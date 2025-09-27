import 'package:flutter/foundation.dart';

/// Survey object
class Survey {
  final String id;
  final String title;
  final String description;
  final int timeToComplete; // in minutes
  final List<String> tags; // up to 3
  final String targetAudience;
  final String creator;
  final DateTime createdAt;
  final bool status; // true = active, false = closed
  int responses; // number of responses
  final List<Question> questions;

  Survey({
    required this.id,
    required this.title,
    required this.description,
    required this.timeToComplete,
    required this.tags,
    required this.targetAudience,
    required this.creator,
    required this.createdAt,
    required this.status,
    required this.questions,
    this.responses = 0, // default to 0
  });

  /// Convenience method to increment response count
  void addResponse() {
    responses++;
  }
}

/// Question object
class Question {
  final String questionId;
  final String text;
  final QuestionType type;
  final bool required;
  final List<String>? options; // only used for multipleChoice/checkbox/dropdown

  Question({
    required this.questionId,
    required this.text,
    required this.type,
    this.required = false,
    this.options,
  });
}

/// Question types supported
enum QuestionType {
  multipleChoice,
  checkbox,
  textResponse,
  longTextResponse,
  ratingScale,
  dropdown,
}
