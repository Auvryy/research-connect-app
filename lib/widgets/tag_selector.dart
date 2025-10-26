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
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: widget.availableTags.map((tag) {
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
      }).toList(),
    );
  }
}