enum QuestionType {
  multipleChoice,
  checkbox,
  textResponse,
  longTextResponse,
  ratingScale,
  dropdown,
  imageChoice,
  fileUpload,
  matrix,
  ranking,
}

extension QuestionTypeExtension on QuestionType {
  String toJson() => name;
  
  static QuestionType fromJson(String json) {
    return QuestionType.values.firstWhere(
      (type) => type.name == json,
      orElse: () => throw ArgumentError('Invalid QuestionType value: $json'),
    );
  }
}