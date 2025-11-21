# Survey Data Structure - Database-Organized Format

## 🎯 Overview

Your backend now uses a **nested structure with proper foreign key relationships** for database organization. This is better for Supabase and other databases because:

✅ **Sections** have unique IDs (`section_another_id`) that questions reference
✅ **Questions** have unique IDs (`question_another_id`) linked to their sections
✅ **Responses** are grouped by `section_another_id` for easy database queries
✅ **Normalization** allows efficient joins and queries in your database

---

## 📥 Backend Response Format (GET /questionnaire/<id>)

```json
{
  "message": {
    "id": 1,
    "title": "Customer Satisfaction Survey 2024",
    "content": "Help us improve our services",
    "approx_time": "15",
    "target_audience": "Students, Professionals",
    "tags": ["Technology", "Customer Service"],
    "section": [
      {
        "id": 1,
        "section_another_id": "section-demographics",
        "title": "About You",
        "description": "Tell us about yourself",
        "survey_id": 1,
        "questions": [
          {
            "id": 1,
            "question_another_id": "question-1763033604215",
            "q_number": 1,
            "question_text": "What is your name?",
            "q_type": "Text",
            "choices": [],
            "required": true,
            "minChoice": 1,
            "maxChoice": 1,
            "image": null,
            "url": null
          },
          {
            "id": 2,
            "question_another_id": "question-1763033665504",
            "q_number": 2,
            "question_text": "Your email address?",
            "q_type": "Email",
            "choices": [],
            "required": true,
            "minChoice": 1,
            "maxChoice": 1,
            "image": null,
            "url": null
          }
        ]
      },
      {
        "id": 2,
        "section_another_id": "section-usage",
        "title": "Platform Usage",
        "description": "How you use our platform",
        "survey_id": 1,
        "questions": [
          {
            "id": 3,
            "question_another_id": "question-1763033699092",
            "q_number": 1,
            "question_text": "How often do you use our service?",
            "q_type": "Single Choice",
            "choices": ["Daily", "Weekly", "Monthly"],
            "required": true,
            "minChoice": 1,
            "maxChoice": 1,
            "image": null,
            "url": null
          },
          {
            "id": 4,
            "question_another_id": "question-1763033699753",
            "q_number": 2,
            "question_text": "Which features do you use?",
            "q_type": "Multiple Choice",
            "choices": ["Feature A", "Feature B", "Feature C"],
            "required": false,
            "minChoice": 2,
            "maxChoice": 4,
            "image": null,
            "url": "https://www.youtube.com/watch?v=example"
          }
        ]
      }
    ]
  },
  "ok": true,
  "status": 200
}
```

---

## 📤 Survey Submission Format (POST /answer/questionnaire/<id>)

When user submits their answers, Flutter sends:

```json
{
  "surveyTitle": "Customer Satisfaction Survey 2024",
  "surveyDescription": "Help us improve our services",
  "submittedAt": "2025-11-21T10:30:00.000Z",
  "responses": {
    "section-demographics": {
      "question-1763033604215": "John Doe",
      "question-1763033665504": "john@email.com"
    },
    "section-usage": {
      "question-1763033699092": "Daily",
      "question-1763033699753": ["Feature A", "Feature C"]
    }
  }
}
```

### Key Differences from Before:

| Aspect | Old Format | New Format (Database-Organized) |
|--------|-----------|--------------------------------|
| Section Key | `"section-demographics"` | `"section-demographics"` (from `section_another_id`) |
| Question Key | `"1section-demographics"` | `"question-1763033604215"` (from `question_another_id`) |
| Structure | Manual parsing needed | Direct database FK references |
| Database Queries | Complex string manipulation | Simple JOIN on `another_id` fields |

---

## 🗄️ Database Structure

### Table: `svy_section`
```sql
id (PK)  | another_id              | title       | survey_id (FK)
---------|-------------------------|-------------|----------------
1        | section-demographics    | About You   | 1
2        | section-usage           | Usage       | 1
```

### Table: `svy_questions`
```sql
id (PK)  | another_id              | question_text        | survey_id (FK to section)
---------|-------------------------|----------------------|---------------------------
1        | question-1763033604215  | What is your name?   | 1
2        | question-1763033665504  | Your email?          | 1
3        | question-1763033699092  | How often?           | 2
```

### Table: `svy_answers`
```sql
id (PK)  | question_id (FK) | user_id (FK) | answer_text
---------|------------------|--------------|------------------
1        | 1                | 123          | "John Doe"
2        | 2                | 123          | "john@email.com"
3        | 3                | 123          | "Daily"
```

---

## 🔄 Flutter Implementation

### 1. Parsing Backend Response

```dart
// In take_survey_page.dart
Future<void> _loadSurveyData() async {
  final data = await SurveyAPI.getSurveyQuestionnaire(widget.postId);
  
  // Backend returns: { message: { section: [...] } }
  _surveyInfo = data['message'];
  final sections = _surveyInfo?['section'] as List<dynamic>? ?? [];
  
  // Group by section_another_id
  for (var section in sections) {
    final sectionAnotherId = section['section_another_id']; // "section-demographics"
    final questions = section['questions'];
    
    _sectionQuestions[sectionAnotherId] = questions;
  }
}
```

### 2. Building Question UI

