import 'dart:io';
import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/models/question_type.dart';
import 'package:inquira/models/survey_creation.dart';
import 'package:inquira/widgets/primary_button.dart';
import 'package:inquira/data/survey_service.dart';
import 'package:inquira/data/draft_service.dart';
import 'package:inquira/data/api/survey_api.dart';

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

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryBG,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
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

  Widget _buildQuestionPreview(SurveyQuestion question, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          radius: 16,
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          question.text.isEmpty ? '(No question text)' : question.text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (question.required)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text(
                  '*',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 16,
                  ),
                ),
              ),
            if (question.imageUrl != null && question.imageUrl!.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.image, size: 18, color: AppColors.accent1),
              ),
            if (question.videoUrl != null && question.videoUrl!.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.videocam, size: 18, color: AppColors.accent1),
              ),
          ],
        ),
        subtitle: Text(
          _getQuestionTypeDisplay(question.type),
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: 14,
          ),
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

      print('Publishing survey to backend...');
      
      // Collect all question images that need to be uploaded
      Map<String, File> questionImages = {};
      
      for (var question in surveyData.questions) {
        // Check if question has an image and it's a local file path
        if (question.imageUrl != null && 
            question.imageUrl!.isNotEmpty &&
            !question.imageUrl!.startsWith('http')) {
          
          final imageFile = File(question.imageUrl!);
          if (imageFile.existsSync()) {
            // Use the imageKey from the question model (format: "image_{questionId}")
            questionImages[question.imageKey] = imageFile;
            print('Collected image for ${question.imageKey}: ${imageFile.path}');
          }
        }
      }
      
      print('Total images to upload: ${questionImages.length}');
      
      // Prepare survey data for backend
      final backendData = surveyData.toBackendJson();
      
      print('Survey data prepared. Sending to backend...');
      print('Data structure: ${backendData.keys.join(', ')}');
      
      // Submit survey with images using FormData
      final result = await SurveyAPI.createSurvey(
        surveyData: backendData,
        questionImages: questionImages.isNotEmpty ? questionImages : null,
      );
      
      if (!context.mounted) return;
      
      // Close loading dialog
      if (isDialogShowing) {
        Navigator.of(context).pop();
        isDialogShowing = false;
      }
      
      if (result['ok'] == true) {
        // Success - clear draft
        await DraftService.clearDraft();
        
        // Also save locally for offline access
        final userId = await SurveyService.getCurrentUserId();
        final survey = SurveyService.surveyCreationToSurvey(surveyData, userId);
        await SurveyService.saveSurvey(survey);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Survey published successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate back to home
        await Future.delayed(const Duration(milliseconds: 500));
        if (context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        // Error from backend
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message'] ?? 'Failed to publish survey'}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
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
            _buildInfoItem('Title', surveyData.title, Icons.title),
            _buildInfoItem('Caption', surveyData.caption, Icons.short_text),
            _buildInfoItem('Description', surveyData.description, Icons.description),
            _buildInfoItem(
                'Time to Complete', '${surveyData.timeToComplete} minutes', Icons.timer),
            _buildInfoItem('Tags', surveyData.tags.join(', '), Icons.label),
            _buildInfoItem('Target Audience', surveyData.targetAudience.join(', '), Icons.people),
            const SizedBox(height: 24),
            _buildSectionHeader('Questions (${surveyData.questions.length})'),
            ...surveyData.questions
                .asMap()
                .entries
                .map((entry) => _buildQuestionPreview(entry.value, entry.key)),
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