# Flutter Survey JSON Format Guide

This document shows the exact JSON formats that the Flutter mobile app sends to the backend.

---

## 📤 1. Creating a Survey (User Creates New Survey)

**Endpoint:** `POST /api/survey/post/send/questionnaire/mobile`

**When:** User completes creating a survey and publishes it

**Authentication:** JWT token required (sent via HTTP-only cookies)

### JSON Structure:

```json
{
  "caption": "Help us improve our services by sharing your valuable feedback!",
  "title": "Customer Satisfaction Survey 2024",
  "description": "This comprehensive survey helps us understand your experience with our platform. Your honest feedback will directly influence our future improvements and new features. The survey covers various aspects including user experience, feature satisfaction, and suggestions for enhancement.",
  "timeToComplete": "10-15 min",
  "tags": [
    "Technology",
    "Customer Service",
    "Product Feedback",
    "User Experience"
  ],
  "targetAudience": [
    "business-students",
    "engineering-students",
    "professionals",
    "researchers"
  ],
  "sections": [
    {
      "id": "section-1763633422945",
      "title": "About You",
      "description": "Tell us a bit about yourself and your background",
      "order": 1
    },
    {
      "id": "section-1763633456454",
      "title": "Platform Usage",
      "description": "How you currently use our platform",
      "order": 2
    },
    {
      "id": "section-1763633498320",
      "title": "Feedback & Suggestions",
      "description": "Share your thoughts and suggestions for improvement",
      "order": 3
    }
  ],
  "data": [
    {
      "id": "question-1763633434439",
      "sectionId": "section-1763633422945",
      "title": "What is your name?",
      "type": "shortText",
      "order": 1,
      "required": true,
      "options": [],
      "imageUrl": null,
      "videoUrl": null
    },
    {
      "id": "question-1763633449518",
      "sectionId": "section-1763633422945",
      "title": "Your email address?",
      "type": "email",
      "order": 2,
      "required": true,
      "options": [],
      "imageUrl": null,
      "videoUrl": null
    },
    {
      "id": "question-1763633465823",
      "sectionId": "section-1763633422945",
      "title": "What is your date of birth?",
      "type": "date",
      "order": 3,
      "required": false,
      "options": [],
      "imageUrl": null,
      "videoUrl": null
    },
    {
      "id": "question-1763633482019",
      "sectionId": "section-1763633422945",
      "title": "Rate your overall experience",
      "type": "rating",
      "order": 4,
      "required": true,
      "options": [],
      "maxRating": 5,
      "imageUrl": "https://example.com/images/rating-icon.png",
      "videoUrl": null
    },
    {
      "id": "question-1763633699092",
      "sectionId": "section-1763633456454",
      "title": "How often do you use our service?",
      "type": "radioButton",
      "order": 5,
      "required": true,
      "options": [
        "Daily",
        "Weekly",
        "Monthly",
        "Rarely"
      ],
      "imageUrl": null,
      "videoUrl": null
    },
    {
      "id": "question-1763633699753",
      "sectionId": "section-1763633456454",
      "title": "Which features do you use? (Select all that apply)",
      "type": "checkBox",
      "order": 6,
      "required": false,
      "minChoice": 1,
      "maxChoice": 5,
      "options": [
        "Survey Creation",
        "Data Analytics",
        "Report Generation",
        "Team Collaboration",
        "API Integration"
      ],
      "imageUrl": null,
      "videoUrl": "https://www.youtube.com/watch?v=example123"
    },
    {
      "id": "question-1763633815415",
      "sectionId": "section-1763633456454",
      "title": "Select your preferred IDE",
      "type": "dropdown",
      "order": 7,
      "required": true,
      "options": [
        "VS Code",
        "IntelliJ IDEA",
        "PyCharm",
        "Sublime Text",
        "Atom"
      ],
      "imageUrl": null,
      "videoUrl": null
    },
    {
      "id": "question-1763633860818",
      "sectionId": "section-1763633498320",
      "title": "Describe your most challenging project",
      "type": "longText",
      "order": 8,
      "required": false,
      "options": [],
      "imageUrl": null,
      "videoUrl": null
    },
    {
      "id": "question-1763633910890",
      "sectionId": "section-1763633498320",
      "title": "Any additional comments or suggestions?",
      "type": "shortText",
      "order": 9,
      "required": false,
      "options": [],
      "imageUrl": null,
      "videoUrl": null
    }
  ]
}
```

