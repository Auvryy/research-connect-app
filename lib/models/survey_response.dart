import 'question_type.dart';

/// Model for storing user's survey responses
class SurveyResponse {
  final String surveyId;
  final String respondentId;
  final DateTime startedAt;
  DateTime? completedAt;
  final Map<String, QuestionAnswer> answers; // questionId -> answer
  bool isComplete;

  SurveyResponse({
    required this.surveyId,
    required this.respondentId,
    required this.startedAt,
    this.completedAt,
    Map<String, QuestionAnswer>? answers,
    this.isComplete = false,
  }) : answers = answers ?? {};

  /// Add or update an answer
  void setAnswer(String questionId, QuestionAnswer answer) {
    answers[questionId] = answer;
  }

  /// Check if a question has been answered
  bool hasAnswer(String questionId) {
    return answers.containsKey(questionId) && answers[questionId]!.hasValue();
  }

  /// Get answer for a question
  QuestionAnswer? getAnswer(String questionId) {
    return answers[questionId];
  }

  /// Mark survey as completed
  void complete() {
    isComplete = true;
    completedAt = DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'surveyId': surveyId,
      'respondentId': respondentId,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'answers': answers.map((key, value) => MapEntry(key, value.toJson())),
      'isComplete': isComplete,
    };
  }

  factory SurveyResponse.fromJson(Map<String, dynamic> json) {
    return SurveyResponse(
      surveyId: json['surveyId'] as String,
      respondentId: json['respondentId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      answers: (json['answers'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          QuestionAnswer.fromJson(value as Map<String, dynamic>),
        ),
      ),
      isComplete: json['isComplete'] as bool,
    );
  }

  /// Convert to backend submission format
  Map<String, dynamic> toBackendJson() {
    return {
      'surveyId': surveyId,
      'respondentId': respondentId,
      'completedAt': completedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'answers': answers.entries.map((entry) => {
        'questionId': entry.key,
        ...entry.value.toBackendJson(),
      }).toList(),
    };
  }
}

/// Model for storing answer to a single question
class QuestionAnswer {
  final QuestionType questionType;
  
  // Different answer types based on question type
  String? textAnswer; // for textResponse, longTextResponse
  String? singleChoiceAnswer; // for multipleChoice, dropdown, yesNo
  List<String>? multipleChoiceAnswers; // for checkbox
  int? ratingAnswer; // for ratingScale

  QuestionAnswer({
    required this.questionType,
    this.textAnswer,
    this.singleChoiceAnswer,
    this.multipleChoiceAnswers,
    this.ratingAnswer,
  });

  /// Check if this answer has a value
  bool hasValue() {
    switch (questionType) {
      case QuestionType.textResponse:
      case QuestionType.longTextResponse:
        return textAnswer != null && textAnswer!.isNotEmpty;
      case QuestionType.multipleChoice:
      case QuestionType.dropdown:
      case QuestionType.yesNo:
        return singleChoiceAnswer != null && singleChoiceAnswer!.isNotEmpty;
      case QuestionType.checkbox:
        return multipleChoiceAnswers != null && multipleChoiceAnswers!.isNotEmpty;
      case QuestionType.ratingScale:
        return ratingAnswer != null;
    }
  }

  /// Get answer value as string for display
  String getDisplayValue() {
    switch (questionType) {
      case QuestionType.textResponse:
      case QuestionType.longTextResponse:
        return textAnswer ?? '';
      case QuestionType.multipleChoice:
      case QuestionType.dropdown:
      case QuestionType.yesNo:
        return singleChoiceAnswer ?? '';
      case QuestionType.checkbox:
        return multipleChoiceAnswers?.join(', ') ?? '';
      case QuestionType.ratingScale:
        return ratingAnswer?.toString() ?? '';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'questionType': questionType.toJson(),
      'textAnswer': textAnswer,
      'singleChoiceAnswer': singleChoiceAnswer,
      'multipleChoiceAnswers': multipleChoiceAnswers,
      'ratingAnswer': ratingAnswer,
    };
  }

  factory QuestionAnswer.fromJson(Map<String, dynamic> json) {
    return QuestionAnswer(
      questionType: QuestionTypeExtension.fromJson(json['questionType'] as String),
      textAnswer: json['textAnswer'] as String?,
      singleChoiceAnswer: json['singleChoiceAnswer'] as String?,
      multipleChoiceAnswers: json['multipleChoiceAnswers'] != null
          ? List<String>.from(json['multipleChoiceAnswers'])
          : null,
      ratingAnswer: json['ratingAnswer'] as int?,
    );
  }

  /// Convert to backend submission format
  Map<String, dynamic> toBackendJson() {
    final Map<String, dynamic> json = {
      'type': questionType.toBackendString(),
    };

    switch (questionType) {
      case QuestionType.textResponse:
      case QuestionType.longTextResponse:
        json['answer'] = textAnswer;
        break;
      case QuestionType.multipleChoice:
      case QuestionType.dropdown:
      case QuestionType.yesNo:
        json['answer'] = singleChoiceAnswer;
        break;
      case QuestionType.checkbox:
        json['answer'] = multipleChoiceAnswers;
        break;
      case QuestionType.ratingScale:
        json['answer'] = ratingAnswer;
        break;
    }

    return json;
  }

  /// Factory constructors for different question types
  factory QuestionAnswer.text(String answer) {
    return QuestionAnswer(
      questionType: QuestionType.textResponse,
      textAnswer: answer,
    );
  }

  factory QuestionAnswer.longText(String answer) {
    return QuestionAnswer(
      questionType: QuestionType.longTextResponse,
      textAnswer: answer,
    );
  }

  factory QuestionAnswer.singleChoice(QuestionType type, String answer) {
    return QuestionAnswer(
      questionType: type,
      singleChoiceAnswer: answer,
    );
  }

  factory QuestionAnswer.multipleChoice(List<String> answers) {
    return QuestionAnswer(
      questionType: QuestionType.checkbox,
      multipleChoiceAnswers: answers,
    );
  }

  factory QuestionAnswer.rating(int rating) {
    return QuestionAnswer(
      questionType: QuestionType.ratingScale,
      ratingAnswer: rating,
    );
  }

  factory QuestionAnswer.yesNo(bool answer) {
    return QuestionAnswer(
      questionType: QuestionType.yesNo,
      singleChoiceAnswer: answer ? 'Yes' : 'No',
    );
  }
}
