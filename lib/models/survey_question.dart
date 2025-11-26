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
    this.imageUrl,
    this.videoUrl,
  });

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) {
    return SurveyQuestion(
      pkQuestionId: json['pk_question_id'],
      questionId: json['question_id'],
      questionNumber: json['question_number'],
      questionText: json['question_text'],
      questionType: json['question_type'],
      required: json['question_required'] ?? false,
      choices: List<String>.from(json['question_choices'] ?? []),
      minChoice: json['question_minChoice'] ?? 1,
      maxChoice: json['question_maxChoice'] ?? 1,
      imageUrl: json['question_image'],
      videoUrl: json['question_url'],
    );
  }
}
