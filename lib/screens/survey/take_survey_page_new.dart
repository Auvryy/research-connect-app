import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
// import 'package:inquira/models/question_type.dart'; // TODO: Uncomment when connecting to backend

/// Modern UI for taking surveys with dynamic section navigation
/// 
/// TODO: Backend Integration
/// - Connect to API endpoint to fetch survey data (sections, questions, etc.)
/// - Submit survey responses to backend
/// - Handle user authentication for respondent ID
/// 
/// Features:
/// - Dynamic section-based navigation (no page reloads)
/// - Progress tracking across sections
/// - Smooth transitions between sections
/// - Responsive design for all question types
/// - Validation before proceeding to next section
class TakeSurveyPage extends StatefulWidget {
  final String surveyId;
  final int? postId; // For backend integration

  const TakeSurveyPage({
    super.key,
    required this.surveyId,
    this.postId,
  });

  @override
  State<TakeSurveyPage> createState() => _TakeSurveyPageState();
}

class _TakeSurveyPageState extends State<TakeSurveyPage> with SingleTickerProviderStateMixin {
  // Current section index (0-based)
  int _currentSectionIndex = 0;
  
  // Page controller for smooth section transitions (not literal pages)
  late PageController _pageController;
  
  // Animation controller for progress bar
  late AnimationController _progressAnimationController;
  
  // Response storage: Map<questionId, answer>
  final Map<String, dynamic> _responses = {};
  
