import 'package:flutter/material.dart';
import 'package:inquira/models/survey_question.dart';
import 'package:inquira/data/api/survey_api.dart';
import 'package:inquira/widgets/question_widgets.dart';
import 'package:inquira/constants/colors.dart';

class SurveyTakingScreen extends StatefulWidget {
  final int surveyId;

  const SurveyTakingScreen({super.key, required this.surveyId});

  @override
  State<SurveyTakingScreen> createState() => _SurveyTakingScreenState();
}

class _SurveyTakingScreenState extends State<SurveyTakingScreen> {
  SurveyQuestionnaire? _questionnaire;
  bool _isLoading = true;
  bool _alreadyAnswered = false;
  int _currentSectionIndex = 0;
  int? _actualSurveyId; // The actual survey ID from the questionnaire (not the widget.surveyId which may be postId)
  
  // Store responses: Map<sectionId, Map<questionId, answer>>
  final Map<String, Map<String, dynamic>> _responses = {};

  @override
  void initState() {
    super.initState();
    _loadSurvey();
  }

  String? _errorMessage;

  Future<void> _loadSurvey() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('SurveyTakingScreen: Loading survey with ID: ${widget.surveyId}');
      
      // First, fetch the questionnaire to get the actual survey ID
      // The widget.surveyId might be a postId, but backend needs the actual survey_id
      final result = await SurveyAPI.getSurveyQuestionnaire(widget.surveyId);
      print('SurveyTakingScreen: getSurveyQuestionnaire result: ${result['ok']}');
      
      if (result['ok'] == true) {
        final questionnaire = SurveyQuestionnaire.fromJson(result['survey']);
        _actualSurveyId = questionnaire.surveyId;
        print('SurveyTakingScreen: Actual survey ID: $_actualSurveyId (widget.surveyId was: ${widget.surveyId})');
        
        // Now check if already answered using the ACTUAL survey ID
        final checkResult = await SurveyAPI.checkIfAnswered(_actualSurveyId!);
        print('SurveyTakingScreen: checkIfAnswered result: $checkResult');
        
        if (checkResult['alreadyAnswered'] == true) {
          setState(() {
            _alreadyAnswered = true;
            _isLoading = false;
          });
          return;
        }
        
        // Handle 404 - survey not found
        if (checkResult['error'] == 'not_found') {
          setState(() {
            _errorMessage = 'Survey not found. This survey may have been deleted.';
            _isLoading = false;
          });
          return;
        }
        
        // Initialize response structure
        for (var section in questionnaire.sections) {
          _responses[section.sectionId] = {};
        }

        setState(() {
          _questionnaire = questionnaire;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load survey';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('SurveyTakingScreen: Error loading survey: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load survey: $e';
      });
    }
  }

  void _updateResponse(String sectionId, String questionId, dynamic value) {
    setState(() {
      _responses[sectionId]![questionId] = value;
    });
  }

  bool _canGoNext() {
    if (_questionnaire == null) return false;
    
    final currentSection = _questionnaire!.sections[_currentSectionIndex];
    
    // Check if all required questions are answered
    for (var question in currentSection.questions) {
      if (question.required) {
        final answer = _responses[currentSection.sectionId]?[question.questionId];
        
        if (answer == null || 
            (answer is String && answer.isEmpty) ||
            (answer is List && answer.isEmpty)) {
          return false;
        }
      }
    }
    
    return true;
  }

  void _nextSection() {
    if (_currentSectionIndex < _questionnaire!.sections.length - 1) {
      setState(() => _currentSectionIndex++);
    }
  }

  void _previousSection() {
    if (_currentSectionIndex > 0) {
      setState(() => _currentSectionIndex--);
    }
  }

  Future<void> _submitSurvey() async {
    if (!_canGoNext()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all required questions')),
      );
      return;
    }

    if (_actualSurveyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Survey ID not available. Please reload.')),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Clean up responses - ensure all sections are present even if empty
      // Backend requires section keys to exist, even for optional questions
      final cleanedResponses = <String, Map<String, dynamic>>{};
      
      // First, ensure all sections exist in the response
      for (var section in _questionnaire!.sections) {
        cleanedResponses[section.sectionId] = {};
      }
      
      // Then populate with actual responses
      for (final sectionEntry in _responses.entries) {
        for (final questionEntry in sectionEntry.value.entries) {
          final value = questionEntry.value;
          if (value is List) {
            if (value.isNotEmpty) {
              cleanedResponses[sectionEntry.key]![questionEntry.key] = List<String>.from(value);
            }
          } else if (value != null && value.toString().isNotEmpty) {
            // For date fields, ensure proper format
            cleanedResponses[sectionEntry.key]![questionEntry.key] = value;
          }
        }
        
        // If section is empty but exists, make sure the key exists
        if (!cleanedResponses.containsKey(sectionEntry.key)) {
          cleanedResponses[sectionEntry.key] = {};
        }
      }

      // Use the actual survey ID, not widget.surveyId which may be postId
      final result = await SurveyAPI.submitSurveyResponse(
        _actualSurveyId!,
        {'responses': cleanedResponses},
      );

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (result['ok'] == true) {
        if (mounted) {
          // Success! Go back with success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Survey submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Failed to submit')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'Loading Survey...',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_alreadyAnswered) {
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, size: 64, color: AppColors.green),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Already Completed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'You have already submitted a response for this survey.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Return to Feed'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_questionnaire == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.primaryText),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Failed to Load Survey',
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? 'An unexpected error occurred. Please try again.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _loadSurvey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentSection = _questionnaire!.sections[_currentSectionIndex];
    final isLastSection = _currentSectionIndex == _questionnaire!.sections.length - 1;
    final progress = (_currentSectionIndex + 1) / _questionnaire!.sections.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              color: AppColors.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _questionnaire!.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentSectionIndex + 1}/${_questionnaire!.sections.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent1),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header Card
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentSection.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                          if (currentSection.description.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              currentSection.description,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.secondaryText,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Questions List
                    ...currentSection.questions.map((question) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.transparent),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: QuestionWidget(
                            question: question,
                            value: _responses[currentSection.sectionId]?[question.questionId],
                            onChanged: (value) => _updateResponse(
                              currentSection.sectionId,
                              question.questionId,
                              value,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    
                    // Bottom padding for scrolling past FAB/Buttons
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_currentSectionIndex > 0) ...[
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: _previousSection,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.secondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _canGoNext()
                    ? (isLastSection ? _submitSurvey : _nextSection)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.secondary2,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isLastSection ? 'Submit Survey' : 'Next Section',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
