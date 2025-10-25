import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/models/survey_creation.dart';
import 'package:inquira/widgets/custom_textfield.dart';
import 'package:inquira/widgets/tag_selector.dart';
import 'package:inquira/widgets/primary_button.dart';

class CreateSurveyPage extends StatefulWidget {
  const CreateSurveyPage({super.key});

  @override
  State<CreateSurveyPage> createState() => _CreateSurveyPageState();
}

class _CreateSurveyPageState extends State<CreateSurveyPage> {
  final _titleController = TextEditingController();
  final _captionController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _selectedTime = 5;
  final List<String> _selectedTags = [];

  final List<int> _availableTimes = [5, 15, 30, 45, 60];
  final List<String> _availableTags = [
    'Technology',
    'Psychology',
    'Health',
    'Education',
    'Business',
    'Science',
    'Social',
    'Environment',
    'Politics',
    'Art',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _proceedToNextPage() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one tag')),
      );
      return;
    }

    final surveyData = SurveyCreation(
      title: _titleController.text,
      caption: _captionController.text,
      description: _descriptionController.text,
      timeToComplete: _selectedTime,
      tags: _selectedTags,
    );

    Navigator.pushNamed(
      context,
      '/create-survey/audience',
      arguments: surveyData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Survey',
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
            CustomTextField(
              controller: _titleController,
              label: 'Survey Title',
              maxLength: 100,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _captionController,
              label: 'Caption',
              maxLength: 150,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _descriptionController,
              label: 'Detailed Description',
              maxLength: 500,
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            const Text(
              'Approximate Time to Complete',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _availableTimes.map((time) {
                return ChoiceChip(
                  label: Text('$time mins'),
                  selected: _selectedTime == time,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedTime = time);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Survey Tags (Select up to 3)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TagSelector(
              selectedTags: _selectedTags,
              availableTags: _availableTags,
              onTagsChanged: (tags) {
                setState(() => _selectedTags.clear());
                setState(() => _selectedTags.addAll(tags));
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryButton(
            onPressed: _proceedToNextPage,
            text: 'Next',
          ),
        ),
      ),
    );
  }
}