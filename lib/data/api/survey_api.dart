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

  /// Get all surveys with pagination support
  /// GET /api/survey/post/get?page=1&per_page=5&category=Technology
  /// Backend Response Format:
  /// {
  ///   "message": [...surveys...],
  ///   "ok": true,
  ///   "status": 200
  /// }
  static Future<List<dynamic>> getAllSurveys({int page = 1, int perPage = 5, String? category}) async {
    try {
      final dio = await DioClient.instance;
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (category != null && category != 'All') {
        queryParams['category'] = category;
      }
      final response = await dio.get(
        '/../survey/post/get',
        queryParameters: queryParams,
      );
      
      print('SurveyAPI getAllSurveys: page=$page, perPage=$perPage');
      print('SurveyAPI getAllSurveys: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['ok'] == true) {
        // Backend returns surveys in 'message' field, not 'data'
        final surveys = response.data['message'];
        if (surveys is List) {
          print('SurveyAPI getAllSurveys: Got ${surveys.length} surveys');
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

  /// Update survey data
  /// PATCH /api/survey/post/update_data
  /// 
  /// Backend accepts:
  /// - id: post id (required)
  /// - title: survey title (optional)
  /// - post_content: post/caption content (optional)
  /// - survey_description: survey description (optional)  
  /// - status: "open" or "closed" (optional)
  static Future<Map<String, dynamic>> updateSurvey({
    required int surveyId,
    String? title,
    String? postContent,
    String? surveyDescription,
    String? status,
  }) async {
    try {
      final dio = await DioClient.instance;
      
      print('SurveyAPI: Updating survey ID: $surveyId');
      
      final Map<String, dynamic> data = {
        'id': surveyId,
      };
      
      if (title != null) data['title'] = title;
      if (postContent != null) data['post_content'] = postContent;
      if (surveyDescription != null) data['survey_description'] = surveyDescription;
      if (status != null) data['status'] = status;
      
      print('SurveyAPI: Update data: $data');
      
      final response = await dio.patch(
        '/../survey/post/update_data',
        data: data,
      );
      
      print('SurveyAPI: Update response status: ${response.statusCode}');
      print('SurveyAPI: Update response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['ok'] == true) {
        return {
          'ok': true,
          'message': response.data['message'] ?? 'Survey updated successfully',
        };
      }
      
      return {
        'ok': false,
        'message': response.data['message'] ?? 'Failed to update survey',
      };
    } on DioException catch (e) {
      print('SurveyAPI updateSurvey: DioException: ${e.message}');
      print('SurveyAPI updateSurvey: Response: ${e.response?.data}');
      
      String errorMessage = 'Failed to update survey';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      
      return {
        'ok': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('SurveyAPI updateSurvey: Error: $e');
      return {
        'ok': false,
        'message': e.toString(),
      };
    }
  }

  /// Archive a survey (removes from public feed)
  /// PATCH /api/survey/post/archive
  /// 
  /// Backend expects: {"id": postId}
  static Future<Map<String, dynamic>> archiveSurvey(int postId) async {
    try {
      final dio = await DioClient.instance;
      
      print('SurveyAPI: Archiving survey ID: $postId');
      
      final response = await dio.patch(
        '/../survey/post/archive',
        data: {'id': postId},
      );
      
      print('SurveyAPI archiveSurvey: Response status: ${response.statusCode}');
      print('SurveyAPI archiveSurvey: Response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['ok'] == true) {
        return {
          'ok': true,
          'message': response.data['message'] ?? 'Survey archived successfully',
        };
      }
      
      return {
        'ok': false,
        'message': response.data['message'] ?? 'Failed to archive survey',
      };
    } on DioException catch (e) {
      print('SurveyAPI archiveSurvey: DioException: ${e.message}');
      print('SurveyAPI archiveSurvey: Response: ${e.response?.data}');
      
      String errorMessage = 'Failed to archive survey';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      
      return {
        'ok': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('SurveyAPI archiveSurvey: Error: $e');
      return {
        'ok': false,
        'message': e.toString(),
      };
    }
  }

  /// Get survey responses/analytics data
  /// GET /api/survey/post/respones/computed_data/<survey_id>
  /// Note: Backend has typo "respones" instead of "responses"
  /// 
  /// Returns computed analytics data for a survey including:
  /// - survey_title, survey_content, survey_tags, etc.
  /// - _total_peeps_who_answered: total number of respondents
  /// - choices_data: aggregated data for choice questions
  /// - dates_data: aggregated data for date questions
  /// - rating_data: aggregated data for rating questions
  /// - text_data: all text responses
  static Future<Map<String, dynamic>> getSurveyResponses(int surveyId) async {
    try {
      final dio = await DioClient.instance;
      
      print('SurveyAPI: Fetching survey responses for survey ID: $surveyId');
      
      final response = await dio.get('/../survey/post/respones/computed_data/$surveyId');
      
      print('SurveyAPI getSurveyResponses: Response status: ${response.statusCode}');
      print('SurveyAPI getSurveyResponses: Response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['ok'] == true) {
        return {
          'ok': true,
          'data': response.data['message'],
        };
      }
      
      return {
        'ok': false,
        'message': response.data['message'] ?? 'Failed to fetch survey responses',
      };
    } on DioException catch (e) {
      print('SurveyAPI getSurveyResponses: DioException: ${e.message}');
      print('SurveyAPI getSurveyResponses: Response: ${e.response?.data}');
      
      String errorMessage = 'Failed to fetch survey responses';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      
      return {
        'ok': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('SurveyAPI getSurveyResponses: Error: $e');
      return {
        'ok': false,
        'message': e.toString(),
      };
    }
  }

  /// Unarchive a survey (restore to public feed)
  /// PATCH /api/survey/post/unarchive
  /// 
  /// Backend expects: {"id": postId}
  static Future<Map<String, dynamic>> unarchiveSurvey(int postId) async {
    try {
      final dio = await DioClient.instance;
      
      print('SurveyAPI: Unarchiving survey ID: $postId');
      
      final response = await dio.patch(
        '/../survey/post/unarchive',
        data: {'id': postId},
      );
      
      print('SurveyAPI unarchiveSurvey: Response status: ${response.statusCode}');
      print('SurveyAPI unarchiveSurvey: Response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['ok'] == true) {
        return {
          'ok': true,
          'message': response.data['message'] ?? 'Survey unarchived successfully',
        };
      }
      
      return {
        'ok': false,
        'message': response.data['message'] ?? 'Failed to unarchive survey',
      };
    } on DioException catch (e) {
      print('SurveyAPI unarchiveSurvey: DioException: ${e.message}');
      print('SurveyAPI unarchiveSurvey: Response: ${e.response?.data}');
      
      String errorMessage = 'Failed to unarchive survey';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      
      return {
        'ok': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('SurveyAPI unarchiveSurvey: Error: $e');
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

  /// Like or unlike a survey (toggle)
  /// POST /api/survey/post/like
  /// 
  /// Backend expects: {"post_id": postId}
  /// Returns: {"ok": true, "message": "Post liked/unliked successfully"}
  static Future<Map<String, dynamic>> likeSurvey(int postId) async {
    try {
      final dio = await DioClient.instance;
      
      print('SurveyAPI: Toggling like for post ID: $postId');
      
      final response = await dio.post(
        '/../survey/post/like',
        data: {'post_id': postId}, // Backend expects 'post_id' not 'id'
      );
      
      print('SurveyAPI likeSurvey: Response status: ${response.statusCode}');
      print('SurveyAPI likeSurvey: Response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['ok'] == true) {
        return {
          'ok': true,
          'message': response.data['message'] ?? 'Like toggled successfully',
        };
      }
      
      return {
        'ok': false,
        'message': response.data['message'] ?? 'Failed to toggle like',
      };
    } on DioException catch (e) {
      print('SurveyAPI likeSurvey: DioException: ${e.message}');
      print('SurveyAPI likeSurvey: Response: ${e.response?.data}');
      
      String errorMessage = 'Failed to toggle like';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      
      return {
        'ok': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('SurveyAPI likeSurvey: Error: $e');
      return {
        'ok': false,
        'message': e.toString(),
      };
    }
  }

  /// Search surveys by keyword (searches title, category, audience, content)
  /// GET /api/survey/post/search?query=<query>&order=<desc|asc>
  static Future<Map<String, dynamic>> searchSurveys({
    required String query,
    String order = 'desc',
  }) async {
    try {
      final dio = await DioClient.instance;
      
      print('SurveyAPI: Searching surveys with query: $query');
      
      final response = await dio.get(
        '/../survey/post/search',
        queryParameters: {
          'query': query, // Backend uses 'query' not 'search'
          'order': order,
        },
      );
      
      print('SurveyAPI searchSurveys: Response status: ${response.statusCode}');
      print('SurveyAPI searchSurveys: Response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['ok'] == true) {
        // Backend returns matching posts - return them directly
        final surveys = response.data['message'] as List? ?? [];
        
        return {
          'ok': true,
          'surveys': surveys,
        };
      }
      
      // Handle 404 as empty results (not an error)
      if (response.statusCode == 404) {
        return {
          'ok': true,
          'surveys': [],
        };
      }
      
      return {
        'ok': false,
        'message': response.data['message'] ?? 'Failed to search surveys',
      };
    } on DioException catch (e) {
      print('SurveyAPI searchSurveys: DioException: ${e.message}');
      
      // Handle 404 as empty results
      if (e.response?.statusCode == 404) {
        return {
          'ok': true,
          'surveys': [],
        };
      }
      
      String errorMessage = 'Failed to search surveys';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      
      return {
        'ok': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('SurveyAPI searchSurveys: Error: $e');
      return {
        'ok': false,
        'message': e.toString(),
      };
    }
  }

  /// Search surveys by tags and/or audience
  /// GET /api/survey/post/search/tags?category=<tag>&target_audience=<audience>
  static Future<Map<String, dynamic>> searchByTags({
    String? category,
    String? targetAudience,
  }) async {
    try {
      final dio = await DioClient.instance;
      
      print('SurveyAPI: Searching by tags - category: $category, audience: $targetAudience');
      
      final Map<String, dynamic> queryParams = {};
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (targetAudience != null && targetAudience.isNotEmpty) {
        queryParams['target_audience'] = targetAudience;
      }
      
      final response = await dio.get(
        '/../survey/post/search/tags',
        queryParameters: queryParams,
      );
      
      print('SurveyAPI searchByTags: Response status: ${response.statusCode}');
      print('SurveyAPI searchByTags: Response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['ok'] == true) {
        return {
          'ok': true,
          'surveys': response.data['message'] ?? [],
        };
      }
      
      return {
        'ok': false,
        'message': response.data['message'] ?? 'Failed to search by tags',
      };
    } on DioException catch (e) {
      print('SurveyAPI searchByTags: DioException: ${e.message}');
      
      String errorMessage = 'Failed to search by tags';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      
      return {
        'ok': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('SurveyAPI searchByTags: Error: $e');
      return {
        'ok': false,
        'message': e.toString(),
      };
    }
  }

  /// Search surveys by title only
  /// GET /api/survey/post/search/title?title=<title>
  static Future<Map<String, dynamic>> searchByTitle(String title) async {
    try {
      final dio = await DioClient.instance;
      
      print('SurveyAPI: Searching by title: $title');
      
      final response = await dio.get(
        '/../survey/post/search/title',
        queryParameters: {'title': title},
      );
      
      print('SurveyAPI searchByTitle: Response status: ${response.statusCode}');
      print('SurveyAPI searchByTitle: Response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['ok'] == true) {
        return {
          'ok': true,
          'surveys': response.data['message'] ?? [],
        };
      }
      
      return {
        'ok': false,
        'message': response.data['message'] ?? 'Failed to search by title',
      };
    } on DioException catch (e) {
      print('SurveyAPI searchByTitle: DioException: ${e.message}');
      
      String errorMessage = 'Failed to search by title';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      
      return {
        'ok': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('SurveyAPI searchByTitle: Error: $e');
      return {
        'ok': false,
        'message': e.toString(),
      };
    }
  }

  /// Get user's archived surveys
  /// GET /api/auth/post/archived
  static Future<Map<String, dynamic>> getArchivedSurveys() async {
    try {
      final dio = await DioClient.instance;
      
      print('SurveyAPI: Fetching archived surveys...');
      
      final response = await dio.get('/post/archived');
      
      print('SurveyAPI getArchivedSurveys: Response status: ${response.statusCode}');
      print('SurveyAPI getArchivedSurveys: Response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['ok'] == true) {
        return {
          'ok': true,
          'surveys': response.data['message'] ?? [],
        };
      }
      
      return {
        'ok': false,
        'message': response.data['message'] ?? 'Failed to fetch archived surveys',
      };
    } on DioException catch (e) {
      print('SurveyAPI getArchivedSurveys: DioException: ${e.message}');
      
      String errorMessage = 'Failed to fetch archived surveys';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      
      return {
        'ok': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('SurveyAPI getArchivedSurveys: Error: $e');
      return {
        'ok': false,
        'message': e.toString(),
      };
    }
  }

  /// Get user's rejected surveys
  /// GET /api/auth/post/rejected
  static Future<Map<String, dynamic>> getRejectedSurveys() async {
    try {
      final dio = await DioClient.instance;
      
      print('SurveyAPI: Fetching rejected surveys...');
      
      final response = await dio.get('/post/rejected');
      
      print('SurveyAPI getRejectedSurveys: Response status: ${response.statusCode}');
      print('SurveyAPI getRejectedSurveys: Response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['ok'] == true) {
        return {
          'ok': true,
          'surveys': response.data['message'] ?? [],
        };
      }
      
      return {
        'ok': false,
        'message': response.data['message'] ?? 'Failed to fetch rejected surveys',
      };
    } on DioException catch (e) {
      print('SurveyAPI getRejectedSurveys: DioException: ${e.message}');
      
      String errorMessage = 'Failed to fetch rejected surveys';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      
      return {
        'ok': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('SurveyAPI getRejectedSurveys: Error: $e');
      return {
        'ok': false,
        'message': e.toString(),
      };
    }
  }

  /// Get user's liked surveys
  /// GET /api/user/post/liked
  static Future<Map<String, dynamic>> getLikedSurveys() async {
    try {
      final dio = await DioClient.instance;
      
      print('SurveyAPI: Fetching liked surveys...');
      
      final response = await dio.get('/post/liked');
      
      print('SurveyAPI getLikedSurveys: Response status: ${response.statusCode}');
      print('SurveyAPI getLikedSurveys: Response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['ok'] == true) {
        return {
          'ok': true,
          'surveys': response.data['message'] ?? [],
        };
      }
      
      return {
        'ok': false,
        'message': response.data['message'] ?? 'Failed to fetch liked surveys',
      };
    } on DioException catch (e) {
      print('SurveyAPI getLikedSurveys: DioException: ${e.message}');
      
      String errorMessage = 'Failed to fetch liked surveys';
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      
      return {
        'ok': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('SurveyAPI getLikedSurveys: Error: $e');
      return {
        'ok': false,
        'message': e.toString(),
      };
    }
  }
}
