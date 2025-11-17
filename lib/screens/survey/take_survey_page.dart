import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/models/survey_response.dart';
import 'package:inquira/models/question_type.dart';
import 'package:inquira/data/api/survey_api.dart';
import 'package:inquira/widgets/primary_button.dart';

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
  String? _errorMessage;
  
  // Survey data
  Map<String, dynamic>? _surveyInfo;
  List<dynamic>? _allQuestions;
  Map<String, List<dynamic>> _sectionQuestions = {}; // sectionId -> questions
  List<String> _sectionIds = [];
  
  // Response tracking
  late SurveyResponse _response;
  int _currentSectionIndex = 0;
  
  // Page controller for smooth transitions
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _initializeResponse();
    _loadSurveyData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initializeResponse() {
    _response = SurveyResponse(
      surveyId: widget.surveyId,
      respondentId: 'current-user-id', // TODO: Get from auth
      startedAt: DateTime.now(),
    );
  }

  Future<void> _loadSurveyData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch survey questionnaire from backend
      final data = await SurveyAPI.getSurveyQuestionnaire(widget.postId);
      
      if (data['ok'] == true) {
        _surveyInfo = data['survey'];
        _allQuestions = data['questions'];
        
        // Group questions by section
        _groupQuestionsBySection();
        
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load survey';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading survey: $e');
      setState(() {
        _errorMessage = 'Error loading survey: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _groupQuestionsBySection() {
    if (_allQuestions == null) return;
    
    _sectionQuestions.clear();
    _sectionIds.clear();
    
    for (var question in _allQuestions!) {
      final sectionId = question['section_id']?.toString() ?? 'default';
      
      if (!_sectionQuestions.containsKey(sectionId)) {
        _sectionQuestions[sectionId] = [];
        _sectionIds.add(sectionId);
      }
      
      _sectionQuestions[sectionId]!.add(question);
    }
    
    // Sort questions within each section by question_number
    for (var sectionId in _sectionIds) {
      _sectionQuestions[sectionId]!.sort((a, b) {
        final aNum = a['question_number'] ?? 0;
        final bNum = b['question_number'] ?? 0;
        return aNum.compareTo(bNum);
      });
    }
    
    print('Grouped into ${_sectionIds.length} sections');
    print('Section IDs: $_sectionIds');
  }

  void _nextSection() {
    if (_currentSectionIndex < _sectionIds.length - 1) {
      setState(() => _currentSectionIndex++);
      _pageController.animateToPage(
        _currentSectionIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousSection() {
    if (_currentSectionIndex > 0) {
      setState(() => _currentSectionIndex--);
      _pageController.animateToPage(
        _currentSectionIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceed() {
    // Check if all required questions in current section are answered
    final currentSectionId = _sectionIds[_currentSectionIndex];
    final questions = _sectionQuestions[currentSectionId] ?? [];
    
    for (var question in questions) {
      final isRequired = question['is_required'] == true || question['is_required'] == 1;
      final questionId = question['id']?.toString() ?? '';
      
      if (isRequired && !_response.hasAnswer(questionId)) {
        return false;
      }
    }
    
    return true;
  }

  Future<void> _submitSurvey() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Survey?'),
        content: const Text('Are you sure you want to submit your responses? You cannot change them after submission.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      _response.complete();
      
      // Submit to backend
      final result = await SurveyAPI.submitSurveyResponse(_response.toBackendJson());
      
      if (!mounted) return;
      
      // Close loading dialog
      Navigator.pop(context);
      
      if (result['ok'] == true) {
        // Show success and go back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Survey submitted successfully! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to submit survey'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      Navigator.pop(context); // Close loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting survey: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Take Survey', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadSurveyData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text('Retry', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Survey header
                    _buildSurveyHeader(),
                    
                    // Progress indicator
                    _buildProgressIndicator(),
                    
                    // Questions area
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(), // Disable swipe
                        itemCount: _sectionIds.length,
                        onPageChanged: (index) {
                          setState(() => _currentSectionIndex = index);
                        },
                        itemBuilder: (context, index) {
                          final sectionId = _sectionIds[index];
                          final questions = _sectionQuestions[sectionId] ?? [];
                          return _buildSectionPage(sectionId, questions);
                        },
                      ),
                    ),
                    
                    // Navigation buttons
                    _buildNavigationButtons(),
                  ],
                ),
    );
  }

  Widget _buildSurveyHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _surveyInfo?['title'] ?? 'Survey',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_surveyInfo?['content'] != null) ...[
            const SizedBox(height: 8),
            Text(
              _surveyInfo!['content'],
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final progress = (_currentSectionIndex + 1) / _sectionIds.length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Section ${_currentSectionIndex + 1} of ${_sectionIds.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondary,
                ),
              ),
              Text(
                '${(_currentSectionIndex + 1)} / ${_sectionIds.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionPage(String sectionId, List<dynamic> questions) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title (if available)
          if (sectionId != 'default') ...[
            Text(
              'Section: $sectionId',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Questions
          ...questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: index < questions.length - 1 ? 24 : 0),
              child: _buildQuestionCard(question),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final questionId = question['id']?.toString() ?? '';
    final questionText = question['question_text'] ?? '';
    final isRequired = question['is_required'] == true || question['is_required'] == 1;
    final questionType = _parseQuestionType(question['question_type']);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    questionText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isRequired)
                  const Text(
                    ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Question input based on type
            _buildQuestionInput(questionId, questionType, question),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionInput(String questionId, QuestionType type, Map<String, dynamic> question) {
    final currentAnswer = _response.getAnswer(questionId);
    
    switch (type) {
      case QuestionType.textResponse:
        return _buildTextInput(questionId, false);
      
      case QuestionType.longTextResponse:
        return _buildTextInput(questionId, true);
      
      case QuestionType.multipleChoice:
        return _buildMultipleChoice(questionId, question, currentAnswer);
      
      case QuestionType.checkbox:
        return _buildCheckboxes(questionId, question, currentAnswer);
      
      case QuestionType.dropdown:
        return _buildDropdown(questionId, question, currentAnswer);
      
      case QuestionType.yesNo:
        return _buildYesNo(questionId, currentAnswer);
      
      case QuestionType.ratingScale:
        return _buildRatingScale(questionId, question, currentAnswer);
    }
  }

  Widget _buildTextInput(String questionId, bool isLong) {
    final currentAnswer = _response.getAnswer(questionId);
    final controller = TextEditingController(
      text: currentAnswer?.textAnswer ?? '',
    );

    return TextField(
      controller: controller,
      maxLines: isLong ? 5 : 1,
      decoration: InputDecoration(
        hintText: isLong ? 'Enter your answer...' : 'Your answer',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      onChanged: (value) {
        setState(() {
          if (isLong) {
            _response.setAnswer(questionId, QuestionAnswer.longText(value));
          } else {
            _response.setAnswer(questionId, QuestionAnswer.text(value));
          }
        });
      },
    );
  }

  Widget _buildMultipleChoice(String questionId, Map<String, dynamic> question, QuestionAnswer? currentAnswer) {
    final options = _parseOptions(question['options']);
    
    return Column(
      children: options.map((option) {
        return RadioListTile<String>(
          title: Text(option),
          value: option,
          groupValue: currentAnswer?.singleChoiceAnswer,
          activeColor: AppColors.primary,
          onChanged: (value) {
            setState(() {
              _response.setAnswer(
                questionId,
                QuestionAnswer.singleChoice(QuestionType.multipleChoice, value!),
              );
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildCheckboxes(String questionId, Map<String, dynamic> question, QuestionAnswer? currentAnswer) {
    final options = _parseOptions(question['options']);
    final selectedOptions = currentAnswer?.multipleChoiceAnswers ?? [];
    
    return Column(
      children: options.map((option) {
        final isSelected = selectedOptions.contains(option);
        
        return CheckboxListTile(
          title: Text(option),
          value: isSelected,
          activeColor: AppColors.primary,
          onChanged: (value) {
            setState(() {
              final newSelected = List<String>.from(selectedOptions);
              if (value == true) {
                newSelected.add(option);
              } else {
                newSelected.remove(option);
              }
              _response.setAnswer(
                questionId,
                QuestionAnswer.multipleChoice(newSelected),
              );
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildDropdown(String questionId, Map<String, dynamic> question, QuestionAnswer? currentAnswer) {
    final options = _parseOptions(question['options']);
    
    return DropdownButtonFormField<String>(
      value: currentAnswer?.singleChoiceAnswer,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      hint: const Text('Select an option'),
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _response.setAnswer(
              questionId,
              QuestionAnswer.singleChoice(QuestionType.dropdown, value),
            );
          });
        }
      },
    );
  }

  Widget _buildYesNo(String questionId, QuestionAnswer? currentAnswer) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _response.setAnswer(questionId, QuestionAnswer.yesNo(true));
              });
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: currentAnswer?.singleChoiceAnswer == 'Yes'
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.white,
              side: BorderSide(
                color: currentAnswer?.singleChoiceAnswer == 'Yes'
                    ? AppColors.primary
                    : AppColors.border,
                width: 2,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Yes',
              style: TextStyle(
                color: currentAnswer?.singleChoiceAnswer == 'Yes'
                    ? AppColors.primary
                    : AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _response.setAnswer(questionId, QuestionAnswer.yesNo(false));
              });
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: currentAnswer?.singleChoiceAnswer == 'No'
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.white,
              side: BorderSide(
                color: currentAnswer?.singleChoiceAnswer == 'No'
                    ? AppColors.primary
                    : AppColors.border,
                width: 2,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'No',
              style: TextStyle(
                color: currentAnswer?.singleChoiceAnswer == 'No'
                    ? AppColors.primary
                    : AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingScale(String questionId, Map<String, dynamic> question, QuestionAnswer? currentAnswer) {
    final options = _parseOptions(question['options']);
    final maxRating = options.length;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(maxRating, (index) {
            final rating = index + 1;
            final isSelected = currentAnswer?.ratingAnswer == rating;
            
            return InkWell(
              onTap: () {
                setState(() {
                  _response.setAnswer(questionId, QuestionAnswer.rating(rating));
                });
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.star,
                    color: isSelected ? Colors.white : AppColors.border,
                    size: 28,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        if (currentAnswer?.ratingAnswer != null)
          Text(
            '${currentAnswer!.ratingAnswer} / $maxRating',
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: 14,
            ),
          ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    final isFirstSection = _currentSectionIndex == 0;
    final isLastSection = _currentSectionIndex == _sectionIds.length - 1;
    final canProceed = _canProceed();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          if (!isFirstSection)
            OutlinedButton(
              onPressed: _previousSection,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                side: BorderSide(color: AppColors.primary),
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_back, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Back',
                    style: TextStyle(color: AppColors.primary, fontSize: 16),
                  ),
                ],
              ),
            )
          else
            const SizedBox.shrink(),
          
          // Next/Submit button
          if (isLastSection)
            Expanded(
              child: PrimaryButton(
                text: 'Submit Survey',
                onPressed: canProceed ? _submitSurvey : null,
              ),
            )
          else
            Expanded(
              child: PrimaryButton(
                text: 'Next →',
                onPressed: canProceed ? _nextSection : null,
              ),
            ),
        ],
      ),
    );
  }

  // Helper methods
  QuestionType _parseQuestionType(String? type) {
    switch (type?.toLowerCase()) {
      case 'multiplechoice':
      case 'multiple_choice':
        return QuestionType.multipleChoice;
      case 'checkbox':
        return QuestionType.checkbox;
      case 'dropdown':
        return QuestionType.dropdown;
      case 'textresponse':
      case 'text_response':
      case 'text':
        return QuestionType.textResponse;
      case 'longtextresponse':
      case 'long_text_response':
      case 'longtext':
        return QuestionType.longTextResponse;
      case 'ratingscale':
      case 'rating_scale':
      case 'rating':
        return QuestionType.ratingScale;
      case 'yesno':
      case 'yes_no':
        return QuestionType.yesNo;
      default:
        return QuestionType.textResponse;
    }
  }

  List<String> _parseOptions(dynamic options) {
    if (options == null) return [];
    
    if (options is List) {
      return options.map((e) => e.toString()).toList();
    }
    
    if (options is String) {
      // Try to parse as JSON array
      try {
        final parsed = options.split(',').map((e) => e.trim()).toList();
        return parsed;
      } catch (e) {
        return [options];
      }
    }
    
    return [];
  }
}
