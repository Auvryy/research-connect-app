import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/models/question_type.dart';
import 'package:inquira/models/survey_creation.dart';
import 'package:inquira/widgets/primary_button.dart';

class SurveyReviewPage extends StatelessWidget {
  final SurveyCreation surveyData;

  const SurveyReviewPage({
    super.key,
    required this.surveyData,
  });

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getQuestionTypeDisplay(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.checkbox:
        return 'Checkbox';
      case QuestionType.textResponse:
        return 'Text Response';
      case QuestionType.longTextResponse:
        return 'Long Text Response';
      case QuestionType.ratingScale:
        return 'Rating Scale';
      case QuestionType.dropdown:
        return 'Dropdown';
      case QuestionType.imageChoice:
        return 'Image Choice';
      case QuestionType.fileUpload:
        return 'File Upload';
      case QuestionType.matrix:
        return 'Matrix';
      case QuestionType.ranking:
        return 'Ranking';
    }
  }

  Widget _buildQuestionPreview(SurveyQuestion question) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    question.text.isEmpty ? '(No question text)' : question.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (question.required)
                  const Text(
                    '*',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Type: ${_getQuestionTypeDisplay(question.type)}',
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 14,
              ),
            ),
            if (question.options.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Options:',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 14,
                ),
              ),
              ...question.options.map((option) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text('• $option'),
                  )),
            ],
            if (question.imageUrl != null || question.videoUrl != null) ...[
              const SizedBox(height: 8),
              if (question.imageUrl != null)
                Text(
                  'Has attached image',
                  style: TextStyle(
                    color: AppColors.accent1,
                    fontSize: 14,
                  ),
                ),
              if (question.videoUrl != null)
                Text(
                  'Has attached video',
                  style: TextStyle(
                    color: AppColors.accent1,
                    fontSize: 14,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _publishSurvey(BuildContext context) async {
    // Here you would typically make an API call to publish the survey
    // For now, we'll just show a success message and navigate back
    try {
      // TODO: Implement API call to publish survey
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Survey published successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // Navigate back to home
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish survey: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
          'Review Survey',
          style: TextStyle(
            fontFamily: 'Giaza',
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.secondaryBG,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Survey Information'),
            _buildInfoItem('Title', surveyData.title),
            _buildInfoItem('Caption', surveyData.caption),
            _buildInfoItem('Description', surveyData.description),
            _buildInfoItem(
                'Time to Complete', '${surveyData.timeToComplete} minutes'),
            _buildInfoItem('Tags', surveyData.tags.join(', ')),
            _buildInfoItem('Target Audience', surveyData.targetAudience.join(', ')),
            const SizedBox(height: 16),
            _buildSectionHeader('Questions'),
            ...surveyData.questions
                .map((question) => _buildQuestionPreview(question)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryButton(
            onPressed: () => _publishSurvey(context),
            text: 'Publish Survey',
          ),
        ),
      ),
    );
  }
}