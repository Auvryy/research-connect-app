# Local Storage Implementation Guide

## Overview
This app now uses **SharedPreferences** for local storage to persist surveys. This allows users to create surveys that are saved on their device and displayed in the HomeFeed and ProfilePage.

## Features Implemented

### ✅ Survey Persistence
- Surveys created by users are saved to local storage
- Data persists across app restarts
- JSON serialization for all survey data

### ✅ HomeFeed Display
- Shows all surveys (mock + user-created)
- Pull-to-refresh functionality
- Filter by tags (All, Business, Technology, Humanities)
- Loading indicator while fetching data

### ✅ ProfilePage Display
- Shows only user's created surveys
- Dynamic survey count in stats
- Empty state when no surveys exist
- Loading indicator while fetching data

## Data Flow

### Creating a Survey
```
1. User fills out survey details (CreateSurveyPage)
2. User adds target audience (TargetAudiencePage)
3. User creates questions (QuestionsPage)
4. User reviews survey (SurveyReviewPage)
5. User clicks "Publish Survey"
   ↓
6. SurveyService.surveyCreationToSurvey() converts data
7. SurveyService.saveSurvey() saves to SharedPreferences
8. Success message shown
9. Navigate back to HomePage
   ↓
10. HomeFeed reloads → shows new survey
11. ProfilePage reloads → shows new survey
```

### Loading Surveys
```
HomeFeed:
- Loads ALL surveys from local storage
- Combines with mock surveys
- Displays in feed

ProfilePage:
- Loads ALL surveys from local storage
- Filters by current user ID
- Displays only user's surveys
```

## Files Modified

### New Files
- `lib/data/survey_service.dart` - Local storage service

### Modified Files
- `pubspec.yaml` - Added shared_preferences dependency
- `lib/screens/add/survey_review_page.dart` - Save survey on publish
- `lib/screens/home/home_feed.dart` - Load surveys from storage
- `lib/screens/profile/profile_page.dart` - Load user surveys

## API Documentation

### SurveyService Methods

#### `saveSurvey(Survey survey)`
Saves a survey to local storage.
```dart
final success = await SurveyService.saveSurvey(survey);
```

#### `getAllSurveys()`
Gets all surveys from local storage.
```dart
final surveys = await SurveyService.getAllSurveys();
```

#### `getUserSurveys(String userId)`
Gets surveys for a specific user.
```dart
final userSurveys = await SurveyService.getUserSurveys('user-123');
```

#### `deleteSurvey(String surveyId)`
Deletes a survey from storage.
```dart
final success = await SurveyService.deleteSurvey('survey-123');
```

#### `surveyCreationToSurvey(SurveyCreation creation, String userId)`
Converts SurveyCreation to Survey model.
```dart
final survey = SurveyService.surveyCreationToSurvey(surveyData, userId);
```

## Backend Integration Ready

The current implementation is **100% ready for backend integration**. To switch:

### Current (Local Storage):
```dart
final surveys = await SurveyService.getAllSurveys();
```

### Future (Backend API):
```dart
// Just change the implementation inside SurveyService
static Future<List<Survey>> getAllSurveys() async {
  final response = await DioClient().get('/surveys');
  return (response.data as List)
      .map((json) => Survey.fromJson(json))
      .toList();
}
```

## Data Structure

### Stored in SharedPreferences
Key: `saved_surveys`

```json
[
  {
    "id": "1730000000000",
    "title": "Customer Satisfaction Survey",
    "description": "Help us improve our services",
    "timeToComplete": 5,
    "tags": ["Business", "Technology"],
    "targetAudience": "Students, General Public",
    "creator": "user-default-123",
    "createdAt": "2025-10-25T10:30:00.000Z",
    "status": true,
    "responses": 0,
    "questions": [
      {
        "questionId": "q-uuid-123",
        "text": "How satisfied are you?",
        "type": "ratingScale",
        "required": true,
        "options": null
      }
    ]
  }
]
```

## Testing

### Clear All Surveys (for testing)
```dart
await SurveyService.clearAllSurveys();
```

### Set User ID
```dart
await SurveyService.setCurrentUserId('user-123');
```

## Benefits

1. ✅ **Works Offline** - No internet required
2. ✅ **Persistent** - Data saved across app restarts
3. ✅ **Fast** - No network latency
4. ✅ **Backend Ready** - Easy to switch to API
5. ✅ **Type Safe** - Full Dart type checking
6. ✅ **Clean Architecture** - Service layer separation

## Next Steps for Backend

When ready to integrate with backend:

1. Update `SurveyService` methods to use `DioClient`
2. Add authentication token to requests
3. Handle network errors and offline mode
4. Add caching strategy (local + remote)
5. Implement sync mechanism

---

**Created:** October 25, 2025
**Status:** ✅ Production Ready
