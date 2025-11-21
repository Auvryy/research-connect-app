import 'package:dio/dio.dart';
import 'dio_client.dart';

class SurveyAPI {
  /// Submit a survey to the backend
  /// POST /api/survey/post/send/questionnaire/mobile
  static Future<Map<String, dynamic>> createSurvey(Map<String, dynamic> surveyData) async {
    try {
      final dio = await DioClient.instance;
      
      print('SurveyAPI: Sending survey data to backend...');
      print('Survey data: $surveyData');
      
      final response = await dio.post(
        '/../survey/post/send/questionnaire/mobile',
        data: surveyData,
      );
      
      print('SurveyAPI: Response status: ${response.statusCode}');
      print('SurveyAPI: Response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['ok'] == true) {
        return {
          'ok': true,
          'message': response.data['message'] ?? 'Survey created successfully',
          'data': response.data['data'],
        };
      }
      
      return {
        'ok': false,
        'message': response.data['message'] ?? 'Failed to create survey',
      };
    } on DioException catch (e) {
      print('SurveyAPI: DioException: ${e.message}');
      print('SurveyAPI: Response: ${e.response?.data}');
      
      if (e.response?.data is Map) {
        return {
          'ok': false,
          'message': e.response?.data['message'] ?? 'Failed to create survey',
        };
      }
      
      return {
        'ok': false,
        'message': e.message ?? 'Network error',
      };
    } catch (e) {
      print('SurveyAPI: Error: $e');
      return {
        'ok': false,
        'message': e.toString(),
      };
    }
  }

  /// Get all surveys
  /// GET /api/survey/post/get/
  static Future<List<dynamic>> getAllSurveys() async {
    try {
      final dio = await DioClient.instance;
      final response = await dio.get('/../survey/post/get');
      
      if (response.statusCode == 200 && response.data['ok'] == true) {
        return response.data['data'] as List<dynamic>;
      }
      
      throw Exception(response.data['message'] ?? 'Failed to fetch surveys');
    } catch (e) {
      print('SurveyAPI: Error fetching surveys: $e');
      rethrow;
    }
  }

  /// Get a single survey by ID
  /// GET /api/survey/post/get/<id>
  static Future<Map<String, dynamic>> getSurvey(int id) async {
    try {
      final dio = await DioClient.instance;
      final response = await dio.get('/../survey/post/get/$id');
      
      if (response.statusCode == 200 && response.data['ok'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      
      throw Exception(response.data['message'] ?? 'Failed to fetch survey');
    } catch (e) {
      print('SurveyAPI: Error fetching survey: $e');
      rethrow;
    }
  }

  /// Get survey questionnaire (questions) by post ID
  /// GET /api/survey/post/get/questionnaire/<id>
  static Future<Map<String, dynamic>> getSurveyQuestionnaire(int postId) async {
    try {
      final dio = await DioClient.instance;
      print('SurveyAPI: Fetching questionnaire for post ID: $postId');
      
      final response = await dio.get('/../survey/post/get/questionnaire/$postId');
      
      print('SurveyAPI: Response status: ${response.statusCode}');
      print('SurveyAPI: Response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['ok'] == true) {
        return {
          'ok': true,
          'survey': response.data['data']['survey'],
          'questions': response.data['data']['questions'],
        };
      }
      
      throw Exception(response.data['message'] ?? 'Failed to fetch questionnaire');
    } on DioException catch (e) {
      print('SurveyAPI: DioException: ${e.message}');
      print('SurveyAPI: Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('SurveyAPI: Error fetching questionnaire: $e');
      rethrow;
    }
  }

  /// Submit survey response
  /// POST /api/survey/answer/questionnaire/<survey_id>
  static Future<Map<String, dynamic>> submitSurveyResponse(
    int surveyId,
    Map<String, dynamic> responseData,
  ) async {
    try {
      final dio = await DioClient.instance;
      
      print('SurveyAPI: Submitting survey response for survey ID: $surveyId');
      print('Response data: $responseData');
      
      final response = await dio.post(
        '/../survey/answer/questionnaire/$surveyId',
        data: responseData,
      );
      
      print('SurveyAPI: Response status: ${response.statusCode}');
      print('SurveyAPI: Response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['ok'] == true) {
        return {
          'ok': true,
          'message': response.data['message'] ?? 'You have successfully answered this survey',
          'data': response.data['data'],
        };
      }
      
      return {
        'ok': false,
        'message': response.data['message'] ?? 'Failed to submit response',
      };
    } on DioException catch (e) {
      print('SurveyAPI: DioException: ${e.message}');
      print('SurveyAPI: Response: ${e.response?.data}');
      
      if (e.response?.data is Map) {
        final message = e.response?.data['message'] ?? 'Failed to submit response';
        
        // Check for specific error codes
        if (e.response?.statusCode == 409) {
          return {
            'ok': false,
            'message': message, // "You already answered this survey."
            'alreadyAnswered': true,
          };
        }
        
        return {
          'ok': false,
          'message': message,
        };
      }
      
      return {
        'ok': false,
        'message': e.message ?? 'Network error',
      };
    } catch (e) {
      print('SurveyAPI: Error: $e');
      return {
        'ok': false,
        'message': e.toString(),
      };
    }
  }

  /// Check if user has already answered a survey
  /// POST /api/survey/questionnaire/is_answered
  static Future<Map<String, dynamic>> checkIfAnswered(int surveyId) async {
    try {
      final dio = await DioClient.instance;
      
      final response = await dio.post(
        '/../survey/questionnaire/is_answered',
        data: {'survey_id': surveyId},
      );
      
      if (response.statusCode == 200 && response.data['ok'] == true) {
        return {
          'ok': true,
          'alreadyAnswered': false,
          'message': response.data['message'],
        };
      } else if (response.statusCode == 409) {
        return {
          'ok': true,
          'alreadyAnswered': true,
          'message': response.data['message'],
        };
      }
      
      return {
        'ok': false,
        'message': response.data['message'] ?? 'Failed to check survey status',
      };
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return {
          'ok': true,
          'alreadyAnswered': true,
          'message': e.response?.data['message'] ?? 'You have already answered this survey',
        };
      }
      
      return {
        'ok': false,
        'message': e.response?.data['message'] ?? 'Network error',
      };
    } catch (e) {
      return {
        'ok': false,
        'message': e.toString(),
      };
    }
  }
}
