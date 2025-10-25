import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/models/survey_creation.dart';
import 'package:inquira/models/question_type.dart';
import 'package:inquira/widgets/custom_textfield.dart';
import 'package:image_picker/image_picker.dart';

class QuestionEditor extends StatefulWidget {
  final SurveyQuestion question;
  final Function(SurveyQuestion) onQuestionUpdated;
  final VoidCallback onDelete;

  const QuestionEditor({
    super.key,
    required this.question,
    required this.onQuestionUpdated,
    required this.onDelete,
  });

  @override
  State<QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<QuestionEditor> {
  late TextEditingController _questionController;
  final _optionsControllers = <TextEditingController>[];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.question.text);
    for (var option in widget.question.options) {
      _optionsControllers.add(TextEditingController(text: option));
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _optionsControllers.add(TextEditingController());
      _updateQuestion();
    });
  }

  void _removeOption(int index) {
    setState(() {
      _optionsControllers[index].dispose();
      _optionsControllers.removeAt(index);
      _updateQuestion();
    });
  }

  void _updateQuestion({
    String? text,
    bool? required,
    List<String>? options,
    String? imageUrl,
    String? videoUrl,
  }) {
    widget.onQuestionUpdated(
      widget.question.copyWith(
        text: text ?? _questionController.text,
        required: required,
        options: options ?? _optionsControllers.map((c) => c.text).toList(),
        imageUrl: imageUrl,
        videoUrl: videoUrl,
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // Here you would typically upload the image and get a URL
        // For now, we'll just store the local path
        setState(() {
          _updateQuestion(imageUrl: image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to pick image'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildQuestionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _questionController,
          label: 'Question',
          onChanged: (_) => _updateQuestion(),
        ),
        const SizedBox(height: 16),
        if (_shouldShowOptions())
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Options'),
              const SizedBox(height: 8),
              ..._buildOptions(),
              TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add),
                label: const Text('Add Option'),
              ),
            ],
          ),
        if (widget.question.type == QuestionType.ratingScale)
          const Text('Rating scale from 1-5 will be shown'),
        Row(
          children: [
            Switch(
              value: widget.question.required,
              onChanged: (value) {
                setState(() {
                  _updateQuestion(required: value);
                });
              },
              activeColor: AppColors.primary,
            ),
            const Text(
              'Required',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.image),
              onPressed: _pickImage,
              tooltip: 'Add Image',
              color: widget.question.imageUrl != null
                  ? AppColors.accent1
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: widget.onDelete,
              tooltip: 'Delete Question',
              color: AppColors.error,
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildOptions() {
    return List.generate(_optionsControllers.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _optionsControllers[index],
                label: 'Option ${index + 1}',
                onChanged: (_) => _updateQuestion(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => _removeOption(index),
            ),
          ],
        ),
      );
    });
  }

  bool _shouldShowOptions() {
    return widget.question.type == QuestionType.multipleChoice ||
        widget.question.type == QuestionType.checkbox ||
        widget.question.type == QuestionType.dropdown;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.question.required 
              ? AppColors.primary.withOpacity(0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildQuestionContent(),
      ),
    );
  }
}