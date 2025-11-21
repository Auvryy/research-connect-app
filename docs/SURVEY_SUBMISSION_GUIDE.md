# Survey Submission Implementation Guide

## Overview
This guide explains how survey responses are collected, formatted, and submitted to the backend.

## Backend Requirements

### Endpoint
```
POST /api/survey/answer/questionnaire/<survey_id>
```

### Expected JSON Format
The backend expects responses in this structure:

```json
{
  "surveyTitle": "Customer Satisfaction Survey 2024",
  "surveyDescription": "Help us improve our services...",
  "submittedAt": "2025-11-15T18:40:14.927Z",
  "responses": {
    "section-demographics": {
      "1section-demographics": "John Doe",
      "2section-demographics": "john@email.com",
      "3section-demographics": "2025-11-16",
      "4section-demographics": 5
    },
    "section-usage": {
      "5section-usage": "option-2",
      "6section-usage": ["option-9", "option-10", "option-11"],
      "7section-usage": "option-17"
    },
    "section-preferences": {
      "8section-preferences": "Custom text answer",
      "9section-preferences": "option-18"
    }
  }
}
```

## Flutter Implementation

### 1. Data Model (`survey_response.dart`)

#### Key Methods

**`toSubmissionJson()`**
Formats responses for backend submission with optional metadata:
```dart
final submissionData = response.toSubmissionJson(
  surveyTitle: "Survey Title",
  surveyDescription: "Survey Description",
);
```

Output structure:
- Groups responses by section ID
- Uses question IDs as keys (e.g., "1section-demographics")
- Includes metadata: surveyTitle, surveyDescription, submittedAt
- Returns proper data types (String, List<String>, int) based on question type

**`toFlatSubmissionJson()`**
Alternative simple format (question number only):
```dart
// Returns: { "1": "answer", "2": ["opt1", "opt2"], "3": 5 }
final flatData = response.toFlatSubmissionJson();
```

#### Answer Value Types

| Question Type | Dart Type | Example Value |
|--------------|-----------|---------------|
| Short Text | `String` | `"John Doe"` |
| Long Text | `String` | `"Detailed feedback..."` |
| Multiple Choice | `String` | `"option-2"` |
| Checkbox | `List<String>` | `["option-1", "option-3"]` |
| Dropdown | `String` | `"option-5"` |
| Rating Scale | `int` | `5` |
| Yes/No | `String` | `"yes"` or `"no"` |

### 2. API Service (`survey_api.dart`)

#### `submitSurveyResponse()`
```dart
static Future<Map<String, dynamic>> submitSurveyResponse(
  int surveyId,
  Map<String, dynamic> responseData,
) async
```

**Parameters:**
- `surveyId`: Survey ID from `pk_survey_id`
- `responseData`: Formatted JSON from `toSubmissionJson()`

**Returns:**
```dart
{
  'ok': true,
  'message': 'You have successfully answered this survey',
  'data': { ... }
}
```

**Error Handling:**
- `409 Conflict`: User already answered survey (`alreadyAnswered: true`)
- `401 Unauthorized`: User not logged in
- `404 Not Found`: Survey doesn't exist
- `500 Server Error`: Database error

#### `checkIfAnswered()`
```dart
static Future<Map<String, dynamic>> checkIfAnswered(int surveyId) async
```

Check if user has already answered before loading survey.

### 3. UI Implementation (`take_survey_page.dart`)

#### Submission Flow

```dart
Future<void> _submitSurvey() async {
  // 1. Show confirmation dialog
  final confirmed = await showDialog<bool>(...);
  if (confirmed != true) return;

  // 2. Mark response as complete
  _response.complete();

  // 3. Format data for backend
  final submissionData = _response.toSubmissionJson(
    surveyTitle: _surveyInfo?['survey_title'],
    surveyDescription: _surveyInfo?['survey_content'],
  );

  // 4. Submit to backend
  final surveyId = _surveyInfo?['pk_survey_id'];
  final result = await SurveyAPI.submitSurveyResponse(surveyId, submissionData);

  // 5. Handle response
  if (result['ok'] == true) {
    // Success - show message and navigate back
    ScaffoldMessenger.of(context).showSnackBar(...);
    Navigator.pop(context, true);
  } else if (result['alreadyAnswered'] == true) {
    // Already answered - inform user
    ScaffoldMessenger.of(context).showSnackBar(...);
  } else {
    // Error - show error message
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
}
```

