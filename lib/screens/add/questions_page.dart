import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/models/question_type.dart';
import 'package:inquira/models/survey_creation.dart';
import 'package:inquira/widgets/primary_button.dart';
import 'package:inquira/widgets/question_editor.dart';
import 'package:inquira/widgets/question_type_selector.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:uuid/uuid.dart';

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
  final String _defaultSectionId = 'default_section';

  @override
  void initState() {
    super.initState();
    _surveyData = widget.surveyData;
    if (_surveyData.sections.isEmpty) {
      _surveyData.sections.add(
        SurveySection(
          id: _defaultSectionId,
          title: 'Main Section',
          order: 0,
        ),
      );
    }
  }

  void _addQuestion() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return QuestionTypeSelector(
          onTypeSelected: (QuestionType type) {
            final newQuestion = SurveyQuestion(
              id: const Uuid().v4(),
              type: type,
              order: _surveyData.questions.length,
              sectionId: _defaultSectionId,
            );
            setState(() {
              _surveyData.questions.add(newQuestion);
            });
          },
        );
      },
    );
  }

  void _updateQuestion(SurveyQuestion updatedQuestion) {
    setState(() {
      final index = _surveyData.questions
          .indexWhere((q) => q.id == updatedQuestion.id);
      if (index != -1) {
        _surveyData.questions[index] = updatedQuestion;
      }
    });
  }

  void _deleteQuestion(String questionId) {
    setState(() {
      _surveyData.questions.removeWhere((q) => q.id == questionId);
      // Update order of remaining questions
      for (var i = 0; i < _surveyData.questions.length; i++) {
        _surveyData.questions[i] = SurveyQuestion(
          id: _surveyData.questions[i].id,
          text: _surveyData.questions[i].text,
          type: _surveyData.questions[i].type,
          required: _surveyData.questions[i].required,
          options: _surveyData.questions[i].options,
          imageUrl: _surveyData.questions[i].imageUrl,
          videoUrl: _surveyData.questions[i].videoUrl,
          order: i,
          sectionId: _surveyData.questions[i].sectionId,
        );
      }
    });
  }

  void _addSection() {
    setState(() {
      _surveyData.sections.add(
        SurveySection(
          id: const Uuid().v4(),
          title: 'New Section',
          order: _surveyData.sections.length,
        ),
      );
    });
  }

  void _reorderQuestions(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _surveyData.questions.removeAt(oldIndex);
      _surveyData.questions.insert(newIndex, item);

      // Update order of all questions
      _surveyData.questions = [
        for (var i = 0; i < _surveyData.questions.length; i++)
          _surveyData.questions[i].copyWith(order: i)
      ];
    });
  }

  void _proceedToReview() {
    if (_surveyData.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one question'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/create-survey/review',
      arguments: _surveyData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Questions',
          style: TextStyle(
            fontFamily: 'Giaza',
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.secondaryBG,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: _addSection,
            tooltip: 'Add Section',
          ),
        ],
      ),
      body: _surveyData.questions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No questions yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Question'),
                  ),
                ],
              ),
            )
          : ReorderableGridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                childAspectRatio: 2,
              ),
              itemCount: _surveyData.questions.length,
              itemBuilder: (context, index) {
                final question = _surveyData.questions[index];
                return QuestionEditor(
                  key: ValueKey(question.id),
                  question: question,
                  onQuestionUpdated: _updateQuestion,
                  onDelete: () => _deleteQuestion(question.id),
                );
              },
              onReorder: _reorderQuestions,
              padding: const EdgeInsets.all(16),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addQuestion,
        child: const Icon(Icons.add),
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