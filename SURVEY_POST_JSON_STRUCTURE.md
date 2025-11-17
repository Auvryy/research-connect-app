# Survey Post JSON Structure

## API Endpoint
**POST** `/api/survey/post/send/questionnaire/mobile`

**Headers:**
- `Content-Type: application/json`
- `Cookie: access_token_cookie=<your_jwt_token>`

---

## Complete JSON Structure

```json
{
  "caption": "Survey caption text (shown as post content in feed)",
  "title": "Survey Title",
  "description": "Detailed survey description explaining purpose and context",
  "timeToComplete": "15",
  "tags": ["Technology", "Education", "Psychology"],
  "targetAudience": ["Students", "Professionals"],
  "data": [
    {
      "questionId": "uuid-v4-string",
      "title": "What is your preferred programming language?",
      "type": "multipleChoice",
      "required": true,
      "order": 0,
      "sectionId": "section-uuid-1",
      "options": [
        "Python",
        "JavaScript",
        "Java",
        "C++"
      ],
      "imageUrl": null,
      "videoUrl": null
    },
    {
      "questionId": "uuid-v4-string-2",
      "title": "Select all frameworks you have used",
      "type": "checkboxes",
      "required": true,
      "order": 1,
      "sectionId": "section-uuid-1",
      "options": [
        "React",
        "Vue",
        "Angular",
        "Flutter"
      ],
      "imageUrl": null,
      "videoUrl": null
    },
    {
      "questionId": "uuid-v4-string-3",
      "title": "How would you rate your coding experience?",
      "type": "ratingScale",
      "required": true,
      "order": 2,
      "sectionId": "section-uuid-2",
      "options": [],
      "imageUrl": null,
      "videoUrl": null
    },
    {
      "questionId": "uuid-v4-string-4",
      "title": "What motivates you to learn programming?",
      "type": "shortText",
      "required": false,
      "order": 3,
      "sectionId": "section-uuid-2",
      "options": [],
      "imageUrl": null,
      "videoUrl": null
    },
    {
      "questionId": "uuid-v4-string-5",
      "title": "Describe your most challenging project",
      "type": "longText",
      "required": false,
      "order": 4,
      "sectionId": "section-uuid-2",
      "options": [],
      "imageUrl": null,
      "videoUrl": "https://example.com/video.mp4"
    },
    {
      "questionId": "uuid-v4-string-6",
      "title": "Would you recommend programming as a career?",
      "type": "yesNo",
      "required": true,
      "order": 5,
      "sectionId": "section-uuid-3",
      "options": [],
      "imageUrl": null,
      "videoUrl": null
    },
    {
      "questionId": "uuid-v4-string-7",
      "title": "Select your preferred IDE",
      "type": "dropdown",
      "required": true,
      "order": 6,
      "sectionId": "section-uuid-3",
      "options": [
        "VS Code",
        "IntelliJ IDEA",
        "PyCharm",
        "Sublime Text"
      ],
      "imageUrl": null,
      "videoUrl": null
    }
  ],
  "sections": [
    {
      "id": "section-uuid-1",
      "title": "Programming Background",
      "description": "Tell us about your programming experience",
      "order": 0
    },
    {
      "id": "section-uuid-2",
      "title": "Learning Journey",
      "description": "Share your learning experiences",
      "order": 1
    },
    {
      "id": "section-uuid-3",
      "title": "Tools & Preferences",
      "description": "Your development environment preferences",
      "order": 2
    }
  ]
}
```

---

## Field Descriptions

### Root Level Fields

| Field | Type | Required | Description | Validation |
|-------|------|----------|-------------|------------|
| `caption` | string | Yes | Post content shown in feed | 4-40 words, max 512 chars |
| `title` | string | Yes | Survey title | 4-40 words, max 512 chars |
| `description` | string | Yes | Detailed survey description | 20-100 words, max 5000 chars |
| `timeToComplete` | string | Yes | Estimated minutes to complete | Number as string (e.g., "15") |
| `tags` | array | Yes | Survey categories | At least 1 tag required |
| `targetAudience` | array | Yes | Target demographics | At least 1 audience required |
| `data` | array | Yes | Array of question objects | At least 1 question required |
| `sections` | array | Yes | Array of section objects | At least 1 section required |

### Question Object (`data` array)

