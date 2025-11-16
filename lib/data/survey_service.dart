import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inquira/models/survey.dart';
import 'package:inquira/models/survey_creation.dart';

class SurveyService {
  static const String _surveysKey = 'saved_surveys';
  static const String _currentUserIdKey = 'current_user_id';
  
  // In-memory fallback storage
  static List<Survey> _inMemorySurveys = [];
  
  // Cache the SharedPreferences instance
  static SharedPreferences? _prefsInstance;
  
  /// Get or initialize SharedPreferences instance
  static Future<SharedPreferences?> _getPrefs() async {
    if (_prefsInstance != null) {
      return _prefsInstance;
    }
    
    try {
      _prefsInstance = await SharedPreferences.getInstance();
      print('SharedPreferences instance cached');
      return _prefsInstance;
    } catch (e) {
      print('Failed to get SharedPreferences: $e');
      return null;
    }
  }

  /// Save a survey to local storage
  static Future<bool> saveSurvey(Survey survey) async {
    try {
      print('SurveyService: Attempting to save survey...');
      
      // Try to get cached or new SharedPreferences instance
      final prefs = await _getPrefs();
      
      if (prefs == null) {
        print('SurveyService: SharedPreferences not available, using in-memory storage');
        return _saveToMemory(survey);
      }
      
      print('SurveyService: SharedPreferences obtained');
      
      // Get existing surveys
      print('SurveyService: Loading existing surveys...');
      final surveys = await getAllSurveys();
      print('SurveyService: Found ${surveys.length} existing surveys');
      
      // Add or update survey
      final existingIndex = surveys.indexWhere((s) => s.id == survey.id);
      if (existingIndex != -1) {
        print('SurveyService: Updating existing survey at index $existingIndex');
        surveys[existingIndex] = survey;
      } else {
        print('SurveyService: Adding new survey');
        surveys.add(survey);
      }
      
      // Also save to memory as backup
      _saveToMemory(survey);
      
      // Convert to JSON and save
      print('SurveyService: Converting ${surveys.length} surveys to JSON...');
      final surveysJson = surveys.map((s) {
        try {
          return s.toJson();
        } catch (e) {
          print('ERROR converting survey ${s.id} to JSON: $e');
          rethrow;
        }
      }).toList();
      
      print('SurveyService: Encoding to JSON string...');
      final jsonString = jsonEncode(surveysJson);
      print('SurveyService: JSON string length: ${jsonString.length}');
      
      print('SurveyService: Saving to SharedPreferences...');
      final saveSuccess = await prefs.setString(_surveysKey, jsonString);
      print('SurveyService: Save success: $saveSuccess');
      
      return saveSuccess;
    } catch (e, stackTrace) {
      print('ERROR in SurveyService.saveSurvey: $e');
      print('Stack trace: $stackTrace');
      
      // Fallback to in-memory storage
      print('SurveyService: Error occurred, falling back to in-memory storage');
      return _saveToMemory(survey);
    }
  }
  
  /// Save to in-memory storage (fallback)
  static Future<bool> _saveToMemory(Survey survey) {
    try {
      print('SurveyService: Saving to in-memory storage...');
      final existingIndex = _inMemorySurveys.indexWhere((s) => s.id == survey.id);
      if (existingIndex != -1) {
        _inMemorySurveys[existingIndex] = survey;
      } else {
        _inMemorySurveys.add(survey);
      }
      print('SurveyService: In-memory storage now has ${_inMemorySurveys.length} surveys');
      return Future.value(true);
    } catch (e) {
      print('ERROR in _saveToMemory: $e');
      return Future.value(false);
    }
  }

  /// Get all surveys from local storage
  static Future<List<Survey>> getAllSurveys() async {
    // Always check in-memory storage first for recent additions
    if (_inMemorySurveys.isNotEmpty) {
      print('SurveyService.getAllSurveys: Have ${_inMemorySurveys.length} surveys in memory');
    }
    
    try {
      print('SurveyService.getAllSurveys: Getting SharedPreferences...');
      final prefs = await _getPrefs();
      
      if (prefs == null) {
        print('SurveyService.getAllSurveys: SharedPreferences not available, returning in-memory surveys');
        return _inMemorySurveys;
      }
      
      final surveysString = prefs.getString(_surveysKey);
      
      print('SurveyService.getAllSurveys: Retrieved string length: ${surveysString?.length ?? 0}');
      
      List<Survey> persistedSurveys = [];
      
      if (surveysString != null && surveysString.isNotEmpty) {
        print('SurveyService.getAllSurveys: Decoding JSON...');
        final List<dynamic> surveysJson = jsonDecode(surveysString);
        print('SurveyService.getAllSurveys: Decoded ${surveysJson.length} surveys');
        
        persistedSurveys = surveysJson.map((json) => Survey.fromJson(json)).toList();
        print('SurveyService.getAllSurveys: Loaded ${persistedSurveys.length} surveys from SharedPreferences');
      }
      
      // Merge persisted and in-memory surveys (in-memory takes precedence)
      final mergedSurveys = <String, Survey>{};
      
      // Add persisted surveys first
      for (var survey in persistedSurveys) {
        mergedSurveys[survey.id] = survey;
      }
      
      // Add/override with in-memory surveys
      for (var survey in _inMemorySurveys) {
        mergedSurveys[survey.id] = survey;
      }
      
      final result = mergedSurveys.values.toList();
      print('SurveyService.getAllSurveys: Returning ${result.length} total surveys');
      
      return result;
    } catch (e, stackTrace) {
      print('ERROR in SurveyService.getAllSurveys: $e');
      print('Stack trace: $stackTrace');
      
      // Return in-memory surveys as fallback
      print('SurveyService.getAllSurveys: Error occurred, returning ${_inMemorySurveys.length} surveys from in-memory storage');
      return _inMemorySurveys;
    }
  }

