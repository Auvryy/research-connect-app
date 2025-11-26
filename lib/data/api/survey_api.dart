import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'dio_client.dart';

class SurveyAPI {
  /// Submit a survey to the backend with image uploads using FormData
  /// POST /api/survey/post/send/questionnaire/mobile
  /// 
  /// Always uses FormData (matching web implementation) with the following structure:
  /// - ALL survey data bundled as ONE JSON string under "surveyData" key
  /// - Image files with keys in format "image_{questionId}"
  /// 
  /// Example FormData structure:
  /// ```
  /// {
  ///   "surveyData": "{\"caption\":\"Survey\",\"title\":\"My Survey\",...}",  // JSON string of entire survey
  ///   "image_question-1763633434439": [FILE],  // Image file for question (optional)
  ///   "image_question-1763633434440": [FILE]   // Image file for another question (optional)
  /// }
  /// ```
  static Future<Map<String, dynamic>> createSurvey({
    required Map<String, dynamic> surveyData,
    Map<String, File>? questionImages,
  }) async {
    try {
      final dio = await DioClient.instance;
      
      print('SurveyAPI: Preparing survey submission...');
      
      // Proactively refresh token before submitting to prevent expiry during upload
      try {
        print('SurveyAPI: Refreshing token before submission...');
        await dio.post('/refresh');
        print('SurveyAPI: Token refreshed successfully');
      } catch (e) {
        print('SurveyAPI: Token refresh failed (will retry if needed): $e');
        // Continue anyway - interceptor will handle if token is actually expired
      }
      
      print('Survey data: $surveyData');
      print('Images to upload: ${questionImages?.length ?? 0}');
      
      // Always use FormData to match web implementation
      print('SurveyAPI: Creating FormData...');
      
      // Bundle ALL survey data into ONE JSON string under "surveyData" key
      FormData formData = FormData.fromMap({
        'surveyData': jsonEncode(surveyData),
      });
      
      // Add image files with keys matching imageKey format: "image_{questionId}"
      if (questionImages != null && questionImages.isNotEmpty) {
        for (var entry in questionImages.entries) {
          final questionId = entry.key; // e.g., "question-1763633434439"
          final imageFile = entry.value;
          
          // Add "image_" prefix to match backend expectation: "image_question-123..."
          final imageKey = 'image_$questionId';
          
          print('SurveyAPI: Adding image with key: $imageKey');
          
          formData.files.add(
            MapEntry(
              imageKey,
              await MultipartFile.fromFile(
                imageFile.path,
                filename: imageFile.path.split(Platform.pathSeparator).last,
              ),
            ),
          );
        }
        print('SurveyAPI: FormData prepared with ${questionImages.length} images');
      } else {
        print('SurveyAPI: FormData prepared without images');
      }
      
      final response = await dio.post(
        '/../survey/post/send/questionnaire/mobile',
        data: formData,
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
  /// Backend Response Format:
  /// {
  ///   "message": [...surveys...],
  ///   "ok": true,
  ///   "status": 200
  /// }
  static Future<List<dynamic>> getAllSurveys() async {
    try {
      final dio = await DioClient.instance;
      final response = await dio.get('/../survey/post/get');
      
      print('SurveyAPI getAllSurveys: Response status: ${response.statusCode}');
      print('SurveyAPI getAllSurveys: Response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['ok'] == true) {
        // Backend returns surveys in 'message' field, not 'data'
        final surveys = response.data['message'];
        if (surveys is List) {
          return surveys;
        }
        print('SurveyAPI getAllSurveys: message is not a List: ${surveys.runtimeType}');
        return [];
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
  /// 
  /// Backend Response Format:
  /// {
  ///   "message": {
  ///     "pk_survey_id": 1,
  ///     "survey_title": "...",
  ///     "survey_content": "...",
  ///     "survey_approx_time": "10-15 min",
  ///     "survey_section": [...]
  ///   },
  ///   "ok": true,
  ///   "status": 200
  /// }
  static Future<Map<String, dynamic>> getSurveyQuestionnaire(int postId) async {
    try {
      final dio = await DioClient.instance;
      print('SurveyAPI: Fetching questionnaire for post ID: $postId');
      
      final response = await dio.get('/../survey/post/get/questionnaire/$postId');
      
      print('SurveyAPI: Response status: ${response.statusCode}');
      print('SurveyAPI: Response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['ok'] == true) {
        // The survey data is in response.data['message']
        return {
          'ok': true,
          'survey': response.data['message'],
        };
      }
      
      return {
        'ok': false,
        'message': response.data['message'] ?? 'Failed to fetch questionnaire',
      };
    } on DioException catch (e) {
      print('SurveyAPI: DioException: ${e.message}');
      print('SurveyAPI: Response: ${e.response?.data}');
      
      String errorMessage = 'Network error';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      
      return {
        'ok': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('SurveyAPI: Error fetching questionnaire: $e');
      return {
        'ok': false,
        'message': e.toString(),
      };
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
      
      print('SurveyAPI: Checking if answered for survey_id: $surveyId');
      
      final response = await dio.post(
        '/../survey/questionnaire/is_answered',
        data: {'survey_id': surveyId},
      );
      
      print('SurveyAPI checkIfAnswered: Response status: ${response.statusCode}');
      print('SurveyAPI checkIfAnswered: Response data: ${response.data}');
      
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
      print('SurveyAPI checkIfAnswered: DioException: ${e.response?.statusCode} - ${e.response?.data}');
      
      if (e.response?.statusCode == 409) {
        return {
          'ok': true,
          'alreadyAnswered': true,
          'message': e.response?.data['message'] ?? 'You have already answered this survey',
        };
      }
      
      // Handle 404 - survey doesn't exist in backend (e.g., local survey)
      if (e.response?.statusCode == 404) {
        print('SurveyAPI checkIfAnswered: Survey $surveyId not found in backend');
        return {
          'ok': false,
          'error': 'not_found',
          'message': 'Survey not found',
        };
      }
      
      return {
        'ok': false,
        'message': e.response?.data['message'] ?? 'Network error',
      };
    } catch (e) {
      print('SurveyAPI checkIfAnswered: Error: $e');
      return {
        'ok': false,
        'message': e.toString(),
      };
    }
  }
}
