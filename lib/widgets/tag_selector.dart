import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/widgets/custom_choice_chip.dart';

class TagSelector extends StatefulWidget {
  final List<String> selectedTags;
  final List<String> availableTags;
  final int maxTags;
  final Function(List<String>) onTagsChanged;

  const TagSelector({
    super.key,
    required this.selectedTags,
    required this.availableTags,
    this.maxTags = 3,
    required this.onTagsChanged,
  });

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  final TextEditingController _customTagController = TextEditingController();
  bool _showCustomInput = false;
  final List<String> _customTags = [];

  @override
  void initState() {
    super.initState();
    // Separate predefined and custom tags
    for (final tag in widget.selectedTags) {
      if (!widget.availableTags.contains(tag)) {
        _customTags.add(tag);
      }
    }
    if (_customTags.isNotEmpty) {
      _showCustomInput = true;
    }
  }

  @override
  void dispose() {
    _customTagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            ...widget.availableTags.map((tag) {
              final isSelected = widget.selectedTags.contains(tag);
              return CustomChoiceChip(
                label: tag,
                selected: isSelected,
                onSelected: (bool selected) {
                  if (selected && widget.selectedTags.length >= widget.maxTags) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Maximum ${widget.maxTags} tags allowed'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  final updatedTags = List<String>.from(widget.selectedTags);
                  if (selected) {
                    updatedTags.add(tag);
                  } else {
                    updatedTags.remove(tag);
                  }
                  widget.onTagsChanged(updatedTags);
                },
              );
            }),
            // Others option
            CustomChoiceChip(
              label: 'Others',
              selected: _showCustomInput || _customTags.isNotEmpty,
              onSelected: (bool selected) {
                setState(() {
                  _showCustomInput = selected;
                  if (!selected) {
                    _customTagController.clear();
                    final updatedTags = List<String>.from(widget.selectedTags);
                    for (final custom in _customTags) {
                      updatedTags.remove(custom);
                    }
                    _customTags.clear();
                    widget.onTagsChanged(updatedTags);
                  }
                });
              },
            ),
          ],
        ),
        if (_showCustomInput || _customTags.isNotEmpty) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _customTagController,
            decoration: InputDecoration(
              hintText: 'Enter custom tag',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.primary),
                onPressed: () {
                  if (widget.selectedTags.length >= widget.maxTags) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Maximum ${widget.maxTags} tags allowed'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  final custom = _customTagController.text.trim();
                  if (custom.isNotEmpty && !_customTags.contains(custom)) {
                    setState(() {
                      _customTags.add(custom);
                      final updatedTags = List<String>.from(widget.selectedTags);
                      updatedTags.add(custom);
                      widget.onTagsChanged(updatedTags);
                      _customTagController.clear();
                    });
                  }
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onSubmitted: (value) {
              if (widget.selectedTags.length >= widget.maxTags) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Maximum ${widget.maxTags} tags allowed'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              final custom = value.trim();
              if (custom.isNotEmpty && !_customTags.contains(custom)) {
                setState(() {
                  _customTags.add(custom);
                  final updatedTags = List<String>.from(widget.selectedTags);
                  updatedTags.add(custom);
                  widget.onTagsChanged(updatedTags);
                  _customTagController.clear();
                });
              }
            },
          ),
          if (_customTags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _customTags.map((custom) => Chip(
                label: Text(custom),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _customTags.remove(custom);
                    final updatedTags = List<String>.from(widget.selectedTags);
                    updatedTags.remove(custom);
                    widget.onTagsChanged(updatedTags);
                    if (_customTags.isEmpty) {
                      _showCustomInput = false;
                    }
                  });
                },
                backgroundColor: AppColors.primary.withOpacity(0.1),
              )).toList(),
            ),
          ],
        ],
      ],
    );
  }
}