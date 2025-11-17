enum QuestionType {
  multipleChoice,
  checkbox,
  dropdown,
  textResponse,
  longTextResponse,
  ratingScale,
  yesNo,
}

extension QuestionTypeExtension on QuestionType {
  String toJson() => name;
  
  static QuestionType fromJson(String json) {
    return QuestionType.values.firstWhere(
      (type) => type.name == json,
      orElse: () => throw ArgumentError('Invalid QuestionType value: $json'),
    );
  }

  /// Convert to backend string format (camelCase)
  String toBackendString() {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'multipleChoice';
      case QuestionType.checkbox:
        return 'checkbox';
      case QuestionType.dropdown:
        return 'dropdown';
      case QuestionType.textResponse:
        return 'textResponse';
      case QuestionType.longTextResponse:
        return 'longTextResponse';
      case QuestionType.ratingScale:
        return 'ratingScale';
      case QuestionType.yesNo:
        return 'yesNo';
    }
  }

  /// Display name for UI
  String displayName() {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.checkbox:
        return 'Checkboxes';
      case QuestionType.dropdown:
        return 'Dropdown';
      case QuestionType.textResponse:
        return 'Short Text';
      case QuestionType.longTextResponse:
        return 'Long Text (Paragraph)';
      case QuestionType.ratingScale:
        return 'Rating Scale';
      case QuestionType.yesNo:
        return 'Yes/No';
    }
  }
}
