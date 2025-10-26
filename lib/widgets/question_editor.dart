import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/models/survey_creation.dart';
import 'package:inquira/models/question_type.dart';
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
  final List<TextEditingController> _optionsControllers = [];
  final ImagePicker _picker = ImagePicker();
  int _maxRating = 5;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.question.text);
    
    // Initialize option controllers
    for (var option in widget.question.options) {
      _optionsControllers.add(TextEditingController(text: option));
    }
    
    // Initialize rating if exists
    if (widget.question.type == QuestionType.ratingScale) {
      _maxRating = 5; // Default to 5 stars
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

  void _addOption() {
    setState(() {
      _optionsControllers.add(TextEditingController(text: 'Option ${_optionsControllers.length + 1}'));
      _updateQuestion();
    });
  }

  void _removeOption(int index) {
    if (_optionsControllers.length > 1) {
      setState(() {
        _optionsControllers[index].dispose();
        _optionsControllers.removeAt(index);
        _updateQuestion();
      });
    }
  }

  Future<void> _pickImage() async {
    // Check if video already exists (limit to one media)
    if (widget.question.videoUrl != null && widget.question.videoUrl!.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please remove the video first. Only one media item allowed per question.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          // Clear video and set image
          widget.onQuestionUpdated(
            widget.question.copyWith(
              imageUrl: image.path,
              videoUrl: '',
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to pick image'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    // Check if image already exists (limit to one media)
    if (widget.question.imageUrl != null && widget.question.imageUrl!.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please remove the image first. Only one media item allowed per question.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          // Clear image and set video
          widget.onQuestionUpdated(
            widget.question.copyWith(
              imageUrl: '',
              videoUrl: video.path,
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to pick video'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeMedia() {
    // Clear both image and video URLs
    _updateQuestion(imageUrl: '', videoUrl: '');
  }

  bool _shouldShowOptions() {
    return widget.question.type == QuestionType.multipleChoice ||
        widget.question.type == QuestionType.checkbox ||
        widget.question.type == QuestionType.dropdown;
  }

  Widget _buildOptionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Options',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        ..._optionsControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  widget.question.type == QuestionType.multipleChoice
                      ? Icons.radio_button_unchecked
                      : widget.question.type == QuestionType.checkbox
                          ? Icons.check_box_outline_blank
                          : Icons.arrow_drop_down,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Option ${index + 1}',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      isDense: true,
                    ),
                    onChanged: (_) => _updateQuestion(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.error,
                  onPressed: () => _removeOption(index),
                  tooltip: 'Remove option',
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _addOption,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Option'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Rating Configuration',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Max Stars:'),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<int>(
                value: _maxRating,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down),
                items: List.generate(5, (index) {
                  final stars = index + 1;
                  return DropdownMenuItem<int>(
                    value: stars,
                    child: Text('$stars Star${stars > 1 ? 's' : ''}'),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _maxRating = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(_maxRating, (index) {
            return const Icon(
              Icons.star,
              color: Colors.amber,
              size: 24,
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.question.required
              ? AppColors.primary.withOpacity(0.3)
              : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with drag handle
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.drag_indicator,
                  color: Colors.grey[400],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getTypeLabel(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.error,
                  onPressed: widget.onDelete,
                  tooltip: 'Delete question',
                ),
              ],
            ),
          ),

          // Question content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Question text field
                TextField(
                  controller: _questionController,
                  maxLines: null,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your question',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  onChanged: (_) => _updateQuestion(),
                ),

                // Options list for choice questions
                if (_shouldShowOptions()) _buildOptionsList(),

                // Rating configuration
                if (widget.question.type == QuestionType.ratingScale)
                  _buildRatingConfig(),

                // Text response placeholder
                if (widget.question.type == QuestionType.textResponse ||
                    widget.question.type == QuestionType.longTextResponse)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.question.type == QuestionType.textResponse
                            ? 'Short text answer'
                            : 'Long text answer (paragraph)',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Media attachments
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (widget.question.imageUrl != null && widget.question.imageUrl!.isNotEmpty)
                      Chip(
                        avatar: const Icon(Icons.image, size: 16),
                        label: const Text('Image attached'),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: _removeMedia,
                        backgroundColor: AppColors.accent1.withOpacity(0.1),
                      ),
                    if (widget.question.videoUrl != null && widget.question.videoUrl!.isNotEmpty)
                      Chip(
                        avatar: const Icon(Icons.videocam, size: 16),
                        label: const Text('Video attached'),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: _removeMedia,
                        backgroundColor: AppColors.accent1.withOpacity(0.1),
                      ),
                  ],
                ),

                const Divider(height: 24),

                // Footer actions
                Row(
                  children: [
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
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.image_outlined,
                        color: (widget.question.imageUrl != null && widget.question.imageUrl!.isNotEmpty)
                            ? AppColors.accent1
                            : Colors.grey[600],
                      ),
                      onPressed: (widget.question.videoUrl != null && widget.question.videoUrl!.isNotEmpty) 
                          ? null 
                          : _pickImage,
                      tooltip: (widget.question.videoUrl != null && widget.question.videoUrl!.isNotEmpty)
                          ? 'Remove video first'
                          : 'Add image',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.videocam_outlined,
                        color: (widget.question.videoUrl != null && widget.question.videoUrl!.isNotEmpty)
                            ? AppColors.accent1
                            : Colors.grey[600],
                      ),
                      onPressed: (widget.question.imageUrl != null && widget.question.imageUrl!.isNotEmpty)
                          ? null
                          : _pickVideo,
                      tooltip: (widget.question.imageUrl != null && widget.question.imageUrl!.isNotEmpty)
                          ? 'Remove image first'
                          : 'Add video',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel() {
    switch (widget.question.type) {
      case QuestionType.multipleChoice:
        return 'MULTIPLE CHOICE';
      case QuestionType.checkbox:
        return 'CHECKBOX';
      case QuestionType.textResponse:
        return 'SHORT TEXT';
      case QuestionType.longTextResponse:
        return 'LONG TEXT';
      case QuestionType.ratingScale:
        return 'RATING';
      case QuestionType.dropdown:
        return 'DROPDOWN';
    }
  }
}
