import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/models/question_type.dart';
import 'package:inquira/models/survey_creation.dart';
import 'package:inquira/widgets/primary_button.dart';
import 'package:inquira/data/survey_service.dart';
import 'package:inquira/data/draft_service.dart';

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
      case QuestionType.shortText:
        return 'Short Text';
      case QuestionType.longText:
        return 'Long Text';
      case QuestionType.radioButton:
        return 'Single Choice';
      case QuestionType.checkBox:
        return 'Multiple Choice';
      case QuestionType.rating:
        return 'Rating (1-5)';
      case QuestionType.dropdown:
        return 'Dropdown';
      case QuestionType.date:
        return 'Date';
      case QuestionType.email:
        return 'Email';
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
    bool isDialogShowing = false;
    
    try {
      // Show loading indicator
      isDialogShowing = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      print('Saving survey to local storage (Backend disconnected for debugging)...');
      
      // Save directly to local storage without backend
      final userId = await SurveyService.getCurrentUserId();
      final survey = SurveyService.surveyCreationToSurvey(surveyData, userId);
      await SurveyService.saveSurvey(survey);
      
      print('Survey saved locally: ${survey.toJson()}');
      
      if (!context.mounted) return;
      
      // Close loading dialog
      if (isDialogShowing) {
        Navigator.of(context).pop();
        isDialogShowing = false;
      }
      
      // Clear draft after successful save
      await DraftService.clearDraft();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Survey saved locally! 🎉 (Debug Mode)'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Navigate back to home
      await Future.delayed(const Duration(milliseconds: 500));
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e, stackTrace) {
      print('Error publishing survey: $e');
      print('Stack trace: $stackTrace');
      
      if (!context.mounted) return;
      
      // Close loading dialog if still showing
      if (isDialogShowing) {
        try {
          Navigator.of(context).pop();
        } catch (_) {
          // Dialog already closed
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
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