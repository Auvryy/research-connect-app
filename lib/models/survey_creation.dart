import 'survey.dart';
import 'question_type.dart';

class SurveyCreation {
  String? id;
  String title;
  String caption;
  String description;
  int timeToComplete;
  List<String> tags;
  List<String> targetAudience;
  List<SurveyQuestion> questions;
  List<SurveySection> sections;
  bool isDraft;

  SurveyCreation({
    this.id,
    this.title = '',
    this.caption = '',
    this.description = '',
    this.timeToComplete = 5,
    List<String>? tags,
    List<String>? targetAudience,
    List<SurveyQuestion>? questions,
    List<SurveySection>? sections,
    this.isDraft = true,
  })  : tags = tags ?? [],
        targetAudience = targetAudience ?? [],
        questions = questions ?? [],
        sections = sections ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'caption': caption,
      'description': description,
      'timeToComplete': timeToComplete,
      'tags': tags,
      'targetAudience': targetAudience,
      'questions': questions.map((q) => q.toJson()).toList(),
      'sections': sections.map((s) => s.toJson()).toList(),
      'isDraft': isDraft,
    };
  }

  factory SurveyCreation.fromJson(Map<String, dynamic> json) {
    return SurveyCreation(
      id: json['id'] as String?,
      title: json['title'] as String,
      caption: json['caption'] as String,
      description: json['description'] as String,
      timeToComplete: json['timeToComplete'] as int,
      tags: List<String>.from(json['tags'] ?? []),
      targetAudience: List<String>.from(json['targetAudience'] ?? []),
      questions: (json['questions'] as List?)
          ?.map((q) => SurveyQuestion.fromJson(q as Map<String, dynamic>))
          .toList() ?? [],
      sections: (json['sections'] as List?)
          ?.map((s) => SurveySection.fromJson(s as Map<String, dynamic>))
          .toList() ?? [],
      isDraft: json['isDraft'] as bool? ?? true,
    );
  }

  Survey toSurvey(String creatorId) {
    // Convert SurveyQuestion list to Question list
    final surveyQuestions = questions.map((q) => Question(
          questionId: q.id,
          text: q.text,
          type: q.type,
          required: q.required,
          options: q.options.isNotEmpty ? q.options : null,
        )).toList();

    // Join target audience array into a string
    final audienceString = targetAudience.join(', ');

    return Survey(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      timeToComplete: timeToComplete,
      tags: tags,
      targetAudience: audienceString,
      creator: creatorId,
      createdAt: DateTime.now(),
      status: true, // New surveys are active by default
      questions: surveyQuestions,
    );
  }

  SurveyCreation copyWith({
    String? id,
    String? title,
    String? caption,
    String? description,
    int? timeToComplete,
    List<String>? tags,
    List<String>? targetAudience,
    List<SurveyQuestion>? questions,
    List<SurveySection>? sections,
    bool? isDraft,
  }) {
    return SurveyCreation(
      id: id ?? this.id,
      title: title ?? this.title,
      caption: caption ?? this.caption,
      description: description ?? this.description,
      timeToComplete: timeToComplete ?? this.timeToComplete,
      tags: tags ?? this.tags,
      targetAudience: targetAudience ?? this.targetAudience,
      questions: questions ?? this.questions,
      sections: sections ?? this.sections,
      isDraft: isDraft ?? this.isDraft,
    );
  }
}

class SurveyQuestion {
  String id;
  String text;
  QuestionType type;
  bool required;
  List<String> options;
  String? imageUrl;
  String? videoUrl;
  int order;
  String sectionId;

  SurveyQuestion({
    required this.id,
    this.text = '',
    required this.type,
    this.required = false,
    List<String>? options,
    this.imageUrl,
    this.videoUrl,
    required this.order,
    required this.sectionId,
  }) : options = options ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type.toJson(),
      'required': required,
      'options': options,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'order': order,
      'sectionId': sectionId,
    };
  }

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) {
    return SurveyQuestion(
      id: json['id'] as String,
      text: json['text'] as String,
      type: QuestionTypeExtension.fromJson(json['type'] as String),
      required: json['required'] as bool,
      options: List<String>.from(json['options'] ?? []),
      imageUrl: json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      order: json['order'] as int,
      sectionId: json['sectionId'] as String,
    );
  }

  SurveyQuestion copyWith({
    String? id,
    String? text,
    QuestionType? type,
    bool? required,
    List<String>? options,
    String? imageUrl,
    String? videoUrl,
    int? order,
    String? sectionId,
  }) {
    return SurveyQuestion(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      required: required ?? this.required,
      options: options ?? this.options,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      order: order ?? this.order,
      sectionId: sectionId ?? this.sectionId,
    );
  }
}

class SurveySection {
  String id;
  String title;
  String description;
  int order;

  SurveySection({
    required this.id,
    this.title = '',
    this.description = '',
    required this.order,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'order': order,
    };
  }

  factory SurveySection.fromJson(Map<String, dynamic> json) {
    return SurveySection(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      order: json['order'] as int,
    );
  }

  SurveySection copyWith({
    String? id,
    String? title,
    String? description,
    int? order,
  }) {
    return SurveySection(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      order: order ?? this.order,
    );
  }
}