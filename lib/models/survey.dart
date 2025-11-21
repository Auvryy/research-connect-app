import 'question_type.dart';

/// Survey object representing a survey in the system
class Survey {
  final String id;
  final String title;
  final String caption; // Short description for feed
  final String description; // Full description for survey takers
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
    this.caption = '',
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'caption': caption,
      'description': description,
      'timeToComplete': timeToComplete,
      'tags': tags,
      'targetAudience': targetAudience,
      'creator': creator,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'responses': responses,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }

  factory Survey.fromJson(Map<String, dynamic> json) {
    return Survey(
      id: json['id'] as String,
      title: json['title'] as String,
      caption: json['caption'] as String? ?? '',
      description: json['description'] as String,
      timeToComplete: json['timeToComplete'] as int,
      tags: List<String>.from(json['tags']),
      targetAudience: json['targetAudience'] as String,
      creator: json['creator'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as bool,
      responses: json['responses'] as int,
      questions: (json['questions'] as List)
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Question object
class Question {
  final String questionId;
  final String text;
  final QuestionType type;
  final bool required;
  final List<String>? options; // only used for checkBox/checkbox/dropdown

  Question({
    required this.questionId,
    required this.text,
    required this.type,
    this.required = false,
    this.options,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'text': text,
      'type': type.toJson(),
      'required': required,
      'options': options,
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionId: json['questionId'] as String,
      text: json['text'] as String,
      type: QuestionTypeExtension.fromJson(json['type'] as String),
      required: json['required'] as bool,
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : null,
    );
  }
}
