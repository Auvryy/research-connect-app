import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/models/question_type.dart';
import 'package:inquira/models/survey_creation.dart';
import 'package:inquira/widgets/primary_button.dart';
import 'package:inquira/widgets/question_editor.dart';
import 'package:inquira/widgets/question_type_selector.dart';
import 'package:inquira/data/draft_service.dart';

class QuestionsPage extends StatefulWidget {
  final SurveyCreation surveyData;

  const QuestionsPage({
    super.key,
    required this.surveyData,
  });

  @override
  State<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage> {
  late SurveyCreation _surveyData;
  int? _expandedSection;

  @override
  void initState() {
    super.initState();
    _surveyData = widget.surveyData;
    
    // Initialize with one section if empty
    if (_surveyData.sections.isEmpty) {
      _surveyData.sections.add(
        SurveySection(
          id: 'section-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Section 1',
          description: '',
          order: 1,
        ),
      );
    }
  }
  
  /// Generate section ID in backend format: section-{timestamp}
  String _generateSectionId() {
    return 'section-${DateTime.now().millisecondsSinceEpoch}';
  }
  
  /// Generate question ID in backend format: question-{timestamp}
  String _generateQuestionId() {
    return 'question-${DateTime.now().millisecondsSinceEpoch}';
  }

  void _addQuestion(int sectionIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return QuestionTypeSelector(
          onTypeSelected: (QuestionType type) {
            final section = _surveyData.sections[sectionIndex];
            final newQuestion = SurveyQuestion(
              id: _generateQuestionId(),
              type: type,
              text: '',
              required: false,
              options: (type == QuestionType.checkBox ||
                      type == QuestionType.radioButton ||
                      type == QuestionType.dropdown)
                  ? ['Option 1']
                  : [],
              minChoice: type == QuestionType.checkBox ? 1 : null,
              maxChoice: type == QuestionType.checkBox ? 1 : null,
              maxRating: type == QuestionType.rating ? 5 : null,
              order: _surveyData.questions.length,
              sectionId: section.id,
            );
            setState(() {
              _surveyData.questions.add(newQuestion);
            });
          },
        );
      },
    );
  }

  Future<void> _updateQuestion(SurveyQuestion updatedQuestion) async {
    setState(() {
      final index = _surveyData.questions
          .indexWhere((q) => q.id == updatedQuestion.id);
      if (index != -1) {
        _surveyData.questions[index] = updatedQuestion;
      }
    });
    
    // Auto-save draft
    await DraftService.saveDraft(_surveyData);
  }

  Future<void> _deleteQuestion(String questionId) async {
    setState(() {
      _surveyData.questions.removeWhere((q) => q.id == questionId);
      // Update order
      for (var i = 0; i < _surveyData.questions.length; i++) {
        _surveyData.questions[i] = _surveyData.questions[i].copyWith(order: i);
      }
    });
    
    // Auto-save draft
    await DraftService.saveDraft(_surveyData);
  }

  void _addSection() {
    setState(() {
      final newOrder = _surveyData.sections.length + 1;
      _surveyData.sections.add(
        SurveySection(
          id: _generateSectionId(),
          title: 'Section $newOrder',
          description: '',
          order: newOrder,
        ),
      );
    });
  }

  void _deleteSection(int index) {
    if (_surveyData.sections.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must have at least one section'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final sectionId = _surveyData.sections[index].id;
    setState(() {
      // Remove all questions in this section
      _surveyData.questions.removeWhere((q) => q.sectionId == sectionId);
      _surveyData.sections.removeAt(index);
      // Update section orders
      for (var i = 0; i < _surveyData.sections.length; i++) {
        _surveyData.sections[i] = _surveyData.sections[i].copyWith(order: i);
      }
    });
  }

  void _updateSection(int index, {String? title, String? description}) {
    setState(() {
      final section = _surveyData.sections[index];
      _surveyData.sections[index] = section.copyWith(
        title: title ?? section.title,
        description: description ?? section.description,
      );
    });
  }

  void _moveSectionUp(int index) {
    if (index > 0) {
      setState(() {
        final section = _surveyData.sections.removeAt(index);
        _surveyData.sections.insert(index - 1, section);
        
        // Update orders
        for (var i = 0; i < _surveyData.sections.length; i++) {
          _surveyData.sections[i] = _surveyData.sections[i].copyWith(order: i);
        }
        
        // Update expanded section index
        if (_expandedSection == index) {
          _expandedSection = index - 1;
        } else if (_expandedSection == index - 1) {
          _expandedSection = index;
        }
      });
    }
  }

  void _moveSectionDown(int index) {
    if (index < _surveyData.sections.length - 1) {
      setState(() {
        final section = _surveyData.sections.removeAt(index);
        _surveyData.sections.insert(index + 1, section);
        
        // Update orders
        for (var i = 0; i < _surveyData.sections.length; i++) {
          _surveyData.sections[i] = _surveyData.sections[i].copyWith(order: i);
        }
        
        // Update expanded section index
        if (_expandedSection == index) {
          _expandedSection = index + 1;
        } else if (_expandedSection == index + 1) {
          _expandedSection = index;
        }
      });
    }
  }

  void _reorderQuestions(String sectionId, int oldIndex, int newIndex) {
    setState(() {
      final sectionQuestions = _surveyData.questions
          .where((q) => q.sectionId == sectionId)
          .toList();
      
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      
      final question = sectionQuestions.removeAt(oldIndex);
      sectionQuestions.insert(newIndex, question);
      
      // Update all questions for this section
      _surveyData.questions.removeWhere((q) => q.sectionId == sectionId);
      _surveyData.questions.addAll(sectionQuestions);
      
      // Update global order
      for (var i = 0; i < _surveyData.questions.length; i++) {
        _surveyData.questions[i] = _surveyData.questions[i].copyWith(order: i);
      }
    });
  }

  void _proceedToReview() {
    // Check if there's at least one question
    if (_surveyData.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one question'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate all questions and sections meet backend requirements
    for (var section in _surveyData.sections) {
      // Validate section title (5-256 characters)
      if (section.title.length < 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Section "${section.title}" must have a title of at least 5 characters'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      if (section.title.length > 256) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Section "${section.title}" title must not exceed 256 characters'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Validate section description if provided (5-512 characters)
      if (section.description.isNotEmpty) {
        if (section.description.length < 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Section "${section.title}" description must be at least 5 characters'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }
        if (section.description.length > 512) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Section "${section.title}" description must not exceed 512 characters'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }
      }
    }

    for (var question in _surveyData.questions) {
      // Validate question text (4-150 words, max 2000 characters)
      final words = question.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      if (words.length < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Question "${question.text.isEmpty ? 'Untitled' : question.text}" must be at least 4 words'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      if (words.length > 150) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Question "${question.text.isEmpty ? 'Untitled' : question.text}" must not exceed 150 words'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      if (question.text.length > 2000) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Question "${question.text.isEmpty ? 'Untitled' : question.text}" must not exceed 2000 characters'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Validate choice-based questions have at least 2 options
      final needsOptions = question.type == QuestionType.checkBox ||
          question.type == QuestionType.radioButton ||
          question.type == QuestionType.dropdown;
      
      if (needsOptions && question.options.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Question "${question.text.isEmpty ? 'Untitled' : question.text}" must have at least 2 options'
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Validate each option (1-500 characters)
      if (needsOptions) {
        for (var i = 0; i < question.options.length; i++) {
          final option = question.options[i];
          if (option.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Question "${question.text.isEmpty ? 'Untitled' : question.text}" has an empty option'),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 3),
              ),
            );
            return;
          }
          if (option.length > 500) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Question "${question.text.isEmpty ? 'Untitled' : question.text}" option ${i + 1} exceeds 500 characters'),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 3),
              ),
            );
            return;
          }
        }
      }
    }

    Navigator.pushNamed(
      context,
      '/create-survey/review',
      arguments: _surveyData,
    );
  }

  List<SurveyQuestion> _getQuestionsForSection(String sectionId) {
    return _surveyData.questions
        .where((q) => q.sectionId == sectionId)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Questions',
          style: TextStyle(
            fontFamily: 'Giaza',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: _addSection,
            tooltip: 'Add Section',
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _surveyData.sections.length,
        itemBuilder: (context, index) {
          final section = _surveyData.sections[index];
          final sectionQuestions = _getQuestionsForSection(section.id);
          final isExpanded = _expandedSection == index;

          return Card(
            key: ValueKey(section.id),
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: ListTile(
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (index > 0)
                          InkWell(
                            onTap: () => _moveSectionUp(index),
                            child: const Icon(
                              Icons.arrow_upward,
                              color: AppColors.primary,
                              size: 16,
                            ),
                          ),
                        if (index < _surveyData.sections.length - 1)
                          InkWell(
                            onTap: () => _moveSectionDown(index),
                            child: const Icon(
                              Icons.arrow_downward,
                              color: AppColors.primary,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: TextEditingController(text: section.title)
                            ..selection = TextSelection.collapsed(
                              offset: section.title.length,
                            ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Section Title',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (value) {
                            if (value.length > 256) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Section title must not exceed 256 characters'),
                                  backgroundColor: AppColors.error,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }
                            _updateSection(index, title: value);
                          },
                        ),
                        Text(
                          '${section.title.length}/256 chars',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: TextEditingController(text: section.description)
                            ..selection = TextSelection.collapsed(
                              offset: section.description.length,
                            ),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Section description (optional)',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (value) {
                            if (value.length > 512) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Section description must not exceed 512 characters'),
                                  backgroundColor: AppColors.error,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }
                            _updateSection(index, description: value);
                          },
                        ),
                        if (section.description.isNotEmpty)
                          Text(
                            '${section.description.length}/512 chars',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              _expandedSection = isExpanded ? null : index;
                            });
                          },
                        ),
                        if (_surveyData.sections.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error),
                            onPressed: () => _deleteSection(index),
                          ),
                      ],
                    ),
                  ),
                ),

                // Section Questions
                if (isExpanded) ...[
                  const Divider(height: 1),
                  if (sectionQuestions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.quiz_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No questions in this section',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _addQuestion(index),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Question'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      itemCount: sectionQuestions.length,
                      onReorder: (oldIdx, newIdx) {
                        _reorderQuestions(section.id, oldIdx, newIdx);
                      },
                      itemBuilder: (context, qIndex) {
                        final question = sectionQuestions[qIndex];
                        return QuestionEditor(
                          key: ValueKey(question.id),
                          question: question,
                          onQuestionUpdated: _updateQuestion,
                          onDelete: () => _deleteQuestion(question.id),
                        );
                      },
                    ),
                  
                  if (sectionQuestions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: OutlinedButton.icon(
                        onPressed: () => _addQuestion(index),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Question'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryButton(
            onPressed: _proceedToReview,
            text: 'Review & Publish',
          ),
        ),
      ),
    );
  }
}
