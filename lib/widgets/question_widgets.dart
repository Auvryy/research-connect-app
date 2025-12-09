import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inquira/models/survey_question.dart';
import 'package:inquira/constants/colors.dart';
import 'package:url_launcher/url_launcher.dart';

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
        
        // Question image if present
        if (question.imageUrl != null && question.imageUrl!.isNotEmpty) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              question.imageUrl!,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
            ),
          ),
        ],
        
        // Video URL link if present
        if (question.videoUrl != null && question.videoUrl!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent1.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent1.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent1,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.play_circle_outline, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Video Resource',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final url = Uri.parse(question.videoUrl!);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.accent1.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            question.videoUrl!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.accent1,
                              decoration: TextDecoration.underline,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: AppColors.accent1.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tap to open in browser',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: question.videoUrl!));
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.copy,
                            size: 14,
                            color: AppColors.accent1.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Copy',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.accent1.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        
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
      case 'number':
        return _buildNumberInput();
      case 'yesNo':
        return _buildYesNo();
      default:
        return Text('Unsupported question type: ${question.questionType}');
    }
  }

  Widget _buildShortText() {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      onChanged: onChanged,
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
    return TextFormField(
      initialValue: value?.toString() ?? '',
      onChanged: onChanged,
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
    final groupVal = value?.toString();
    return Column(
      children: question.choices.map((choice) {
        return RadioListTile<String>(
          title: Text(choice),
          value: choice,
          groupValue: groupVal,
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
          onChanged: (newValue) => onChanged(newValue),
        );
      }).toList(),
    );
  }

  Widget _buildCheckboxes() {
    // Safely convert value to List<String> handling List<dynamic> case
    List<String> selectedValues = [];
    if (value != null && value is List) {
      selectedValues = (value as List).map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }
    
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
    // Ensure value is in choices list, otherwise set to null
    final currentValue = (value != null && question.choices.contains(value)) 
        ? value as String 
        : null;
    
    return DropdownButtonFormField<String>(
      value: currentValue,
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
      isExpanded: true,
      items: question.choices.map((choice) {
        return DropdownMenuItem(
          value: choice,
          child: Text(
            choice,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        );
      }).toList(),
      onChanged: (newValue) => onChanged(newValue),
    );
  }

  Widget _buildRating() {
    final rating = (value is String) ? int.tryParse(value) ?? 0 : (value as int? ?? 0);
    final maxStars = question.maxRating > 0 ? question.maxRating : 5;
    
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 8,
      children: List.generate(maxStars, (index) {
        return IconButton(
          icon: Icon(
            index < rating ? Icons.star : Icons.star_border,
            size: maxStars > 5 ? 32 : 40,
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
    return TextFormField(
      initialValue: value?.toString() ?? '',
      onChanged: onChanged,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: 'your.email@example.com',
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

  Widget _buildNumberInput() {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        hintText: 'Enter a number (e.g., 42, -10, 3.14)',
        filled: true,
        fillColor: AppColors.inputColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(Icons.numbers, color: Colors.grey[500]),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildYesNo() {
    final groupVal = value?.toString();
    return Row(
      children: [
        Expanded(
          child: RadioListTile<String>(
            title: const Text('Yes'),
            value: 'Yes',
            groupValue: groupVal,
            onChanged: (newValue) => onChanged(newValue),
          ),
        ),
        Expanded(
          child: RadioListTile<String>(
            title: const Text('No'),
            value: 'No',
            groupValue: groupVal,
            onChanged: (newValue) => onChanged(newValue),
          ),
        ),
      ],
    );
  }
}
