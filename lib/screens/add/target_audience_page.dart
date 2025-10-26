import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/models/survey_creation.dart';
import 'package:inquira/widgets/primary_button.dart';

class TargetAudiencePage extends StatefulWidget {
  final SurveyCreation surveyData;

  const TargetAudiencePage({
    super.key,
    required this.surveyData,
  });

  @override
  State<TargetAudiencePage> createState() => _TargetAudiencePageState();
}

class _TargetAudiencePageState extends State<TargetAudiencePage> {
  final List<String> _availableAudiences = [
    'Students',
    'Business Students',
    'General Public',
    'Professionals',
    'Educators',
    'Healthcare Workers',
    'IT Professionals',
    'Researchers',
    'Parents',
    'Senior Citizens',
  ];

  final Set<String> _selectedAudiences = {};

  @override
  void initState() {
    super.initState();
    _selectedAudiences.addAll(widget.surveyData.targetAudience);
  }

  void _proceedToQuestions() {
    if (_selectedAudiences.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one target audience'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final updatedSurvey = SurveyCreation(
      id: widget.surveyData.id,
      title: widget.surveyData.title,
      caption: widget.surveyData.caption,
      description: widget.surveyData.description,
      timeToComplete: widget.surveyData.timeToComplete,
      tags: widget.surveyData.tags,
      targetAudience: _selectedAudiences.toList(),
      questions: widget.surveyData.questions,
      sections: widget.surveyData.sections,
      isDraft: widget.surveyData.isDraft,
    );

    Navigator.pushNamed(
      context,
      '/create-survey/questions',
      arguments: updatedSurvey,
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
          'Target Audience',
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
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _availableAudiences.length,
        itemBuilder: (context, index) {
          final audience = _availableAudiences[index];
          return CheckboxListTile(
            title: Text(audience),
            value: _selectedAudiences.contains(audience),
            onChanged: (bool? value) {
              setState(() {
                if (value ?? false) {
                  _selectedAudiences.add(audience);
                } else {
                  _selectedAudiences.remove(audience);
                }
              });
            },
            activeColor: AppColors.primary,
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryButton(
            onPressed: _proceedToQuestions,
            text: 'Next',
          ),
        ),
      ),
    );
  }
}