  /// Get surveys for a specific user
  static Future<List<Survey>> getUserSurveys(String userId) async {
    try {
      final allSurveys = await getAllSurveys();
      final userSurveys = allSurveys.where((s) => s.creator == userId).toList();
      print('SurveyService.getUserSurveys: Found ${userSurveys.length} surveys for user $userId');
      return userSurveys;
    } catch (e) {
      print('Error loading user surveys: $e');
      return [];
    }
  }

  /// Delete a survey
  static Future<bool> deleteSurvey(String surveyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final surveys = await getAllSurveys();
      
      surveys.removeWhere((s) => s.id == surveyId);
      
      final surveysJson = surveys.map((s) => s.toJson()).toList();
      await prefs.setString(_surveysKey, jsonEncode(surveysJson));
      
      return true;
    } catch (e) {
      print('Error deleting survey: $e');
      return false;
    }
  }

  /// Get current user ID from logged-in user
  static Future<String> getCurrentUserId() async {
    try {
      print('SurveyService.getCurrentUserId: Getting user ID...');
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final username = prefs.getString('username');
      
      if (userId != null) {
        print('SurveyService.getCurrentUserId: User ID: $userId');
        return userId.toString();
      } else if (username != null) {
        // Fallback to username if ID is not available
        print('SurveyService.getCurrentUserId: Using username: $username');
        return username;
      } else {
        print('SurveyService.getCurrentUserId: No user logged in, using default');
        return 'user-default-123';
      }
    } catch (e, stackTrace) {
      print('ERROR in SurveyService.getCurrentUserId: $e');
      print('Stack trace: $stackTrace');
      return 'user-default-123';
    }
  }

  /// Set current user ID
  static Future<void> setCurrentUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserIdKey, userId);
  }

  /// Convert SurveyCreation to Survey (for saving)
  static Survey surveyCreationToSurvey(SurveyCreation creation, String userId) {
    try {
      print('Converting SurveyCreation to Survey...');
      print('  Title: ${creation.title}');
      print('  Description: ${creation.description}');
      print('  Time to complete: ${creation.timeToComplete}');
      print('  Tags: ${creation.tags}');
      print('  Target audience: ${creation.targetAudience}');
      print('  Questions count: ${creation.questions.length}');
      print('  Sections count: ${creation.sections.length}');
      
      // Validate required fields
      if (creation.title.isEmpty) {
        throw Exception('Survey title is required');
      }
      
      if (creation.questions.isEmpty) {
        throw Exception('Survey must have at least one question');
      }
      
      final surveyId = creation.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      print('  Survey ID: $surveyId');
      
      // Convert questions
      print('Converting questions...');
      final questions = creation.questions.map((q) {
        print('    Question: ${q.id} - ${q.text} (${q.type})');
        return Question(
          questionId: q.id,
          text: q.text,
          type: q.type,
          required: q.required,
          options: q.options.isNotEmpty ? q.options : null,
        );
      }).toList();
      
      print('Creating Survey object...');
      final survey = Survey(
        id: surveyId,
        title: creation.title,
        caption: creation.caption,
        description: creation.description,
        timeToComplete: creation.timeToComplete,
        tags: creation.tags.isNotEmpty ? creation.tags : ['General'],
        creator: userId,
        targetAudience: creation.targetAudience.isNotEmpty 
            ? creation.targetAudience.join(', ')
            : 'General Public',
        questions: questions,
        responses: 0,
        createdAt: DateTime.now(),
        status: true, // Active by default
      );
      
      print('Survey object created successfully!');
      
      // Test JSON conversion
      print('Testing JSON conversion...');
      final testJson = survey.toJson();
      print('JSON conversion successful! Keys: ${testJson.keys.join(', ')}');
      
      return survey;
    } catch (e, stackTrace) {
      print('ERROR in surveyCreationToSurvey: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Clear all surveys (useful for testing)
  static Future<void> clearAllSurveys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_surveysKey);
    _inMemorySurveys.clear(); // Also clear in-memory storage
    print('All surveys cleared from both SharedPreferences and in-memory storage');
  }
}