| Field | Type | Required | Description | Validation |
|-------|------|----------|-------------|------------|
| `questionId` | string | Yes | Unique identifier | UUID v4 format |
| `title` | string | Yes | Question text | 4-150 words, max 2000 chars |
| `type` | string | Yes | Question type | See question types below |
| `required` | boolean | Yes | Is answer required | true or false |
| `order` | number | Yes | Display order | 0-based index |
| `sectionId` | string | Yes | Parent section ID | Must match a section.id |
| `options` | array | Conditional | Answer choices | Required for choice-based types, 2+ options, max 500 chars each |
| `imageUrl` | string/null | No | Image attachment path | Local path or null |
| `videoUrl` | string/null | No | Video URL | Valid URL or null |

### Question Types

Choice-based types (require `options` with 2+ items):
- `"multipleChoice"` - Single selection from options
- `"checkboxes"` - Multiple selections allowed
- `"dropdown"` - Dropdown selection

Rating type (no options):
- `"ratingScale"` - Star rating scale (e.g., 1-5 stars)

Text input types (no options):
- `"shortText"` - Single-line text input
- `"longText"` - Multi-line text input

Boolean type (no options):
- `"yesNo"` - Yes/No question

### Section Object (`sections` array)

| Field | Type | Required | Description | Validation |
|-------|------|----------|-------------|------------|
| `id` | string | Yes | Unique identifier | UUID v4 format |
| `title` | string | Yes | Section title | 5-256 characters |
| `description` | string | No | Section description | 5-512 characters if provided |
| `order` | number | Yes | Display order | 0-based index |

---

## Validation Rules Summary

### Survey Level
- ✅ Title: 4-40 words, max 512 characters
- ✅ Caption: 4-40 words, max 512 characters
- ✅ Description: 20-100 words, max 5000 characters
- ✅ At least 1 tag
- ✅ At least 1 target audience
- ✅ At least 1 question
- ✅ At least 1 section

### Question Level
- ✅ Question text: 4-150 words, max 2000 characters
- ✅ Choice-based questions must have 2+ options
- ✅ Each option: 1-500 characters
- ✅ sectionId must reference an existing section
- ✅ Only one media (image OR video, not both)

### Section Level
- ✅ Title: 5-256 characters (required)
- ✅ Description: 5-512 characters (optional)
- ✅ All questions must belong to a valid section

---

## Success Response

```json
{
  "ok": true,
  "message": "Post added successfully"
}
```

## Error Responses

### 400 - Missing Data
```json
{
  "ok": false,
  "message": "Survey is missing data",
  "survey": {
    "Question1": {
      "title1": "Question 1: Title is missing"
    }
  }
}
```

### 422 - Requirements Not Met
```json
{
  "ok": false,
  "message": "You must meet the requirements for the survey",
  "survey": {
    "title1": "Question must be at least 4 words"
  }
}
```

### 500 - Server Error
```json
{
  "ok": false,
  "message": "Database error"
}
```

---

## Implementation Notes

1. **Frontend sends "title" field** - Backend validation checks for "title" in questions
2. **Supported question types** - `multipleChoice`, `checkboxes`, `dropdown`, `ratingScale`, `yesNo`, `shortText`, `longText`
3. **Survey appears in feed automatically** - After successful POST, survey is added to posts table and appears in home feed
4. **Draft is cleared on success** - Local draft removed after successful publish
5. **Authentication required** - Must have valid JWT cookie
6. **Rate limited** - 1 per minute, 20 per hour, 100 per day

---

## Example Minimal Valid Survey

```json
{
  "caption": "Quick tech survey for students",
  "title": "Technology Usage Survey 2025",
  "description": "This survey aims to understand how students use technology in their daily lives. Your responses will help improve educational technology tools and resources. Please answer honestly and thoughtfully.",
  "timeToComplete": "5",
  "tags": ["Technology"],
  "targetAudience": ["Students"],
  "data": [
    {
      "questionId": "q1",
      "title": "What device do you primarily use for studying?",
      "type": "multipleChoice",
      "required": true,
      "order": 0,
      "sectionId": "s1",
      "options": ["Laptop", "Tablet"],
      "imageUrl": null,
      "videoUrl": null
    }
  ],
  "sections": [
    {
      "id": "s1",
      "title": "Device Usage",
      "description": "Information about your devices",
      "order": 0
    }
  ]
}
```

---

**Last Updated:** November 17, 2025
**API Version:** Mobile v1
**Endpoint:** `/api/survey/post/send/questionnaire/mobile`
