import 'dart:io';
import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/models/question_type.dart';
import 'package:inquira/models/survey_creation.dart';
import 'package:inquira/widgets/primary_button.dart';
import 'package:inquira/data/draft_service.dart';
import 'package:inquira/data/api/survey_api.dart';

class SurveyReviewPage extends StatefulWidget {
  final SurveyCreation surveyData;

  const SurveyReviewPage({
    super.key,
    required this.surveyData,
  });

  @override
  State<SurveyReviewPage> createState() => _SurveyReviewPageState();
}

class _SurveyReviewPageState extends State<SurveyReviewPage> {
  final TextEditingController _bypassCodeController = TextEditingController();
  bool _showBypassCodeField = false;

  @override
  void dispose() {
    _bypassCodeController.dispose();
    super.dispose();
  }

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

  /// Build the bypass code section
  Widget _buildBypassCodeSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.vpn_key, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Have an approval bypass code?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              Switch(
                value: _showBypassCodeField,
                onChanged: (value) {
                  setState(() {
                    _showBypassCodeField = value;
                    if (!value) {
                      _bypassCodeController.clear();
                    }
                  });
                },
                activeColor: Colors.blue.shade700,
              ),
            ],
          ),
          if (_showBypassCodeField) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _bypassCodeController,
              decoration: InputDecoration(
                hintText: 'Enter your bypass code',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.lock_open, color: Colors.blue.shade600),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'If you have a valid code, your survey will be published immediately without waiting for admin approval.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              'Without a code, your survey will need admin approval before appearing in the feed.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade600,
              ),
            ),
          ],
        ],
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
      
      // Set the bypass code if provided
      final bypassCode = _bypassCodeController.text.trim();
      if (bypassCode.isNotEmpty) {
        widget.surveyData.bypassCode = bypassCode;
        print('Bypass code provided: $bypassCode');
      }
      
      // Collect all question images that need to be uploaded
      Map<String, File> questionImages = {};
      
      for (var question in widget.surveyData.questions) {
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
      final backendData = widget.surveyData.toBackendJson();
      
      print('Survey data prepared. Sending to backend...');
      print('Data structure: ${backendData.keys.join(', ')}');
      if (backendData.containsKey('post_code')) {
        print('Bypass code included in submission');
      }
      
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
        
        // Determine if bypass code was used (survey approved immediately)
        final wasApprovedImmediately = bypassCode.isNotEmpty;
        
        // Show success dialog with appropriate message
        if (context.mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  const SizedBox(width: 8),
                  const Text('Survey Submitted!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your survey has been submitted successfully.',
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  if (wasApprovedImmediately)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your survey has been approved and is now live in the public feed!',
                              style: TextStyle(fontSize: 13, color: Colors.green.shade900),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.pending_actions, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your survey is pending admin approval before it appears in the public feed.',
                              style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Got it!', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
        
        // Navigate back to home
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
            _buildInfoItem('Title', widget.surveyData.title, Icons.title),
            _buildInfoItem('Caption', widget.surveyData.caption, Icons.short_text),
            _buildInfoItem('Description', widget.surveyData.description, Icons.description),
            _buildInfoItem(
                'Time to Complete', '${widget.surveyData.timeToComplete} minutes', Icons.timer),
            _buildInfoItem('Tags', widget.surveyData.tags.join(', '), Icons.label),
            _buildInfoItem('Target Audience', widget.surveyData.targetAudience.join(', '), Icons.people),
            const SizedBox(height: 24),
            _buildSectionHeader('Questions (${widget.surveyData.questions.length})'),
            ...widget.surveyData.questions
                .asMap()
                .entries
                .map((entry) => _buildQuestionPreview(entry.value, entry.key)),
            const SizedBox(height: 24),
            // Bypass Code Section
            _buildBypassCodeSection(),
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