### Field Descriptions:

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| **caption** | String | Yes | Short description for post feed | "Help us improve!" |
| **title** | String | Yes | Survey title | "Customer Survey 2024" |
| **description** | String | Yes | Full survey description | "This survey helps us..." |
| **timeToComplete** | String | Yes | Estimated completion time | "10-15 min" or "5-10 minutes" |
| **tags** | Array[String] | Yes | Survey categories/topics | `["Technology", "Health"]` |
| **targetAudience** | Array[String] | Yes | Target user groups | `["students", "professionals"]` |
| **sections** | Array[Object] | Yes | Survey sections (see below) | `[{id, title, description}]` |
| **data** | Array[Object] | Yes | All questions flat (see below) | `[{sectionId, title, type...}]` |
| **post_code** | String | Optional | Admin approval code | `"ABC123"` (if provided) |

### Section Object Structure:

```json
{
  "id": "section-1763633422945",
  "title": "Section Title",
  "description": "Section description text",
  "order": 1
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| **id** | String | Yes | Unique section ID: `section-{timestamp}` |
| **title** | String | Yes | Section title |
| **description** | String | Yes | Section description |
| **order** | Integer | Yes | Section display order (1, 2, 3...) |

### Question Object Structure:

```json
{
  "id": "question-1763633434439",
  "sectionId": "section-1763633422945",
  "title": "Question text here?",
  "type": "shortText",
  "order": 1,
  "required": true,
  "options": [],
  "minChoice": null,
  "maxChoice": null,
  "maxRating": null,
  "imageUrl": null,
  "videoUrl": null
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| **id** | String | Yes | Unique question ID: `question-{timestamp}` |
| **sectionId** | String | Yes | FK reference to section.id |
| **title** | String | Yes | Question text |
| **type** | String | Yes | Question type (see types below) |
| **order** | Integer | Yes | Global question number (1, 2, 3...) |
| **required** | Boolean | Yes | Is answer required? |
| **options** | Array[String] | Conditional | For choice types only (not for rating) |
| **minChoice** | Integer/null | Conditional | Min selections (checkBox only) |
| **maxChoice** | Integer/null | Conditional | Max selections (checkBox only) |
| **maxRating** | Integer/null | Conditional | Number of stars for rating (1-5, rating only) |
| **imageUrl** | String/null | Optional | Local file path to image (picked from device) |
| **videoUrl** | String/null | Optional | Video URL (YouTube, Vimeo, etc.) |

### Question Types:

**Backend expects these exact type strings:**

| Type Value | UI Element | Has Options? | Has minChoice/maxChoice? | Has maxRating? |
|-----------|------------|--------------|---------------------------|----------------|
| `"shortText"` | Short text input | No | No | No |
| `"longText"` | Long text area | No | No | No |
| `"email"` | Email input field | No | No | No |
| `"date"` | Date picker | No | No | No |
| `"rating"` | Star rating (1-5) | No | No | **Yes** (required) |
| `"radioButton"` | Radio buttons | Yes | No | No |
| `"checkBox"` | Checkboxes | Yes | **Yes** (required) | No |
| `"dropdown"` | Select dropdown | Yes | No | No |

**Important Notes:**
- For `checkBox` type: `minChoice` and `maxChoice` are **required**
  - `minChoice` must be ≥ 1
  - `maxChoice` must be ≤ number of options
  - For all other types: `minChoice` and `maxChoice` should be `null`
- For `rating` type: `maxRating` is **required** (1-5 stars)
  - User chooses how many stars their rating question has (1, 2, 3, 4, or 5 stars)
  - When answering, user selects one star from available stars
  - Response is integer (1 to maxRating value)
  - `rating` type does NOT use the `options` array
- **Media Attachments:**
  - Only ONE media item per question (either image OR video, not both)
  - **Image**: User picks from device gallery, stored as local file path
    - Shows image preview during survey creation and taking
  - **Video**: User enters URL (YouTube, Vimeo, etc.)
    - Shows clickable video link during survey creation and taking

---

## 📥 2. Answering a Survey (User Submits Response)

**Endpoint:** `POST /api/survey/answer/questionnaire/<survey_id>`

**When:** User completes answering a survey and submits their responses

**Authentication:** JWT token required (sent via HTTP-only cookies)

### JSON Structure:

```json
{
  "surveyTitle": "Customer Satisfaction Survey 2024",
  "surveyDescription": "This comprehensive survey helps us understand your experience with our platform.",
  "submittedAt": "2025-11-21T10:30:45.123Z",
  "responses": {
    "section-demographics": {
      "question-1763033604215": "John Doe",
      "question-1763033665504": "john.doe@email.com",
      "question-1763033719283": "1995-03-15",
      "question-1763033745812": 5
    },
    "section-usage": {
      "question-1763033699092": "Daily",
      "question-1763033699753": [
        "Survey Creation",
        "Data Analytics",
        "Report Generation"
      ],
      "question-1763033815415": "VS Code"
    },
    "section-feedback": {
      "question-1763033860818": "Working on a machine learning project that involved processing large datasets. The main challenge was optimizing the algorithm for better performance while maintaining accuracy. It took several iterations and extensive testing to achieve the desired results.",
      "question-1763033910890": "The platform is intuitive and powerful. Would love to see more integration options with third-party tools."
    }
  }
}
```

### Response Field Descriptions:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| **surveyTitle** | String | Optional | Survey title (metadata) |
| **surveyDescription** | String | Optional | Survey description (metadata) |
| **submittedAt** | String (ISO 8601) | Yes | Submission timestamp |
| **responses** | Object | Yes | Grouped by section_another_id |

### Responses Object Structure:

**Format:** `{ "section_another_id": { "question_another_id": answer_value } }`

```json
{
  "section-demographics": {
    "question-1763033604215": "Text answer",
    "question-1763033665504": "email@example.com",
    "question-1763033719283": "2025-11-21",
    "question-1763033745812": 4
  }
}
```

**Key Points:**
- Grouped by `section_another_id` (e.g., `"section-demographics"`)
- Each key inside is `question_another_id` (e.g., `"question-1763033604215"`)
- Values match the question type (see below)

### Answer Value Types:

| Question Type | Value Type | Example |
|--------------|------------|---------|
| **Text** | String | `"John Doe"` |
| **Essay** | String | `"Long detailed answer..."` |
| **Email** | String | `"user@email.com"` |
| **Date** | String (ISO date) | `"2025-11-21"` |
| **Rating** | Integer | `5` |
| **Single Choice** | String | `"Option A"` |
| **Multiple Choice** | Array[String] | `["Option 1", "Option 3"]` |
| **Dropdown** | String | `"Selected Option"` |

### Example with All Question Types:

```json
{
  "submittedAt": "2025-11-21T10:30:45.123Z",
  "responses": {
    "section-demographics": {
      "question-text-001": "John Doe",
      "question-essay-002": "This is a long text answer with multiple sentences and detailed information.",
      "question-email-003": "john@example.com",
      "question-date-004": "1995-03-15",
      "question-rating-005": 4
    },
    "section-preferences": {
      "question-single-001": "Option B",
      "question-multiple-002": ["Feature A", "Feature C", "Feature D"],
      "question-dropdown-003": "VS Code"
    }
  }
}
```

---

## 🔄 Complete User Flow Examples

### Example 1: Simple Feedback Survey

#### Creating the Survey:

```json
{
  "caption": "Quick feedback survey",
  "title": "Product Feedback",
  "description": "Help us improve our product",
  "timeToComplete": "5 min",
  "tags": ["Feedback", "Product"],
  "targetAudience": ["students"],
  "sections": [
    {
      "id": "section-001",
      "title": "Your Feedback",
      "description": "Tell us what you think",
      "order": 1
    }
  ],
  "data": [
    {
      "id": "question-001",
      "sectionId": "section-001",
      "title": "How satisfied are you?",
      "type": "rating",
      "order": 1,
      "required": true,
      "options": [],
      "minChoice": null,
      "maxChoice": null,
      "maxRating": 5,
      "imageUrl": null,
      "videoUrl": null
    },
    {
      "id": "question-002",
      "sectionId": "section-001",
      "title": "Any suggestions?",
      "type": "longText",
      "order": 2,
      "required": false,
      "options": [],
      "minChoice": null,
      "maxChoice": null,
      "imageUrl": null,
      "videoUrl": null
    }
  ]
}
```

#### User's Response:

```json
{
  "submittedAt": "2025-11-21T14:20:00.000Z",
  "responses": {
    "section-001": {
      "question-1763033860818": 5,
      "question-1763033910890": "Great product! Would love offline mode."
    }
  }
}
```

---

### Example 2: Multi-Section Survey

#### Creating the Survey:

```json
{
  "caption": "Academic research survey",
  "title": "Student Learning Preferences Survey",
  "description": "Understanding how students learn best",
  "timeToComplete": "15-20 min",
  "tags": ["Education", "Research", "Learning"],
  "targetAudience": ["students", "educators"],
  "sections": [
    {
      "id": "section-A",
      "title": "Demographics",
      "description": "Basic information",
      "order": 1
    },
    {
      "id": "section-B",
      "title": "Learning Style",
      "description": "Your preferences",
      "order": 2
    }
  ],
  "data": [
    {
      "id": "question-12345",
      "sectionId": "section-A",
      "title": "What is your major?",
      "type": "shortText",
      "order": 1,
      "required": true,
      "options": [],
      "minChoice": null,
      "maxChoice": null,
      "imageUrl": null,
      "videoUrl": null
    },
    {
      "id": "question-12346",
      "sectionId": "section-A",
      "title": "Current year level?",
      "type": "radioButton",
      "order": 2,
      "required": true,
      "options": ["Freshman", "Sophomore", "Junior", "Senior", "Graduate"],
      "minChoice": null,
      "maxChoice": null,
      "imageUrl": null,
      "videoUrl": null
    },
    {
      "id": "question-12347",
      "sectionId": "section-B",
      "title": "Preferred learning methods?",
      "type": "checkBox",
      "order": 3,
      "required": true,
      "minChoice": 1,
      "maxChoice": 4,
      "options": ["Video Lectures", "Reading", "Hands-on Labs", "Group Discussion"],
      "imageUrl": null,
      "videoUrl": null
    }
  ]
}
```

#### User's Response:

```json
{
  "submittedAt": "2025-11-21T16:45:30.000Z",
  "responses": {
    "section-A": {
      "question-12345": "Computer Science",
      "question-12346": "Junior"
    },
    "section-B": {
      "question-12347": ["Video Lectures", "Hands-on Labs"]
    }
  }
}
```

---

## ⚠️ Important Notes

### For Survey Creation:

1. **Section IDs must be unique** - Use timestamp: `section-{Date.now()}`
2. **Question order is global** - Continuous numbering across all sections
3. **Options required for choice types** - Single/Multiple Choice, Dropdown
4. **targetAudience is array** - Backend expects array format
5. **All questions in flat data array** - Not nested inside sections

### For Survey Submission:

1. **Use question_another_id** - Not question number or database ID
2. **Group by section_another_id** - Backend expects section grouping
3. **Answer types must match** - String for text, Array for multiple choice, Integer for rating
4. **submittedAt must be ISO 8601** - Use `DateTime.now().toIso8601String()`
5. **Only answered questions** - Don't include unanswered optional questions

---

## 🧪 Validation Rules

### Creating Survey - Backend Will Reject If:

- ❌ Missing required fields: `title`, `description`, `timeToComplete`, `tags`, `targetAudience`
- ❌ Empty arrays: `tags`, `targetAudience`, `sections`, `data`
- ❌ Question `sectionId` doesn't match any section `id`
- ❌ Choice-type questions have empty `options` array
- ❌ Duplicate section `id` values
- ❌ `order` values are not sequential

### Submitting Response - Backend Will Reject If:

- ❌ User already answered this survey (409 Conflict)
- ❌ Survey doesn't exist (404 Not Found)
- ❌ Missing required question answers
- ❌ Invalid question IDs (don't exist in survey)
- ❌ Wrong answer type (e.g., array for single choice)

---

## 📋 Quick Reference

### Survey Creation Checklist:

```
✅ caption: Short post description
✅ title: Survey title
✅ description: Full description
✅ timeToComplete: "X-Y min" format
✅ tags: Array with at least 1 tag
✅ targetAudience: Array with at least 1 audience
✅ sections: Array with unique IDs and order field
✅ Each section has: id, title, description, order
✅ data: Flat array with all questions
✅ Each question has: id, sectionId, title, type, order, required, options, minChoice, maxChoice, imageUrl, videoUrl
✅ Each question has valid sectionId
✅ Question types use backend format: shortText, longText, email, date, rating, radioButton, checkBox, dropdown
✅ Choice questions (radioButton, checkBox, dropdown) have options array
✅ checkBox questions MUST have minChoice and maxChoice (not null)
✅ Non-checkBox questions have minChoice=null and maxChoice=null
✅ minChoice ≥ 1 and maxChoice ≤ options.length for checkBox
✅ order numbers are sequential (sections and questions)
✅ Question IDs are unique (question-{timestamp})
✅ Section IDs are unique (section-{timestamp})
```

### Survey Response Checklist:

```
✅ surveyTitle: Survey name (optional)
✅ surveyDescription: Survey desc (optional)
✅ submittedAt: ISO 8601 timestamp
✅ responses: Object grouped by section_another_id
✅ Each key is question_another_id
✅ Values match question types
✅ All required questions answered
✅ Multiple choice answers are arrays
✅ Ratings are integers (1-5)
```

---

## 🎯 Summary

**Creating Survey:**
- Uses `/post/send/questionnaire/mobile` endpoint
- Flat structure with `sections` array + `data` array
- Questions reference sections via `sectionId`

**Submitting Response:**
- Uses `/answer/questionnaire/<id>` endpoint  
- Nested structure grouped by `section_another_id`
- Uses `question_another_id` from backend response

Both formats are optimized for mobile and work perfectly with your backend! 🚀
