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

  /// Convert to submission format for /answer/questionnaire endpoint
  /// Backend expects responses organized by section with question_another_id as keys
  /// Format matches the nested structure: section[questions[{question_another_id, answer}]]
  Map<String, dynamic> toSubmissionJson({
    String? surveyTitle, 
    String? surveyDescription,
    List<Map<String, dynamic>>? sections, // Pass section data from backend
  }) {
    final Map<String, dynamic> result = {};
    
    // Add metadata if provided (optional based on backend requirements)
    if (surveyTitle != null) {
      result['surveyTitle'] = surveyTitle;
    }
    if (surveyDescription != null) {
      result['surveyDescription'] = surveyDescription;
    }
    result['submittedAt'] = (completedAt ?? DateTime.now()).toIso8601String();
    
    // Group responses by section_another_id for proper database foreign key relationships
    final Map<String, Map<String, dynamic>> groupedResponses = {};
    
    for (var entry in answers.entries) {
      final questionId = entry.key; // This is question_another_id from backend (e.g., "question-1763033604215")
      final answer = entry.value;
      
      // Find which section this question belongs to using the sections data
      String? sectionAnotherId;
      if (sections != null) {
        for (var section in sections) {
          final questions = section['questions'] as List<dynamic>? ?? [];
          for (var question in questions) {
            if (question['question_another_id'] == questionId) {
              sectionAnotherId = section['section_another_id'] as String?;
              break;
            }
          }
          if (sectionAnotherId != null) break;
        }
      }
      
      // Fallback: extract section ID from old format if no section data provided
      if (sectionAnotherId == null) {
        if (questionId.contains('section-')) {
          // Old format: "1section-demographics" -> "section-demographics"
          final parts = questionId.split('section-');
          sectionAnotherId = parts.length > 1 ? 'section-${parts[1]}' : 'default';
        } else {
          // New format: just use 'default' or try to infer
          sectionAnotherId = 'default';
        }
      }
      
      // Initialize section if not exists
      if (!groupedResponses.containsKey(sectionAnotherId)) {
        groupedResponses[sectionAnotherId] = {};
      }
      
      // Add answer value using question_another_id as key
      final answerValue = answer.getAnswerValue();
      if (answerValue != null) {
        groupedResponses[sectionAnotherId]![questionId] = answerValue;
      }
    }
    
    // Add responses object grouped by section_another_id
    if (groupedResponses.isNotEmpty) {
      result['responses'] = groupedResponses;
    }
    
    return result;
  }

  /// Simple flat format for backend (just question numbers and answers)
  /// Format: { "1": "answer", "2": ["opt1", "opt2"], "3": 5 }
  Map<String, dynamic> toFlatSubmissionJson() {
    final Map<String, dynamic> result = {};
    
    for (var entry in answers.entries) {
      final questionId = entry.key;
      final answer = entry.value;
      
      // Extract question number from question ID
      final questionNumber = questionId.split('section-').first;
      
      final answerValue = answer.getAnswerValue();
      if (answerValue != null) {
        result[questionNumber] = answerValue;
      }
    }
    
    return result;
  }
}

/// Model for storing answer to a single question
class QuestionAnswer {
  final QuestionType questionType;
  
  // Different answer types based on question type
  String? textAnswer; // for textResponse, longTextResponse
  String? radioButtonAnswer; // for checkBox, dropdown, yesNo
  List<String>? checkBoxAnswers; // for checkbox
  int? ratingAnswer; // for ratingScale

  QuestionAnswer({
    required this.questionType,
    this.textAnswer,
    this.radioButtonAnswer,
    this.checkBoxAnswers,
    this.ratingAnswer,
  });

  /// Check if this answer has a value
  bool hasValue() {
    switch (questionType) {
      case QuestionType.shortText:
      case QuestionType.longText:
      case QuestionType.email:
      case QuestionType.date:
        return textAnswer != null && textAnswer!.isNotEmpty;
      case QuestionType.radioButton:
      case QuestionType.dropdown:
        return radioButtonAnswer != null && radioButtonAnswer!.isNotEmpty;
      case QuestionType.checkBox:
        return checkBoxAnswers != null && checkBoxAnswers!.isNotEmpty;
      case QuestionType.rating:
        return ratingAnswer != null;
    }
  }

  /// Get answer value as string for display
  String getDisplayValue() {
    switch (questionType) {
      case QuestionType.shortText:
      case QuestionType.longText:
      case QuestionType.email:
      case QuestionType.date:
        return textAnswer ?? '';
      case QuestionType.radioButton:
      case QuestionType.dropdown:
        return radioButtonAnswer ?? '';
      case QuestionType.checkBox:
        return checkBoxAnswers?.join(', ') ?? '';
      case QuestionType.rating:
        return ratingAnswer?.toString() ?? '';
    }
  }

  /// Get raw answer value for backend submission
  dynamic getAnswerValue() {
    switch (questionType) {
      case QuestionType.shortText:
      case QuestionType.longText:
      case QuestionType.email:
      case QuestionType.date:
        return textAnswer;
      case QuestionType.radioButton:
      case QuestionType.dropdown:
        return radioButtonAnswer;
      case QuestionType.checkBox:
        return checkBoxAnswers;
      case QuestionType.rating:
        return ratingAnswer;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'questionType': questionType.toJson(),
      'textAnswer': textAnswer,
      'radioButtonAnswer': radioButtonAnswer,
      'checkBoxAnswers': checkBoxAnswers,
      'ratingAnswer': ratingAnswer,
    };
  }

  factory QuestionAnswer.fromJson(Map<String, dynamic> json) {
    return QuestionAnswer(
      questionType: QuestionTypeExtension.fromJson(json['questionType'] as String),
      textAnswer: json['textAnswer'] as String?,
      radioButtonAnswer: json['radioButtonAnswer'] as String?,
      checkBoxAnswers: json['checkBoxAnswers'] != null
          ? List<String>.from(json['checkBoxAnswers'])
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
      case QuestionType.shortText:
      case QuestionType.longText:
      case QuestionType.email:
      case QuestionType.date:
        json['answer'] = textAnswer;
        break;
      case QuestionType.radioButton:
      case QuestionType.dropdown:
        json['answer'] = radioButtonAnswer;
        break;
      case QuestionType.checkBox:
        json['answer'] = checkBoxAnswers;
        break;
      case QuestionType.rating:
        json['answer'] = ratingAnswer;
        break;
    }

    return json;
  }

  /// Factory constructors for different question types
  factory QuestionAnswer.text(String answer) {
    return QuestionAnswer(
      questionType: QuestionType.shortText,
      textAnswer: answer,
    );
  }

  factory QuestionAnswer.longText(String answer) {
    return QuestionAnswer(
      questionType: QuestionType.longText,
      textAnswer: answer,
    );
  }

  factory QuestionAnswer.radioButton(QuestionType type, String answer) {
    return QuestionAnswer(
      questionType: type,
      radioButtonAnswer: answer,
    );
  }

  factory QuestionAnswer.checkBox(List<String> answers) {
    return QuestionAnswer(
      questionType: QuestionType.checkBox,
      checkBoxAnswers: answers,
    );
  }

  factory QuestionAnswer.rating(int rating) {
    return QuestionAnswer(
      questionType: QuestionType.rating,
      ratingAnswer: rating,
    );
  }

  factory QuestionAnswer.email(String answer) {
    return QuestionAnswer(
      questionType: QuestionType.email,
      textAnswer: answer,
    );
  }

  factory QuestionAnswer.date(String answer) {
    return QuestionAnswer(
      questionType: QuestionType.date,
      textAnswer: answer,
    );
  }
}
