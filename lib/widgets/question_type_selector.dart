import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/models/question_type.dart';

class QuestionTypeSelector extends StatelessWidget {
  final Function(QuestionType) onTypeSelected;

  const QuestionTypeSelector({
    super.key,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Question Type',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: QuestionType.values.map((type) {
              return _QuestionTypeCard(
                type: type,
                onTap: () {
                  onTypeSelected(type);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _QuestionTypeCard extends StatelessWidget {
  final QuestionType type;
  final VoidCallback onTap;

  const _QuestionTypeCard({
    required this.type,
    required this.onTap,
  });

  String get typeTitle {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.checkbox:
        return 'Checkbox';
      case QuestionType.textResponse:
        return 'Short Text';
      case QuestionType.longTextResponse:
        return 'Long Text';
      case QuestionType.ratingScale:
        return 'Rating (Stars)';
      case QuestionType.dropdown:
        return 'Dropdown';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case QuestionType.multipleChoice:
        return Icons.radio_button_checked;
      case QuestionType.checkbox:
        return Icons.check_box;
      case QuestionType.textResponse:
        return Icons.short_text;
      case QuestionType.longTextResponse:
        return Icons.text_fields;
      case QuestionType.ratingScale:
        return Icons.star;
      case QuestionType.dropdown:
        return Icons.arrow_drop_down_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondaryBG,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(typeIcon, size: 32, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              typeTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}