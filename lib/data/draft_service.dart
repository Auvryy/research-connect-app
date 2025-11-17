import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:inquira/models/survey_creation.dart';

/// Service for managing survey drafts during creation
class DraftService {
  static const String _draftKey = 'survey_draft';
  
  /// Save current survey draft
  static Future<bool> saveDraft(SurveyCreation surveyData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(surveyData.toJson());
      await prefs.setString(_draftKey, json);
      print('Draft saved successfully');
      return true;
    } catch (e) {
      print('Error saving draft: $e');
      return false;
    }
  }
  
  /// Load saved survey draft
  static Future<SurveyCreation?> loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_draftKey);
      
      if (json == null || json.isEmpty) {
        print('No draft found');
        return null;
      }
      
      final data = jsonDecode(json) as Map<String, dynamic>;
      print('Draft loaded successfully');
      return SurveyCreation.fromJson(data);
    } catch (e) {
      print('Error loading draft: $e');
      return null;
    }
  }
  
  /// Clear draft after successful publish or user cancellation
  static Future<bool> clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
      print('Draft cleared');
      return true;
    } catch (e) {
      print('Error clearing draft: $e');
      return false;
    }
  }
  
  /// Check if draft exists
  static Future<bool> hasDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_draftKey);
      return json != null && json.isNotEmpty;
    } catch (e) {
      print('Error checking draft: $e');
      return false;
    }
  }
}
