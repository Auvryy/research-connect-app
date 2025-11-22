# Image Upload Implementation Guide

## Overview
This document explains how image uploads work in the survey creation flow using FormData.

## Key Concept: `imageKey`

Each question with an image gets a unique key in the format: **`image_{questionId}`**

### Example:
```
Question ID: "question-1763633434439"
Image Key:   "image_question-1763633434439"
```

---

## 🔧 Implementation Details

### 1. **Model Layer** (`lib/models/survey_creation.dart`)

#### Added `imageKey` getter:
```dart
class SurveyQuestion {
  String id;
  String? imageUrl;
  // ... other fields
  
  /// Get the FormData key for this question's image
  /// Returns "image_{questionId}"
  String get imageKey => 'image_$id';
}
```

#### JSON output includes `imageKey`:
```json
{
  "questionId": "question-1763633434439",
  "text": "What is your primary use case?",
  "type": "shortAnswer",
  "required": true,
  "options": [],
  "imageUrl": null,
  "imageKey": "image_question-1763633434439",  // ← Backend knows which FormData field
  "videoUrl": null,
  "order": 4,
  "sectionId": "section-usage"
}
```

---

### 2. **API Layer** (`lib/data/api/survey_api.dart`)

#### FormData Structure:
```dart
FormData formData = FormData.fromMap({
  // Survey metadata (text fields)
  'caption': 'Survey',
  'title': 'My Survey Title',
  'description': 'Survey description',
  'timeToComplete': '5-10 min',
  'tags': 'research,feedback',
  'targetAudience': 'Students,Researchers',
  
  // Complex data as JSON strings
  'sections': '[{"id":"section-1", "title":"Demographics", ...}]',
  'data': '[{"questionId":"question-1", "imageKey":"image_question-1", ...}]',
});

// Add image files with imageKey as field name
formData.files.add(
  MapEntry(
    'image_question-1763633434439',  // ← Key from question.imageKey
    await MultipartFile.fromFile('/path/to/image.jpg'),
  ),
);
```

#### API Method:
```dart
static Future<Map<String, dynamic>> createSurvey({
  required Map<String, dynamic> surveyData,
  Map<String, File>? questionImages,  // Map<imageKey, File>
}) async {
  // Automatically uses FormData if images exist, otherwise JSON
  if (hasImages) {
    FormData formData = FormData.fromMap({...});
    for (var entry in questionImages.entries) {
      formData.files.add(MapEntry(entry.key, MultipartFile.fromFile(...)));
    }
    return dio.post('/survey/create', data: formData);
  } else {
    return dio.post('/survey/create', data: surveyData);
  }
}
```

---

### 3. **UI Layer** (`lib/screens/add/survey_review_page.dart`)

#### Collecting Images:
```dart
void _publishSurvey(BuildContext context) async {
  // Collect images from questions
  Map<String, File> questionImages = {};
  
  for (var question in surveyData.questions) {
    if (question.imageUrl != null && 
        !question.imageUrl!.startsWith('http')) {
      
      final imageFile = File(question.imageUrl!);
      if (imageFile.existsSync()) {
        // Use imageKey from model
        questionImages[question.imageKey] = imageFile;
      }
    }
  }
  
  // Submit with images
  final result = await SurveyAPI.createSurvey(
    surveyData: surveyData.toBackendJson(),
    questionImages: questionImages,
  );
}
```

---

## 📡 Backend Integration

### What Backend Receives

#### FormData Structure:
```
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary...

------WebKitFormBoundary...
Content-Disposition: form-data; name="caption"

Survey
------WebKitFormBoundary...
Content-Disposition: form-data; name="title"

My Survey Title
------WebKitFormBoundary...
Content-Disposition: form-data; name="data"

[{"questionId":"question-1763633434439","imageKey":"image_question-1763633434439",...}]
------WebKitFormBoundary...
Content-Disposition: form-data; name="image_question-1763633434439"; filename="photo.jpg"
Content-Type: image/jpeg

[binary image data]
------WebKitFormBoundary...
```

### Backend Processing (Python Example)

```python
@app.route('/survey/post/send/questionnaire/mobile', methods=['POST'])
def create_survey():
    # Parse JSON fields
    caption = request.form.get('caption')
    title = request.form.get('title')
    sections = json.loads(request.form.get('sections'))
    data = json.loads(request.form.get('data'))
    
    # Process each question
    for question in data:
        question_id = question['questionId']
        image_key = question['imageKey']  # "image_question-1763633434439"
        
        # Check if this question has an image
        if image_key in request.files:
            image_file = request.files[image_key]
            
            # Save file
            filename = f"{question_id}.jpg"
            filepath = f"/uploads/questions/{filename}"
            image_file.save(filepath)
            
            # Store path in database
            question_obj.image = filepath
            db.session.add(question_obj)
    
    db.session.commit()
    return {'ok': True, 'message': 'Survey created'}
```

### Key Backend Steps:

1. **Parse FormData fields**: Extract text fields and JSON strings
2. **Loop through questions**: Check each question's `imageKey`
3. **Find matching files**: Look for `request.files[imageKey]`
4. **Save images**: Store files in `/uploads/questions/`
5. **Update database**: Link image path to question record

---

## 🔄 Complete Flow

```
Survey Creation with Images:

1. User adds image to question
   ↓
2. Image stored locally at /path/to/image.jpg
   ↓
3. Question has:
   - id: "question-1763633434439"
   - imageUrl: "/path/to/image.jpg"
   - imageKey: "image_question-1763633434439"
   ↓
4. User publishes survey
   ↓
5. survey_review_page collects images:
   Map<String, File> {
     "image_question-1763633434439": File("/path/to/image.jpg")
   }
   ↓
6. SurveyAPI creates FormData:
   - Metadata as text fields
   - Questions as JSON string (includes imageKey)
   - Images as MultipartFile with imageKey as field name
   ↓
7. POST to backend with FormData
   ↓
8. Backend receives:
   - Parses questions JSON
   - Finds image using imageKey
   - Saves file
   - Stores path in database
   ↓
9. Success response
   ↓
10. User takes survey later:
    Backend returns: "image": "/uploads/questions/question-1763633434439.jpg"
    Flutter displays: Image.network(url)
```

---

## ✅ Summary

| Component | Responsibility |
|-----------|---------------|
| **Model** | Generates `imageKey` in format `image_{questionId}` |
| **API** | Creates FormData with images using `imageKey` as field name |
| **UI** | Collects image files and calls API with proper structure |
| **Backend** | Uses `imageKey` to identify which question each image belongs to |

### Key Points:

✅ **imageKey format**: Always `image_{questionId}`  
✅ **No images?**: Uses JSON instead of FormData  
✅ **Multiple images?**: Each uses unique imageKey  
✅ **Backend parsing**: Loop through `image_*` fields  
✅ **Storage**: Backend saves files and returns paths  

---

## 🎯 For Your Backend Developer

Tell them:

1. **Field Name Pattern**: `image_{questionId}`
2. **Extract Question ID**: `question_id = key.replace('image_', '')`
3. **File Format**: Standard multipart file
4. **Questions Array**: Available in `data` field (JSON string)
5. **Matching**: Use `imageKey` from questions array to match with FormData fields

**Example:**
```python
# Question in data array
{"questionId": "question-123", "imageKey": "image_question-123"}

# File in FormData
request.files['image_question-123']  # ← Same key!
```

That's it! 🚀
