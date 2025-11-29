import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/models/survey_creation.dart';
import 'package:inquira/widgets/custom_textfield.dart';
import 'package:inquira/widgets/tag_selector.dart';
import 'package:inquira/widgets/primary_button.dart';
import 'package:inquira/data/draft_service.dart';

class CreateSurveyPage extends StatefulWidget {
  const CreateSurveyPage({super.key});

  @override
  State<CreateSurveyPage> createState() => _CreateSurveyPageState();
}

class _CreateSurveyPageState extends State<CreateSurveyPage> {
  final _titleController = TextEditingController();
  final _captionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customTimeController = TextEditingController();
  int _selectedTime = 5;
  bool _useCustomTime = false;
  final List<String> _selectedTags = [];
  bool _isLoadingDraft = true;

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
  void initState() {
    super.initState();
    _loadDraft();
    
    // Add listeners to update character counters
    _titleController.addListener(() {
      setState(() {});
    });
    _captionController.addListener(() {
      setState(() {});
    });
    _descriptionController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _loadDraft() async {
    final draft = await DraftService.loadDraft();
    if (draft != null && mounted) {
      setState(() {
        _titleController.text = draft.title;
        _captionController.text = draft.caption;
        _descriptionController.text = draft.description;
        _selectedTime = draft.timeToComplete;
        _selectedTags.clear();
        _selectedTags.addAll(draft.tags);
        _isLoadingDraft = false;
      });
    } else {
      setState(() => _isLoadingDraft = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _proceedToNextPage() async {
    final title = _titleController.text.trim();
    final caption = _captionController.text.trim();
    final description = _descriptionController.text.trim();

    // Validate title (4-40 words, max 512 characters)
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }
    final titleWords = title.split(RegExp(r'\s+'));
    if (titleWords.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title must be at least 4 words')),
      );
      return;
    }
    if (titleWords.length > 40) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title must not exceed 40 words')),
      );
      return;
    }
    if (title.length > 512) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title must not exceed 512 characters')),
      );
      return;
    }

    // Validate caption (5-400 words, max 5000 characters) - backend post content validation
    if (caption.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a caption')),
      );
      return;
    }
    final captionWords = caption.split(RegExp(r'\s+'));
    if (captionWords.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caption must be at least 5 words')),
      );
      return;
    }
    if (captionWords.length > 400) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caption must not exceed 400 words')),
      );
      return;
    }
    if (caption.length > 5000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caption must not exceed 5000 characters')),
      );
      return;
    }

    // Validate description (5-100 words, max 5000 characters) - backend survey description validation
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }
    final descWords = description.split(RegExp(r'\s+'));
    if (descWords.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description must be at least 5 words')),
      );
      return;
    }
    if (descWords.length > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description must not exceed 100 words')),
      );
      return;
    }
    if (description.length > 5000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description must not exceed 5000 characters')),
      );
      return;
    }

    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one tag')),
      );
      return;
    }

    // Load existing draft to preserve questions and sections
    final existingDraft = await DraftService.loadDraft();

    final surveyData = SurveyCreation(
      title: _titleController.text,
      caption: _captionController.text,
      description: _descriptionController.text,
      timeToComplete: _selectedTime,
      tags: _selectedTags,
      targetAudience: existingDraft?.targetAudience ?? [],
      questions: existingDraft?.questions ?? [],
      sections: existingDraft?.sections ?? [],
    );

    // Save draft before navigating
    await DraftService.saveDraft(surveyData);

    if (mounted) {
      Navigator.pushNamed(
        context,
        '/create-survey/audience',
        arguments: surveyData,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDraft) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            // Ask user if they want to continue editing or discard
            await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Save Progress?'),
                content: const Text('Your progress is automatically saved. Do you want to continue editing later?'),
                actions: [
                  TextButton(
                    onPressed: () async {
                      await DraftService.clearDraft();
                      if (context.mounted) Navigator.pop(context, false);
                    },
                    child: const Text('Discard All'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Keep Draft', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
            
            // Draft is already saved, just close
            if (context.mounted) Navigator.of(context).pop();
          },
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
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(
                '${_titleController.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length}/40 words, ${_titleController.text.length}/512 chars',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _captionController,
              label: 'Caption',
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(
                '${_captionController.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length}/400 words, ${_captionController.text.length}/5000 chars (min 5 words)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _descriptionController,
              label: 'Detailed Description',
              maxLines: 5,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(
                '${_descriptionController.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length}/100 words, ${_descriptionController.text.length}/5000 chars (min 5 words)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
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
              runSpacing: 8,
              children: [
                ..._availableTimes.map((time) {
                  return ChoiceChip(
                    label: Text('$time mins'),
                    selected: !_useCustomTime && _selectedTime == time,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedTime = time;
                          _useCustomTime = false;
                        });
                      }
                    },
                  );
                }),
                ChoiceChip(
                  label: const Text('Custom'),
                  selected: _useCustomTime,
                  onSelected: (selected) {
                    setState(() {
                      _useCustomTime = selected;
                    });
                  },
                ),
              ],
            ),
            if (_useCustomTime) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customTimeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter minutes',
                  suffixText: 'mins',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (value) {
                  final time = int.tryParse(value);
                  if (time != null && time > 0) {
                    setState(() {
                      _selectedTime = time;
                    });
                  }
                },
              ),
            ],
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