class SurveyQuestionnaire {
  final int surveyId;
  final String title;
  final String description;
  final String approxTime;
  final List<String> tags;
  final List<String> targetAudience;
  final List<SurveySection> sections;

  SurveyQuestionnaire({
    required this.surveyId,
    required this.title,
    required this.description,
    required this.approxTime,
    required this.tags,
    required this.targetAudience,
    required this.sections,
  });

  factory SurveyQuestionnaire.fromJson(Map<String, dynamic> json) {
    return SurveyQuestionnaire(
      surveyId: json['pk_survey_id'],
      title: json['survey_title'],
      description: json['survey_content'],
      approxTime: json['survey_approx_time'],
      tags: List<String>.from(json['survey_tags'] ?? []),
      targetAudience: List<String>.from(json['survey_target_audience'] ?? []),
      sections: (json['survey_section'] as List)
          .map((s) => SurveySection.fromJson(s))
          .toList(),
    );
  }
}

class SurveySection {
  final int pkSectionId;
  final String sectionId;
  final String title;
  final String description;
  final List<SurveyQuestion> questions;

  SurveySection({
    required this.pkSectionId,
    required this.sectionId,
    required this.title,
    required this.description,
    required this.questions,
  });

  factory SurveySection.fromJson(Map<String, dynamic> json) {
    return SurveySection(
      pkSectionId: json['pk_section_id'],
      sectionId: json['section_id'],
      title: json['section_title'],
      description: json['section_description'] ?? '',
      questions: (json['questions'] as List)
          .map((q) => SurveyQuestion.fromJson(q))
          .toList(),
    );
  }
}

class SurveyQuestion {
  final int pkQuestionId;
  final String questionId;
  final int questionNumber;
  final String questionText;
  final String questionType;
  final bool required;
  final List<String> choices;
  final int minChoice;
  final int maxChoice;
  final int maxRating;
  final String? imageUrl;
  final String? videoUrl;

  SurveyQuestion({
    required this.pkQuestionId,
    required this.questionId,
    required this.questionNumber,
    required this.questionText,
    required this.questionType,
    required this.required,
    required this.choices,
    required this.minChoice,
    required this.maxChoice,
    this.maxRating = 5,
    this.imageUrl,
    this.videoUrl,
  });

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) {
    // Handle question_image which can be a Map object or String
    String? imageUrl;
    final imageData = json['question_image'];
    if (imageData != null) {
      if (imageData is Map) {
        imageUrl = imageData['img_url'] as String?;
      } else if (imageData is String) {
        imageUrl = imageData;
      }
    }
    
    // Safely parse maxRating - backend sends as int but handle string case too
    int maxRating = 5;
    final maxRatingValue = json['question_maxRating'];
    if (maxRatingValue != null) {
      if (maxRatingValue is int) {
        maxRating = maxRatingValue;
      } else if (maxRatingValue is String) {
        maxRating = int.tryParse(maxRatingValue) ?? 5;
      }
    }
    // Ensure maxRating is at least 1
    if (maxRating < 1) maxRating = 5;
    
    return SurveyQuestion(
      pkQuestionId: json['pk_question_id'] ?? 0,
      questionId: json['question_id'] ?? '',
      questionNumber: json['question_number'] ?? 0,
      questionText: json['question_text'] ?? '',
      questionType: json['question_type'] ?? 'shortText',
      required: json['question_required'] ?? false,
      choices: List<String>.from(json['question_choices'] ?? []),
      minChoice: json['question_minChoice'] ?? 1,
      maxChoice: json['question_maxChoice'] ?? 1,
      maxRating: maxRating,
      imageUrl: imageUrl,
      videoUrl: json['question_url'],
    );
  }
}