  // TODO: Replace with real data from backend API
  // This is mock data structure for UI demonstration
  final Map<String, dynamic> _mockSurveyData = {
    'title': 'Sample Survey',
    'description': 'This is a demonstration of the survey UI',
    'sections': [
      {
        'id': 'section-1',
        'title': 'Personal Information',
        'description': 'Tell us about yourself',
        'questions': [
          {
            'id': 'q1',
            'text': 'What is your name?',
            'type': 'shortText',
            'required': true,
          },
          {
            'id': 'q2',
            'text': 'What is your email address?',
            'type': 'email',
            'required': true,
          },
          {
            'id': 'q3',
            'text': 'Tell us about your experience',
            'type': 'longText',
            'required': false,
          },
        ],
      },
      {
        'id': 'section-2',
        'title': 'Preferences',
        'description': 'Help us understand your preferences',
        'questions': [
          {
            'id': 'q4',
            'text': 'What is your preferred contact method?',
            'type': 'radioButton',
            'required': true,
            'options': ['Email', 'Phone', 'Text Message'],
          },
          {
            'id': 'q5',
            'text': 'Select all that apply',
            'type': 'checkBox',
            'required': true,
            'options': ['Option A', 'Option B', 'Option C', 'Option D'],
            'minChoice': 1,
            'maxChoice': 3,
          },
          {
            'id': 'q6',
            'text': 'Choose from dropdown',
            'type': 'dropdown',
            'required': false,
            'options': ['Choice 1', 'Choice 2', 'Choice 3'],
          },
        ],
      },
      {
        'id': 'section-3',
        'title': 'Feedback',
        'description': 'Rate your experience',
        'questions': [
          {
            'id': 'q7',
            'text': 'Rate your overall satisfaction',
            'type': 'rating',
            'required': true,
            'maxRating': 5,
          },
          {
            'id': 'q8',
            'text': 'When did you start using our service?',
            'type': 'date',
            'required': false,
          },
        ],
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // TODO: Load survey data from backend
    // _loadSurveyFromBackend();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  // TODO: Backend Integration - Load survey data
  // Future<void> _loadSurveyFromBackend() async {
  //   try {
  //     final data = await SurveyAPI.getSurveyQuestionnaire(widget.postId);
  //     setState(() {
  //       // Parse and set survey data
  //     });
  //   } catch (e) {
  //     // Handle error
  //   }
  // }

  List<dynamic> get _sections => _mockSurveyData['sections'] as List;
  
  Map<String, dynamic> get _currentSection => _sections[_currentSectionIndex];
  
  List<dynamic> get _currentQuestions => _currentSection['questions'] as List;
  
  double get _progress => (_currentSectionIndex + 1) / _sections.length;
  
  bool get _isFirstSection => _currentSectionIndex == 0;
  
  bool get _isLastSection => _currentSectionIndex == _sections.length - 1;

  void _updateResponse(String questionId, dynamic value) {
    setState(() {
      _responses[questionId] = value;
    });
  }

  bool _isQuestionAnswered(Map<String, dynamic> question) {
    final questionId = question['id'] as String;
    final answer = _responses[questionId];
    
    if (answer == null) return false;
    
    // Check based on question type
    if (answer is String) return answer.trim().isNotEmpty;
    if (answer is List) return answer.isNotEmpty;
    if (answer is int || answer is double) return true;
    
    return false;
  }

  bool _canProceed() {
    // Check if all required questions in current section are answered
    for (var question in _currentQuestions) {
      final isRequired = question['required'] == true;
      if (isRequired && !_isQuestionAnswered(question)) {
        return false;
      }
    }
    return true;
  }

  void _goToNextSection() {
    if (!_canProceed()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all required questions'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isLastSection) {
      _submitSurvey();
    } else {
      setState(() => _currentSectionIndex++);
      _pageController.animateToPage(
        _currentSectionIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousSection() {
    if (!_isFirstSection) {
      setState(() => _currentSectionIndex--);
      _pageController.animateToPage(
        _currentSectionIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // TODO: Backend Integration - Submit survey responses
  Future<void> _submitSurvey() async {
    // Show confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Survey?'),
        content: const Text('Are you sure you want to submit? You cannot change your answers after submission.'),
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

    if (confirmed != true || !mounted) return;

    // TODO: Send to backend
    // try {
    //   final result = await SurveyAPI.submitSurveyResponse(
    //     surveyId: widget.surveyId,
    //     responses: _responses,
    //   );
    //   // Handle success/error
    // } catch (e) {
    //   // Handle error
    // }

    // Mock success
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Survey submitted successfully! 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _mockSurveyData['title'] as String,
          style: const TextStyle(
            color: AppColors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildProgressHeader(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable swipe, use buttons only
              itemCount: _sections.length,
              onPageChanged: (index) {
                setState(() => _currentSectionIndex = index);
              },
              itemBuilder: (context, index) {
                final section = _sections[index];
                return _buildSectionContent(section);
              },
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Section ${_currentSectionIndex + 1} of ${_sections.length}',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(_progress * 100).toInt()}% Complete',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent(Map<String, dynamic> section) {
    final questions = section['questions'] as List;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.accent1.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Section ${_currentSectionIndex + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  section['title'] as String,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                if (section['description'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    section['description'] as String,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.secondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Questions
          ...questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildQuestionCard(question, index + 1),
            );
          }),
          
          const SizedBox(height: 80), // Space for navigation buttons
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int questionNumber) {
    final questionId = question['id'] as String;
    final questionText = question['text'] as String;
    final questionType = question['type'] as String;
    final isRequired = question['required'] == true;
    final isAnswered = _isQuestionAnswered(question);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAnswered 
              ? AppColors.primary.withOpacity(0.3)
              : Colors.grey.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isAnswered 
                        ? AppColors.primary 
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$questionNumber',
                      style: TextStyle(
                        color: isAnswered ? Colors.white : AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              questionText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                                height: 1.4,
                              ),
                            ),
                          ),
                          if (isRequired)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Required',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getQuestionTypeLabel(questionType),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Question Input
            _buildQuestionInput(question),
          ],
        ),
      ),
    );
  }

  String _getQuestionTypeLabel(String type) {
    switch (type) {
      case 'shortText': return 'Short Answer';
      case 'longText': return 'Long Answer';
      case 'radioButton': return 'Single Choice';
      case 'checkBox': return 'Multiple Choice';
      case 'dropdown': return 'Dropdown Selection';
      case 'rating': return 'Rating';
      case 'date': return 'Date';
      case 'email': return 'Email Address';
      default: return 'Answer';
    }
  }

  Widget _buildQuestionInput(Map<String, dynamic> question) {
    final questionId = question['id'] as String;
    final questionType = question['type'] as String;
    final currentAnswer = _responses[questionId];

    switch (questionType) {
      case 'shortText':
      case 'email':
        return _buildTextInput(questionId, currentAnswer as String?, false);
      
      case 'longText':
        return _buildTextInput(questionId, currentAnswer as String?, true);
      
      case 'radioButton':
        return _buildRadioInput(questionId, question['options'] as List, currentAnswer as String?);
      
      case 'checkBox':
        return _buildCheckboxInput(
          questionId,
          question['options'] as List,
          currentAnswer as List<String>?,
          question['minChoice'] as int?,
          question['maxChoice'] as int?,
        );
      
      case 'dropdown':
        return _buildDropdownInput(questionId, question['options'] as List, currentAnswer as String?);
      
      case 'rating':
        return _buildRatingInput(questionId, question['maxRating'] as int? ?? 5, currentAnswer as int?);
      
      case 'date':
        return _buildDateInput(questionId, currentAnswer as DateTime?);
      
      default:
        return _buildTextInput(questionId, currentAnswer as String?, false);
    }
  }

  Widget _buildTextInput(String questionId, String? value, bool multiline) {
    return TextField(
      controller: TextEditingController(text: value ?? '')
        ..selection = TextSelection.collapsed(offset: value?.length ?? 0),
      maxLines: multiline ? 5 : 1,
      onChanged: (text) => _updateResponse(questionId, text),
      decoration: InputDecoration(
        hintText: multiline ? 'Type your answer here...' : 'Your answer',
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildRadioInput(String questionId, List options, String? selectedValue) {
    return Column(
      children: options.map((option) {
        final optionText = option.toString();
        final isSelected = selectedValue == optionText;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => _updateResponse(questionId, optionText),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.primary : Colors.grey.shade400,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      optionText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? AppColors.primary : AppColors.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCheckboxInput(String questionId, List options, List<String>? selectedValues, int? minChoice, int? maxChoice) {
    final selected = selectedValues ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (minChoice != null || maxChoice != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              minChoice != null && maxChoice != null
                  ? 'Select between $minChoice and $maxChoice options'
                  : minChoice != null
                      ? 'Select at least $minChoice option(s)'
                      : 'Select up to $maxChoice option(s)',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ...options.map((option) {
          final optionText = option.toString();
          final isSelected = selected.contains(optionText);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                final newSelected = List<String>.from(selected);
                if (isSelected) {
                  newSelected.remove(optionText);
                } else {
                  if (maxChoice == null || newSelected.length < maxChoice) {
                    newSelected.add(optionText);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('You can select up to $maxChoice options'),
                        backgroundColor: AppColors.error,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                }
                _updateResponse(questionId, newSelected);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                      color: isSelected ? AppColors.primary : Colors.grey.shade400,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        optionText,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? AppColors.primary : AppColors.primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDropdownInput(String questionId, List options, String? selectedValue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedValue,
          hint: const Text('Select an option'),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
          items: options.map((option) {
            final optionText = option.toString();
            return DropdownMenuItem<String>(
              value: optionText,
              child: Text(optionText),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              _updateResponse(questionId, value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildRatingInput(String questionId, int maxRating, int? selectedRating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1 = Poor, $maxRating = Excellent',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.secondary,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(maxRating, (index) {
            final rating = index + 1;
            final isSelected = selectedRating != null && rating <= selectedRating;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => _updateResponse(questionId, rating),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.amber.withOpacity(0.2)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.amber : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.star,
                    color: isSelected ? Colors.amber : Colors.grey.shade400,
                    size: 28,
                  ),
                ),
              ),
            );
          }),
        ),
        if (selectedRating != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'You rated: $selectedRating / $maxRating',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateInput(String questionId, DateTime? selectedDate) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primary,
                ),
              ),
              child: child!,
            );
          },
        );
        
        if (picked != null) {
          _updateResponse(questionId, picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              selectedDate != null
                  ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                  : 'Select a date',
              style: TextStyle(
                fontSize: 15,
                color: selectedDate != null ? AppColors.primaryText : AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final canProceed = _canProceed();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!_isFirstSection)
              Expanded(
                child: OutlinedButton(
                  onPressed: _goToPreviousSection,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Previous',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!_isFirstSection) const SizedBox(width: 12),
            Expanded(
              flex: _isFirstSection ? 1 : 1,
              child: ElevatedButton(
                onPressed: canProceed ? _goToNextSection : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: canProceed ? AppColors.primary : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLastSection ? 'Submit Survey' : 'Next Section',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isLastSection ? Icons.check_circle : Icons.arrow_forward,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