```dart
Widget _buildQuestionCard(Map<String, dynamic> question) {
  // Use question_another_id as unique identifier
  final questionId = question['question_another_id']; // "question-1763033604215"
  final questionText = question['question_text'];
  final questionType = _parseQuestionType(question['q_type']);
  final choices = question['choices']; // For dropdown, multiple choice, etc.
  
  // Save answer using question_another_id
  _response.setAnswer(questionId, QuestionAnswer.text(value));
}
```

### 3. Submitting Response

```dart
Future<void> _submitSurvey() async {
  final sections = _surveyInfo?['section']; // Pass sections for proper grouping
  
  // Convert to backend format
  final submissionData = _response.toSubmissionJson(
    surveyTitle: _surveyInfo?['title'],
    surveyDescription: _surveyInfo?['content'],
    sections: sections, // Used to map question_another_id → section_another_id
  );
  
  // Submit to backend
  final result = await SurveyAPI.submitSurveyResponse(
    _surveyInfo?['id'], 
    submissionData
  );
}
```

### 4. Response Grouping Logic

```dart
// In survey_response.dart - toSubmissionJson()
Map<String, dynamic> toSubmissionJson({
  List<Map<String, dynamic>>? sections,
}) {
  final groupedResponses = {};
  
  for (var entry in answers.entries) {
    final questionAnotherId = entry.key; // "question-1763033604215"
    final answer = entry.value;
    
    // Find which section this question belongs to
    String? sectionAnotherId;
    for (var section in sections!) {
      final questions = section['questions'];
      for (var q in questions) {
        if (q['question_another_id'] == questionAnotherId) {
          sectionAnotherId = section['section_another_id'];
          break;
        }
      }
    }
    
    // Group by section_another_id
    groupedResponses[sectionAnotherId] ??= {};
    groupedResponses[sectionAnotherId][questionAnotherId] = answer.getAnswerValue();
  }
  
  return {
    'responses': groupedResponses
  };
}
```

---

## 🎨 Question Type Mapping

| Backend `q_type` | Flutter QuestionType | Example |
|------------------|----------------------|---------|
| `"Text"` | `textResponse` | Short answer |
| `"Essay"` | `longTextResponse` | Long text |
| `"Single Choice"` | `multipleChoice` | Radio buttons |
| `"Multiple Choice"` | `checkbox` | Checkboxes |
| `"Dropdown"` | `dropdown` | Select menu |
| `"Rating"` | `ratingScale` | 1-5 stars |
| `"Date"` | `textResponse` | Date picker |
| `"Email"` | `textResponse` | Email input |

---

## ✅ Benefits of This Structure

### 1. **Database Efficiency**
```sql
-- Easy query for all answers in a section
SELECT a.* FROM svy_answers a
JOIN svy_questions q ON a.question_id = q.id
JOIN svy_section s ON q.survey_id = s.id
WHERE s.another_id = 'section-demographics';
```

### 2. **Scalability**
- Add new questions to sections without breaking existing queries
- Move questions between sections by updating FK
- Archive/delete sections with CASCADE

### 3. **Frontend Flexibility**
- Direct mapping between UI state and database IDs
- No string parsing needed
- Type-safe with proper foreign keys

### 4. **Maintainability**
```dart
// Clear relationship
question['question_another_id'] // Unique question ID
question['survey_id']            // FK to section.id
section['section_another_id']    // Unique section ID
section['survey_id']             // FK to survey.id
```

---

## 🧪 Testing Example

```dart
void main() async {
  // 1. Fetch survey
  final data = await SurveyAPI.getSurveyQuestionnaire(1);
  print(data['message']['section'][0]['section_another_id']);
  // Output: "section-demographics"
  
  // 2. Answer questions
  final response = SurveyResponse(...);
  response.setAnswer(
    'question-1763033604215', 
    QuestionAnswer.text('John Doe')
  );
  
  // 3. Submit
  final submission = response.toSubmissionJson(
    sections: data['message']['section']
  );
  print(submission);
  /* Output:
  {
    "responses": {
      "section-demographics": {
        "question-1763033604215": "John Doe"
      }
    }
  }
  */
}
```

---

## 📊 Comparison: Before vs After

### Before (String-based)
```json
{
  "responses": {
    "section-demographics": {
      "1section-demographics": "John Doe",
      "2section-demographics": "john@email.com"
    }
  }
}
```
❌ Question number might change
❌ Section name embedded in question ID
❌ Hard to query specific questions

### After (Database FK-based)
```json
{
  "responses": {
    "section-demographics": {
      "question-1763033604215": "John Doe",
      "question-1763033665504": "john@email.com"
    }
  }
}
```
✅ Unique, immutable IDs
✅ Clear FK relationships
✅ Direct database mapping
✅ Easy to query and join

---

## 🚀 Your Implementation is Complete!

**What's updated:**
1. ✅ `survey_response.dart` - Uses `section_another_id` and `question_another_id`
2. ✅ `take_survey_page.dart` - Parses nested `section[questions]` structure
3. ✅ `question_type.dart` - Handles all backend `q_type` values
4. ✅ Submission format matches backend expectations perfectly

**Database-ready features:**
- Proper foreign key relationships
- Efficient queries with JOINs
- Scalable structure for Supabase
- Type-safe IDs throughout the flow

Hot restart your app and test with your backend! 🎉
