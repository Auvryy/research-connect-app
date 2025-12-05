import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/data/api/survey_api.dart';
import 'package:inquira/models/survey_question.dart';

class TakeSurveyPage extends StatefulWidget {
  final String surveyId;
  final int postId;

  const TakeSurveyPage({
    super.key,
    required this.surveyId,
    required this.postId,
  });

  @override
  State<TakeSurveyPage> createState() => _TakeSurveyPageState();
}

class _TakeSurveyPageState extends State<TakeSurveyPage> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _alreadyAnswered = false;
  String? _errorMessage;

  SurveyQuestionnaire? _questionnaire;
  int? _actualSurveyId; // The actual survey ID from the questionnaire (not postId)
  int _currentSectionIndex = 0;

  final Map<String, Map<String, dynamic>> _responses = {};
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadSurvey();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSurvey() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    print('TakeSurveyPage: Loading survey with postId: ${widget.postId}');

    try {
      // First, fetch the questionnaire to get the actual survey ID
      // The postId is different from survey_id - backend uses survey_id for checkIfAnswered
      print('TakeSurveyPage: Fetching questionnaire first to get actual survey ID...');
      final result = await SurveyAPI.getSurveyQuestionnaire(widget.postId);
      print('TakeSurveyPage: Questionnaire result ok: ${result['ok']}');

      if (result['ok'] == true && result['survey'] != null) {
        print('TakeSurveyPage: Parsing questionnaire...');
        final questionnaire = SurveyQuestionnaire.fromJson(result['survey']);
        _actualSurveyId = questionnaire.surveyId;
        print('TakeSurveyPage: Actual survey ID: $_actualSurveyId (postId was: ${widget.postId})');
        print('TakeSurveyPage: Questionnaire has ${questionnaire.sections.length} sections');

        // Now check if already answered using the ACTUAL survey ID
        final checkResult = await SurveyAPI.checkIfAnswered(_actualSurveyId!);
        print('TakeSurveyPage: Check answered result: $checkResult');
        
        if (checkResult['alreadyAnswered'] == true) {
          setState(() {
            _alreadyAnswered = true;
            _isLoading = false;
          });
          return;
        }

        for (var section in questionnaire.sections) {
          _responses[section.sectionId] = {};
          for (var question in section.questions) {
            // Initialize ALL questions with appropriate empty values
            // Backend iterates all questions, so we must have a value for each
            if (question.questionType == 'checkBox') {
              _responses[section.sectionId]![question.questionId] = <String>[];
            } else {
              // Initialize other types with empty string
              _responses[section.sectionId]![question.questionId] = '';
            }
          }
        }

        setState(() {
          _questionnaire = questionnaire;
          _isLoading = false;
        });
      } else {
        print('TakeSurveyPage: Failed - result ok: ${result['ok']}, survey: ${result['survey']}');
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load survey';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('TakeSurveyPage: Exception: $e');
      setState(() {
        _errorMessage = 'Failed to load survey: $e';
        _isLoading = false;
      });
    }
  }

  void _updateResponse(String sectionId, String questionId, dynamic value) {
    setState(() {
      _responses[sectionId]![questionId] = value;
    });
  }

  bool _isSectionComplete(int sectionIndex) {
    if (_questionnaire == null) return false;

    final section = _questionnaire!.sections[sectionIndex];

    for (var question in section.questions) {
      if (question.required) {
        final answer = _responses[section.sectionId]?[question.questionId];

        if (answer == null) return false;
        if (answer is String && answer.isEmpty) return false;
        if (answer is List && answer.isEmpty) return false;

        if (question.questionType == 'checkBox' && answer is List) {
          if (answer.length < question.minChoice) return false;
        }
      }
    }

    return true;
  }

  void _nextSection() {
    if (_currentSectionIndex < _questionnaire!.sections.length - 1) {
      setState(() => _currentSectionIndex++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousSection() {
    if (_currentSectionIndex > 0) {
      setState(() => _currentSectionIndex--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Check if at least one question has been answered across all sections
  bool _hasAtLeastOneAnswer() {
    for (final sectionEntry in _responses.entries) {
      for (final questionEntry in sectionEntry.value.entries) {
        final value = questionEntry.value;
        if (value is List && value.isNotEmpty) {
          return true;
        } else if (value != null && value.toString().isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _submitSurvey() async {
    if (!_isSectionComplete(_currentSectionIndex)) {
      _showSnackBar('Please answer all required questions', isError: true);
      return;
    }

    // Check if at least one question is answered (even if nothing is required)
    if (!_hasAtLeastOneAnswer()) {
      _showSnackBar('Please answer at least one question before submitting', isError: true);
      return;
    }

    if (_actualSurveyId == null) {
      _showSnackBar('Survey ID not available. Please reload.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Clean up responses before sending - ensure all values are properly formatted
      // Backend iterates ALL questions, so we must send valid values for each
      final cleanedResponses = <String, Map<String, dynamic>>{};
      for (final sectionEntry in _responses.entries) {
        cleanedResponses[sectionEntry.key] = {};
        for (final questionEntry in sectionEntry.value.entries) {
          final value = questionEntry.value;
          // Convert checkbox lists to proper format (send empty list [] not null)
          if (value is List) {
            // Only include non-empty checkbox lists
            if (value.isNotEmpty) {
              // Safely convert all elements to strings
              cleanedResponses[sectionEntry.key]![questionEntry.key] = 
                  value.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
            }
            // Empty checkbox lists are not included - backend will skip them
          } else if (value != null && value.toString().isNotEmpty) {
            // Only include non-empty string values - convert to string explicitly
            cleanedResponses[sectionEntry.key]![questionEntry.key] = value.toString();
          }
          // Empty/null values are NOT included - backend handles missing keys gracefully
          // This prevents date validation errors for optional empty date fields
        }
      }

      // Use the actual survey ID, not the post ID
      final result = await SurveyAPI.submitSurveyResponse(
        _actualSurveyId!,
        {'responses': cleanedResponses},
      );

      if (result['ok'] == true) {
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        _showSnackBar(result['message'] ?? 'Failed to submit', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.green,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Survey Submitted!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Thank you for your response.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingScreen();
    if (_alreadyAnswered) return _buildAlreadyAnsweredScreen();
    if (_errorMessage != null || _questionnaire == null) return _buildErrorScreen();
    return _buildSurveyScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
              ),
              child: const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
            ),
            const SizedBox(height: 24),
            const Text('Loading Survey...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.secondaryText)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlreadyAnsweredScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(color: AppColors.green.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, size: 80, color: AppColors.green),
              ),
              const SizedBox(height: 32),
              const Text('Already Completed', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
              const SizedBox(height: 12),
              const Text('You have already submitted a response for this survey.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: AppColors.secondaryText, height: 1.5)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Return to Feed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
              ),
              const SizedBox(height: 24),
              const Text('Failed to Load Survey', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
              const SizedBox(height: 12),
              Text(_errorMessage ?? 'Something went wrong', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: AppColors.secondaryText)),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.secondary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Go Back', style: TextStyle(color: AppColors.primaryText)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loadSurvey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurveyScreen() {
    final totalSections = _questionnaire!.sections.length;
    final progress = ((_currentSectionIndex + 1) / totalSections);
    final isLastSection = _currentSectionIndex == totalSections - 1;
    final canProceed = _isSectionComplete(_currentSectionIndex);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(progress),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalSections,
                onPageChanged: (index) => setState(() => _currentSectionIndex = index),
                itemBuilder: (context, index) => _buildSectionPage(_questionnaire!.sections[index]),
              ),
            ),
            _buildBottomNavigation(isLastSection, canProceed),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double progress) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.close_rounded), color: AppColors.primaryText, onPressed: _showExitConfirmation),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_questionnaire!.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(_questionnaire!.approxTime, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: AppColors.accent1.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('${_currentSectionIndex + 1} / ${_questionnaire!.sections.length}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent1)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: Colors.grey[200], valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent1)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionPage(SurveySection section) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.accent1.withOpacity(0.08), AppColors.accent1.withOpacity(0.02)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent1.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.accent1.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.article_outlined, color: AppColors.accent1, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(section.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryText))),
                ],
              ),
              if (section.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(section.description, style: const TextStyle(fontSize: 14, color: AppColors.secondaryText, height: 1.5)),
              ],
              const SizedBox(height: 8),
              Text('${section.questions.length} question${section.questions.length > 1 ? 's' : ''}', style: TextStyle(fontSize: 13, color: AppColors.accent1.withOpacity(0.8), fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ...section.questions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: index < section.questions.length - 1 ? 20 : 100),
            child: _buildQuestionCard(section.sectionId, question),
          );
        }),
      ],
    );
  }

  Widget _buildQuestionCard(String sectionId, SurveyQuestion question) {
    final currentValue = _responses[sectionId]?[question.questionId];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text('${question.questionNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: question.questionText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryText, height: 1.4)),
                            if (question.required) const TextSpan(text: ' *', style: TextStyle(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      if (question.questionType == 'checkBox') ...[
                        const SizedBox(height: 6),
                        Text('Select ${question.minChoice} to ${question.maxChoice} options', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (question.imageUrl != null && question.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(question.imageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 100, color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image)))),
              ),
            ],
            const SizedBox(height: 20),
            _buildQuestionInput(sectionId, question, currentValue),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionInput(String sectionId, SurveyQuestion question, dynamic value) {
    switch (question.questionType) {
      case 'shortText':
        return _buildShortTextInput(sectionId, question, value);
      case 'longText':
        return _buildLongTextInput(sectionId, question, value);
      case 'radioButton':
        return _buildRadioInput(sectionId, question, value);
      case 'checkBox':
        return _buildCheckboxInput(sectionId, question, value);
      case 'dropdown':
        return _buildDropdownInput(sectionId, question, value);
      case 'rating':
        return _buildRatingInput(sectionId, question, value);
      case 'date':
        return _buildDateInput(sectionId, question, value);
      case 'email':
        return _buildEmailInput(sectionId, question, value);
      case 'number':
        return _buildNumberInput(sectionId, question, value);
      default:
        return Text('Unsupported type: ${question.questionType}');
    }
  }

  Widget _buildShortTextInput(String sectionId, SurveyQuestion question, dynamic value) {
    final textValue = value?.toString() ?? '';
    return TextField(
      controller: TextEditingController(text: textValue)..selection = TextSelection.collapsed(offset: textValue.length),
      onChanged: (text) => _updateResponse(sectionId, question.questionId, text),
      decoration: InputDecoration(
        hintText: 'Type your answer here...',
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: AppColors.inputColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent1, width: 2)),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildLongTextInput(String sectionId, SurveyQuestion question, dynamic value) {
    final textValue = value?.toString() ?? '';
    return TextField(
      controller: TextEditingController(text: textValue)..selection = TextSelection.collapsed(offset: textValue.length),
      onChanged: (text) => _updateResponse(sectionId, question.questionId, text),
      maxLines: 5,
      decoration: InputDecoration(
        hintText: 'Write your detailed response...',
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: AppColors.inputColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent1, width: 2)),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildRadioInput(String sectionId, SurveyQuestion question, dynamic value) {
    return Column(
      children: question.choices.map((choice) {
        final isSelected = value == choice;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => _updateResponse(sectionId, question.questionId, choice),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent1.withOpacity(0.08) : AppColors.inputColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? AppColors.accent1 : Colors.transparent, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? AppColors.accent1 : Colors.grey[400]!, width: 2), color: isSelected ? AppColors.accent1 : Colors.transparent),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(choice, style: TextStyle(fontSize: 15, color: isSelected ? AppColors.accent1 : AppColors.primaryText, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCheckboxInput(String sectionId, SurveyQuestion question, dynamic value) {
    // Safely convert value to List<String> handling List<dynamic> case
    List<String> selectedValues = [];
    if (value != null && value is List) {
      selectedValues = value.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }

    return Column(
      children: question.choices.map((choice) {
        final isSelected = selectedValues.contains(choice);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () {
              final newList = List<String>.from(selectedValues);
              if (isSelected) {
                newList.remove(choice);
              } else {
                if (newList.length < question.maxChoice) {
                  newList.add(choice);
                }
              }
              _updateResponse(sectionId, question.questionId, newList);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent1.withOpacity(0.08) : AppColors.inputColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? AppColors.accent1 : Colors.transparent, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: isSelected ? AppColors.accent1 : Colors.grey[400]!, width: 2), color: isSelected ? AppColors.accent1 : Colors.transparent),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(choice, style: TextStyle(fontSize: 15, color: isSelected ? AppColors.accent1 : AppColors.primaryText, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDropdownInput(String sectionId, SurveyQuestion question, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: AppColors.inputColor, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value as String?,
          isExpanded: true,
          hint: Text('Select an option', style: TextStyle(color: Colors.grey[500])),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.accent1),
          items: question.choices.map((choice) => DropdownMenuItem(value: choice, child: Text(choice))).toList(),
          onChanged: (newValue) => _updateResponse(sectionId, question.questionId, newValue),
        ),
      ),
    );
  }

  Widget _buildRatingInput(String sectionId, SurveyQuestion question, dynamic value) {
    final rating = int.tryParse(value?.toString() ?? '0') ?? 0;
    final maxStars = question.maxRating > 0 ? question.maxRating : 5;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 80),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.inputColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: maxStars > 5 ? 4 : 8,
          runSpacing: 8,
          children: List.generate(maxStars, (index) {
            final starValue = index + 1;
            final isSelected = starValue <= rating;

            return GestureDetector(
              onTap: () => _updateResponse(sectionId, question.questionId, starValue.toString()),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(4),
                child: Icon(
                  isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: maxStars > 7 ? 32 : (maxStars > 5 ? 38 : 44),
                  color: isSelected ? Colors.amber[600] : Colors.grey[300],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDateInput(String sectionId, SurveyQuestion question, dynamic value) {
    final displayDate = value as String?;

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
          builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.accent1)), child: child!),
        );
        if (date != null) {
          final formatted = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          _updateResponse(sectionId, question.questionId, formatted);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.inputColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: displayDate != null ? AppColors.accent1.withOpacity(0.3) : Colors.transparent)),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: displayDate != null ? AppColors.accent1 : Colors.grey[500], size: 20),
            const SizedBox(width: 12),
            Text(displayDate ?? 'Select a date', style: TextStyle(fontSize: 15, color: displayDate != null ? AppColors.primaryText : Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailInput(String sectionId, SurveyQuestion question, dynamic value) {
    final textValue = value?.toString() ?? '';
    return TextField(
      controller: TextEditingController(text: textValue)..selection = TextSelection.collapsed(offset: textValue.length),
      onChanged: (text) => _updateResponse(sectionId, question.questionId, text),
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: 'your.email@example.com',
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[500]),
        filled: true,
        fillColor: AppColors.inputColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent1, width: 2)),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildNumberInput(String sectionId, SurveyQuestion question, dynamic value) {
    final textValue = value?.toString() ?? '';
    return TextField(
      controller: TextEditingController(text: textValue)..selection = TextSelection.collapsed(offset: textValue.length),
      onChanged: (text) => _updateResponse(sectionId, question.questionId, text),
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        hintText: 'Enter a number (e.g., 42, -10, 3.14)',
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(Icons.numbers, color: Colors.grey[500]),
        filled: true,
        fillColor: AppColors.inputColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent1, width: 2)),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
  Widget _buildBottomNavigation(bool isLastSection, bool canProceed) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]),
      child: Row(
        children: [
          if (_currentSectionIndex > 0) ...[
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _previousSection,
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: AppColors.secondary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.primaryText),
                    SizedBox(width: 6),
                    Text('Back', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : (canProceed ? (isLastSection ? _submitSurvey : _nextSection) : null),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, disabledBackgroundColor: AppColors.secondary2, padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(isLastSection ? 'Submit Survey' : 'Next Section', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        if (!isLastSection) ...[const SizedBox(width: 6), const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white)],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Exit Survey?'),
        content: const Text('Your progress will not be saved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
