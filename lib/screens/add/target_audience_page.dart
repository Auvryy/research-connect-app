import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/models/survey_creation.dart';
import 'package:inquira/widgets/primary_button.dart';
import 'package:inquira/data/draft_service.dart';

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

  // Icon mapping for each audience type
  final Map<String, IconData> _audienceIcons = {
    'Students': Icons.school,
    'Business Students': Icons.business_center,
    'General Public': Icons.public,
    'Professionals': Icons.work,
    'Educators': Icons.menu_book,
    'Healthcare Workers': Icons.local_hospital,
    'IT Professionals': Icons.computer,
    'Researchers': Icons.science,
    'Parents': Icons.family_restroom,
    'Senior Citizens': Icons.elderly,
  };

  final Set<String> _selectedAudiences = {};
  final TextEditingController _customAudienceController = TextEditingController();
  bool _showOthersInput = false;
  final List<String> _customAudiences = [];
  static const int _maxAudiences = 5;

  @override
  void initState() {
    super.initState();
    // Separate predefined and custom audiences
    for (final audience in widget.surveyData.targetAudience) {
      if (_availableAudiences.contains(audience)) {
        _selectedAudiences.add(audience);
      } else {
        _customAudiences.add(audience);
        _selectedAudiences.add(audience);
      }
    }
  }

  @override
  void dispose() {
    _customAudienceController.dispose();
    super.dispose();
  }

  Future<void> _proceedToQuestions() async {
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

    // Save draft before navigating
    await DraftService.saveDraft(updatedSurvey);

    if (mounted) {
      Navigator.pushNamed(
        context,
        '/create-survey/questions',
        arguments: updatedSurvey,
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableAudiences.map((audience) {
              final isSelected = _selectedAudiences.contains(audience);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedAudiences.remove(audience);
                    } else {
                      if (_selectedAudiences.length >= _maxAudiences) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Maximum $_maxAudiences audiences allowed'),
                            backgroundColor: AppColors.error,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      _selectedAudiences.add(audience);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: (MediaQuery.of(context).size.width - 44) / 2,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.secondaryBG,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey.shade300,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : [],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _audienceIcons[audience] ?? Icons.person,
                        size: 40,
                        color: isSelected ? AppColors.primary : AppColors.secondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        audience,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.primaryText,
                        ),
                      ),
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Icon(
                            Icons.check_circle,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const Divider(height: 32),
          CheckboxListTile(
            title: const Text(
              'Others (Specify)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            value: _showOthersInput || _customAudiences.isNotEmpty,
            onChanged: (bool? value) {
              setState(() {
                _showOthersInput = value ?? false;
                if (!_showOthersInput) {
                  _customAudienceController.clear();
                  for (final custom in _customAudiences) {
                    _selectedAudiences.remove(custom);
                  }
                  _customAudiences.clear();
                }
              });
            },
            activeColor: AppColors.primary,
          ),
          if (_showOthersInput || _customAudiences.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _customAudienceController,
                    decoration: InputDecoration(
                      hintText: 'Enter custom audience',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add_circle, color: AppColors.primary),
                        onPressed: () {
                          final custom = _customAudienceController.text.trim();
                          if (custom.isEmpty) return;
                          
                          if (custom.length > 50) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Audience name must be 50 characters or less'),
                                backgroundColor: AppColors.error,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          
                          if (_selectedAudiences.length >= _maxAudiences) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Maximum $_maxAudiences audiences allowed'),
                                backgroundColor: AppColors.error,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          
                          if (!_customAudiences.contains(custom)) {
                            setState(() {
                              _customAudiences.add(custom);
                              _selectedAudiences.add(custom);
                              _customAudienceController.clear();
                            });
                          }
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onSubmitted: (value) {
                      final custom = value.trim();
                      if (custom.isNotEmpty && !_customAudiences.contains(custom)) {
                        setState(() {
                          _customAudiences.add(custom);
                          _selectedAudiences.add(custom);
                          _customAudienceController.clear();
                        });
                      }
                    },
                  ),
                  if (_customAudiences.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _customAudiences.map((custom) => Chip(
                        label: Text(custom),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            _customAudiences.remove(custom);
                            _selectedAudiences.remove(custom);
                            if (_customAudiences.isEmpty) {
                              _showOthersInput = false;
                            }
                          });
                        },
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
        ],
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