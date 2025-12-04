enum QuestionType {
  shortText,
  longText,
  radioButton,
  checkBox,
  rating,
  dropdown,
  date,
  email,
  number,
}

extension QuestionTypeExtension on QuestionType {
  String toJson() => name;
  
  static QuestionType fromJson(String json) {
    return QuestionType.values.firstWhere(
      (type) => type.name == json,
      orElse: () => throw ArgumentError('Invalid QuestionType value: $json'),
    );
  }

  /// Convert to backend string format matching Q_TYPE_WEB
  /// Backend expects: ("shortText", "longText", "radioButton", "checkBox", "rating", "dropdown", "date", "email", "number")
  String toBackendString() {
    switch (this) {
      case QuestionType.shortText:
        return 'shortText';
      case QuestionType.longText:
        return 'longText';
      case QuestionType.radioButton:
        return 'radioButton';
      case QuestionType.checkBox:
        return 'checkBox';
      case QuestionType.rating:
        return 'rating';
      case QuestionType.dropdown:
        return 'dropdown';
      case QuestionType.date:
        return 'date';
      case QuestionType.email:
        return 'email';
      case QuestionType.number:
        return 'number';
    }
  }

  /// Display name for UI
  String displayName() {
    switch (this) {
      case QuestionType.shortText:
        return 'Short Text';
      case QuestionType.longText:
        return 'Long Text (Essay)';
      case QuestionType.radioButton:
        return 'Radio Button (Single Choice)';
      case QuestionType.checkBox:
        return 'Checkbox (Multiple Choice)';
      case QuestionType.rating:
        return 'Rating Scale (1-5)';
      case QuestionType.dropdown:
        return 'Dropdown';
      case QuestionType.date:
        return 'Date Picker';
      case QuestionType.email:
        return 'Email Address';
      case QuestionType.number:
        return 'Number Input';
    }
  }
  
  /// Check if question type requires options
  bool requiresOptions() {
    switch (this) {
      case QuestionType.radioButton:
      case QuestionType.checkBox:
      case QuestionType.dropdown:
        return true;
      default:
        return false;
    }
  }
  
  /// Check if question type requires minChoice/maxChoice
  /// Backend CHOICES_MAX_MIN_TYPE_MOBILE = ("checkBox", "dropdown")
  bool requiresMinMaxChoice() {
    return this == QuestionType.checkBox || this == QuestionType.dropdown;
  }
}
