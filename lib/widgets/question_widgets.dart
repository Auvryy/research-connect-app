import 'package:flutter/material.dart';
import 'package:inquira/models/survey_question.dart';
import 'package:inquira/constants/colors.dart';

class QuestionWidget extends StatelessWidget {
  final SurveyQuestion question;
  final dynamic value;
  final Function(dynamic) onChanged;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question text with required indicator
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            children: [
              TextSpan(
                text: '${question.questionNumber}. ${question.questionText}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (question.required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Question input based on type
        _buildQuestionInput(context),
      ],
    );
  }

  Widget _buildQuestionInput(BuildContext context) {
    switch (question.questionType) {
      case 'shortText':
        return _buildShortText();
      case 'longText':
        return _buildLongText();
      case 'radioButton':
        return _buildRadioButtons();
      case 'checkBox':
        return _buildCheckboxes();
      case 'dropdown':
        return _buildDropdown();
      case 'rating':
        return _buildRating();
      case 'date':
        return _buildDatePicker(context);
      case 'email':
        return _buildEmailInput();
      case 'yesNo':
        return _buildYesNo();
      default:
        return Text('Unsupported question type: ${question.questionType}');
    }
  }

  Widget _buildShortText() {
    return TextField(
      onChanged: onChanged,
      controller: TextEditingController(text: value ?? ''),
      decoration: InputDecoration(
        hintText: 'Your answer',
        filled: true,
        fillColor: AppColors.inputColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildLongText() {
    return TextField(
      onChanged: onChanged,
      controller: TextEditingController(text: value ?? ''),
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Your detailed answer',
        filled: true,
        fillColor: AppColors.inputColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildRadioButtons() {
    return Column(
      children: question.choices.map((choice) {
        return RadioListTile<String>(
          title: Text(choice),
          value: choice,
          groupValue: value as String?,
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
          onChanged: (newValue) => onChanged(newValue),
        );
      }).toList(),
    );
  }

  Widget _buildCheckboxes() {
    final selectedValues = (value as List<String>?) ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question.minChoice > 0 || question.maxChoice > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Select ${question.minChoice}-${question.maxChoice} options',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ...question.choices.map((choice) {
          final isSelected = selectedValues.contains(choice);
          
          return CheckboxListTile(
            title: Text(choice),
            value: isSelected,
            onChanged: (checked) {
              final newList = List<String>.from(selectedValues);
              
              if (checked == true) {
                if (newList.length < question.maxChoice) {
                  newList.add(choice);
                }
              } else {
                newList.remove(choice);
              }
              
              onChanged(newList);
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: value as String?,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.inputColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      hint: const Text('Select an option'),
      items: question.choices.map((choice) {
        return DropdownMenuItem(
          value: choice,
          child: Text(choice),
        );
      }).toList(),
      onChanged: (newValue) => onChanged(newValue),
    );
  }

  Widget _buildRating() {
    final rating = (value is String) ? int.tryParse(value) ?? 0 : (value as int? ?? 0);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < rating ? Icons.star : Icons.star_border,
            size: 40,
          ),
          color: Colors.amber,
          onPressed: () => onChanged((index + 1).toString()),
        );
      }),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    final selectedDate = value != null ? DateTime.tryParse(value) : null;
    
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        
        if (date != null) {
          onChanged(date.toIso8601String().split('T')[0]);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          selectedDate != null
              ? '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'
              : 'Select a date',
        ),
      ),
    );
  }

  Widget _buildEmailInput() {
    return TextField(
      onChanged: onChanged,
      controller: TextEditingController(text: value ?? ''),
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        hintText: 'your.email@example.com',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildYesNo() {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<String>(
            title: const Text('Yes'),
            value: 'Yes',
            groupValue: value as String?,
            onChanged: (newValue) => onChanged(newValue),
          ),
        ),
        Expanded(
          child: RadioListTile<String>(
            title: const Text('No'),
            value: 'No',
            groupValue: value as String?,
            onChanged: (newValue) => onChanged(newValue),
          ),
        ),
      ],
    );
  }
}
