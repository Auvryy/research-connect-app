// Example: Complete Survey Submission Flow
// This demonstrates how a survey response is collected and submitted

import 'package:inquira/models/survey_response.dart';
import 'package:inquira/models/question_type.dart';
import 'package:inquira/data/api/survey_api.dart';

void main() async {
  // Example survey data from backend
  final surveyData = {
    'pk_survey_id': 2,
    'survey_title': 'Customer Satisfaction Survey 2024',
    'survey_content': 'Help us improve our services',
    'survey_section': [
      {
        'section_id': 'section-demographics',
        'section_title': 'About You',
        'questions': [
          {
            'pk_question_id': 1,
            'question_id': '1section-demographics',
            'question_text': 'What is your name?',
            'question_type': 'shortText',
            'question_required': true,
          },
          {
            'pk_question_id': 2,
            'question_id': '2section-demographics',
            'question_text': 'Your email address?',
            'question_type': 'shortText',
            'question_required': true,
          },
          {
            'pk_question_id': 4,
            'question_id': '4section-demographics',
            'question_text': 'Rate your satisfaction (1-5)',
            'question_type': 'ratingScale',
            'question_required': true,
          },
        ],
      },
      {
        'section_id': 'section-usage',
        'section_title': 'Platform Usage',
        'questions': [
          {
            'pk_question_id': 5,
            'question_id': '5section-usage',
            'question_text': 'How often do you use our service?',
            'question_type': 'multipleChoice',
            'question_choices': ['Daily', 'Weekly', 'Monthly'],
            'question_required': true,
          },
          {
            'pk_question_id': 6,
            'question_id': '6section-usage',
            'question_text': 'Which features do you use? (Select all)',
            'question_type': 'checkboxes',
            'question_choices': ['Feature A', 'Feature B', 'Feature C'],
            'question_required': false,
          },
        ],
      },
    ],
  };

  // STEP 1: Create SurveyResponse
  final response = SurveyResponse(
    surveyId: surveyData['pk_survey_id'].toString(),
    respondentId: 'user-123', // From authentication
    startedAt: DateTime.now(),
  );

  // STEP 2: User answers questions (collected from UI)
  
  // Section 1: Demographics
  response.setAnswer(
    '1section-demographics',
    QuestionAnswer.text('John Doe'),
  );

  response.setAnswer(
    '2section-demographics',
    QuestionAnswer.text('john@email.com'),
  );

  response.setAnswer(
    '4section-demographics',
    QuestionAnswer.rating(5),
  );

  // Section 2: Usage
  response.setAnswer(
    '5section-usage',
    QuestionAnswer.singleChoice(
      QuestionType.multipleChoice,
      'Daily',
    ),
  );

  response.setAnswer(
    '6section-usage',
    QuestionAnswer.multipleChoice(['Feature A', 'Feature C']),
  );

  // STEP 3: Prepare submission data
  final submissionData = response.toSubmissionJson(
    surveyTitle: surveyData['survey_title'],
    surveyDescription: surveyData['survey_content'],
  );

  print('=== Submission Data ===');
  print(submissionData);
  /* Output:
  {
    "surveyTitle": "Customer Satisfaction Survey 2024",
    "surveyDescription": "Help us improve our services",
    "submittedAt": "2025-11-21T10:30:00.000Z",
    "responses": {
      "section-demographics": {
        "1section-demographics": "John Doe",
        "2section-demographics": "john@email.com",
        "4section-demographics": 5
      },
      "section-usage": {
        "5section-usage": "Daily",
        "6section-usage": ["Feature A", "Feature C"]
      }
    }
  }
  */

  // STEP 4: Submit to backend
  final surveyId = surveyData['pk_survey_id'] as int;
  final result = await SurveyAPI.submitSurveyResponse(surveyId, submissionData);

  print('\n=== Backend Response ===');
  print(result);
  
  // STEP 5: Handle result
  if (result['ok'] == true) {
    print('✅ Survey submitted successfully!');
    print('Message: ${result['message']}');
  } else if (result['alreadyAnswered'] == true) {
    print('⚠️ Already answered this survey');
    print('Message: ${result['message']}');
  } else {
    print('❌ Submission failed');
    print('Error: ${result['message']}');
  }
}

// Example: Different Answer Types
void demonstrateAnswerTypes() {
  final response = SurveyResponse(
    surveyId: '1',
    respondentId: 'user-123',
    startedAt: DateTime.now(),
  );

  // Text Response (Short Text)
  response.setAnswer(
    '1section-info',
    QuestionAnswer.text('John Doe'),
  );

  // Long Text Response
  response.setAnswer(
    '2section-info',
    QuestionAnswer.longText('This is a detailed feedback about the product...'),
  );

  // Single Choice (Multiple Choice, Dropdown, Yes/No)
  response.setAnswer(
    '3section-info',
    QuestionAnswer.singleChoice(QuestionType.multipleChoice, 'option-2'),
  );

  response.setAnswer(
    '4section-info',
    QuestionAnswer.singleChoice(QuestionType.dropdown, 'option-5'),
  );

  response.setAnswer(
    '5section-info',
    QuestionAnswer.yesNo(true), // Converts to "Yes"
  );

  // Multiple Choice (Checkbox)
  response.setAnswer(
    '6section-info',
    QuestionAnswer.multipleChoice(['option-1', 'option-3', 'option-5']),
  );

  // Rating Scale
  response.setAnswer(
    '7section-info',
    QuestionAnswer.rating(4), // 1-5 scale
  );

  // Convert to backend format
  final data = response.toSubmissionJson();
  
  print('All answer types:');
  print(data['responses']);
  /* Output:
  {
    "section-info": {
      "1section-info": "John Doe",
      "2section-info": "This is a detailed feedback...",
      "3section-info": "option-2",
      "4section-info": "option-5",
      "5section-info": "Yes",
      "6section-info": ["option-1", "option-3", "option-5"],
      "7section-info": 4
    }
  }
  */
}

// Example: Validation Before Submission
bool validateSurveyCompletion(
  SurveyResponse response,
  List<Map<String, dynamic>> questions,
) {
  for (var question in questions) {
    final required = question['question_required'] as bool? ?? false;
    final questionId = question['question_id'] as String;

    if (required && !response.hasAnswer(questionId)) {
      print('❌ Required question not answered: ${question['question_text']}');
      return false;
    }
  }

  print('✅ All required questions answered');
  return true;
}

// Example: Error Handling
Future<void> submitWithErrorHandling(
  int surveyId,
  SurveyResponse response,
  Map<String, dynamic> surveyInfo,
) async {
  try {
    // Prepare data
    final submissionData = response.toSubmissionJson(
      surveyTitle: surveyInfo['survey_title'],
      surveyDescription: surveyInfo['survey_content'],
    );

    // Submit
    final result = await SurveyAPI.submitSurveyResponse(surveyId, submissionData);

    // Handle different responses
    if (result['ok'] == true) {
      // Success
      print('✅ ${result['message']}');
    } else if (result['alreadyAnswered'] == true) {
      // Already answered (409)
      print('⚠️ ${result['message']}');
      print('You cannot submit multiple times');
    } else {
      // Other errors
      print('❌ ${result['message']}');
    }
  } catch (e) {
    // Network or unexpected errors
    print('💥 Error: $e');
    print('Please check your connection and try again');
  }
}