## Data Flow Example

### User answers questions:

```dart
// Question 1: Text input
_response.setAnswer(
  "1section-demographics",
  QuestionAnswer.text("John Doe")
);

// Question 2: Multiple choice
_response.setAnswer(
  "5section-usage",
  QuestionAnswer.singleChoice(QuestionType.multipleChoice, "option-2")
);

// Question 3: Checkboxes
_response.setAnswer(
  "6section-usage",
  QuestionAnswer.multipleChoice(["option-9", "option-10"])
);

// Question 4: Rating
_response.setAnswer(
  "4section-demographics",
  QuestionAnswer.rating(5)
);
```

### Submitted JSON:

```json
{
  "surveyTitle": "Customer Survey",
  "surveyDescription": "Your feedback matters",
  "submittedAt": "2025-11-21T10:30:00.000Z",
  "responses": {
    "section-demographics": {
      "1section-demographics": "John Doe",
      "4section-demographics": 5
    },
    "section-usage": {
      "5section-usage": "option-2",
      "6section-usage": ["option-9", "option-10"]
    }
  }
}
```

## Backend Processing

The backend endpoint `/answer/questionnaire/<id>` expects:

1. **JWT Authentication**: User must be logged in
2. **Survey ID**: Valid survey from database
3. **Response Data**: JSON with question answers
4. **Duplicate Check**: Prevents multiple submissions

### Backend Logic (from `route_post_survey.py`)

```python
@survey_posting.route("/answer/questionnaire/<int:id>", methods=['POST'])
@jwt_required()
def answer_questionnaire(id):
    data = request.get_json()
    user_id = get_jwt_identity()
    
    # Check if already answered
    if user_survey_exists:
        return jsonify_template_user(409, False, "You already answered this survey.")
    
    # Save answers
    for question in survey.questions:
        answer = Answers(
            answer_text=data.get(f"{question.question_number}"),
            user=user
        )
        question.answers.append(answer)
    
    # Mark as answered
    user_survey_answered = RootUser_Survey(user=user, survey=survey)
    db.add(user_survey_answered)
    
    return jsonify_template_user(200, True, "Successfully answered")
```

## Testing

### Test Submission

```dart
// Create test response
final testResponse = SurveyResponse(
  surveyId: "1",
  respondentId: "user-123",
  startedAt: DateTime.now(),
);

// Add test answers
testResponse.setAnswer("1section-test", QuestionAnswer.text("Test answer"));
testResponse.setAnswer("2section-test", QuestionAnswer.rating(4));

// Submit
final result = await SurveyAPI.submitSurveyResponse(1, 
  testResponse.toSubmissionJson(
    surveyTitle: "Test Survey",
    surveyDescription: "Testing submission"
  )
);

print('Submission result: $result');
```

## Error Scenarios

| Error | Status Code | Message | Action |
|-------|-------------|---------|--------|
| Already answered | 409 | "You already answered this survey" | Show info, navigate back |
| Not logged in | 401 | "You need to log in" | Redirect to login |
| Survey not found | 404 | "No such post like that" | Show error |
| Validation error | 422 | Validation messages | Show specific errors |
| Network error | N/A | "Network error" | Show retry option |

## Optimization Features

✅ **Efficient grouping**: Responses grouped by section for better organization
✅ **Type safety**: Proper data types (String, List, int) based on question type
✅ **Null handling**: Skips unanswered questions
✅ **Duplicate prevention**: Backend checks if user already answered
✅ **Validation**: Required questions checked before submission
✅ **Error handling**: Comprehensive error messages for all scenarios

## Future Enhancements

- [ ] Offline storage (save draft responses)
- [ ] Auto-save progress
- [ ] Resume incomplete surveys
- [ ] Partial submission for long surveys
- [ ] Attachment support (images, files)
- [ ] Rich text formatting for long text answers
