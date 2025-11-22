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

  /// Convert to backend format for mobile endpoint
  /// POST /api/survey/post/send/questionnaire/mobile
  /// Returns JSON in camelCase format matching FLUTTER_SURVEY_JSON_FORMAT.md
  Map<String, dynamic> toBackendJson() {
    return {
      'caption': caption.isEmpty ? title : caption,
      'title': title,
      'description': description.isEmpty ? caption : description,
      'timeToComplete': '$timeToComplete-${timeToComplete + 5} min',
      'tags': tags,
      'targetAudience': targetAudience,
      'sections': sections.map((s) => {
        'id': s.id,
        'title': s.title,
        'description': s.description,
        'order': s.order,
      }).toList(),
      'data': questions.map((q) => {
        'questionId': q.id,
        'title': q.text, // Backend expects 'title' not 'text'
        'type': q.type.toBackendString(),
        'required': q.required,
        'options': q.options,
        'imageUrl': q.imageUrl,
        'imageKey': q.imageKey, // "image_{questionId}" - tells backend which FormData field has this question's image
        'videoUrl': q.videoUrl,
        'order': q.order,
        'sectionId': q.sectionId.isEmpty ? 'default' : q.sectionId,
        'minChoice': q.minChoice,
        'maxChoice': q.maxChoice,
        'maxRating': q.maxRating,
      }).toList(),
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
  int? minChoice;
  int? maxChoice;
  int? maxRating;
  String? imageUrl;
  String? videoUrl;
  int order;
  String sectionId;
  
  /// Get the FormData key for this question's image
  /// Returns "image_{questionId}" for backend to identify which question the image belongs to
  String get imageKey => 'image_$id';

  SurveyQuestion({
    required this.id,
    this.text = '',
    required this.type,
    this.required = false,
    List<String>? options,
    this.minChoice,
    this.maxChoice,
    this.maxRating,
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
      'minChoice': minChoice,
      'maxChoice': maxChoice,
      'maxRating': maxRating,
      'imageUrl': imageUrl,
      'imageKey': imageKey, // "image_{questionId}"
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
      minChoice: json['minChoice'] as int?,
      maxChoice: json['maxChoice'] as int?,
      maxRating: json['maxRating'] as int?,
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
    int? minChoice,
    int? maxChoice,
    int? maxRating,
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
      minChoice: minChoice ?? this.minChoice,
      maxChoice: maxChoice ?? this.maxChoice,
      maxRating: maxRating ?? this.maxRating,
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