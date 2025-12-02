import 'question_type.dart';

/// Survey object representing a survey in the system
class Survey {
  final String id;
  final int? postId; // Backend database ID
  final String title;
  final String caption; // Short description for feed
  final String description; // Full description for survey takers
  final int timeToComplete; // in minutes
  final List<String> tags; // up to 3
  final String targetAudience;
  final String creator;
  final DateTime createdAt;
  final bool status; // true = active, false = closed
  final bool approved; // true = approved by admin, false = pending
  final bool archived; // true = archived, false = active
  int responses; // number of responses
  int numOfLikes; // number of likes
  bool isLiked; // whether current user has liked this survey
  final List<Question> questions;

  Survey({
    required this.id,
    this.postId,
    required this.title,
    this.caption = '',
    required this.description,
    required this.timeToComplete,
    required this.tags,
    required this.targetAudience,
    required this.creator,
    required this.createdAt,
    required this.status,
    this.approved = false, // default to false (pending)
    this.archived = false, // default to false
    required this.questions,
    this.responses = 0, // default to 0
    this.numOfLikes = 0, // default to 0
    this.isLiked = false, // default to false
  });

  /// Convenience method to increment response count
  void addResponse() {
    responses++;
  }

  /// Toggle like status locally
  void toggleLike() {
    if (isLiked) {
      isLiked = false;
      numOfLikes = numOfLikes > 0 ? numOfLikes - 1 : 0;
    } else {
      isLiked = true;
      numOfLikes++;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pk_survey_id': postId,
      'title': title,
      'caption': caption,
      'description': description,
      'timeToComplete': timeToComplete,
      'tags': tags,
      'targetAudience': targetAudience,
      'creator': creator,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'approved': approved,
      'archived': archived,
      'responses': responses,
      'num_of_likes': numOfLikes,
      'is_liked': isLiked,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }

  factory Survey.fromJson(Map<String, dynamic> json) {
    return Survey(
      id: json['id'] as String,
      postId: json['pk_survey_id'] as int?,
      title: json['title'] as String,
      caption: json['caption'] as String? ?? '',
      description: json['description'] as String,
      timeToComplete: json['timeToComplete'] as int,
      tags: List<String>.from(json['tags']),
      targetAudience: json['targetAudience'] as String,
      creator: json['creator'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as bool,
      approved: json['approved'] as bool? ?? false,
      archived: json['archived'] as bool? ?? false,
      responses: json['responses'] as int,
      numOfLikes: json['num_of_likes'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
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
