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
      case QuestionType.number:
        return 'Number';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case QuestionType.shortText:
        return Icons.short_text;
      case QuestionType.longText:
        return Icons.text_fields;
      case QuestionType.radioButton:
        return Icons.radio_button_checked;
      case QuestionType.checkBox:
        return Icons.check_box;
      case QuestionType.rating:
        return Icons.star;
      case QuestionType.dropdown:
        return Icons.arrow_drop_down_circle;
      case QuestionType.date:
        return Icons.calendar_today;
      case QuestionType.email:
        return Icons.email;
      case QuestionType.number:
        return Icons.numbers;
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