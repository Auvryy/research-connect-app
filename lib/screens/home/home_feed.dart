import 'package:flutter/material.dart';
import 'package:inquira/widgets/custom_choice_chip.dart';
import 'package:inquira/widgets/survey_card.dart';
import 'package:inquira/data/api/survey_api.dart';
import 'package:inquira/models/survey.dart';
import 'package:inquira/constants/colors.dart';

class HomeFeed extends StatefulWidget {
  const HomeFeed({super.key});

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  String selectedFilter = "All";
  List<Survey> _allSurveys = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSurveys();
  }

  Future<void> _loadSurveys() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Fetch surveys from backend ONLY - no local storage
      print('HomeFeed: Fetching surveys from backend...');
      final backendData = await SurveyAPI.getAllSurveys();
      
      final surveys = backendData.map((json) => _parseSurveyFromBackend(json)).toList();
      print('HomeFeed: Loaded ${surveys.length} surveys from backend');
      
      setState(() {
        _allSurveys = surveys;
        _isLoading = false;
      });
    } catch (e) {
      print('HomeFeed: Error fetching surveys: $e');
      setState(() {
        _allSurveys = [];
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  /// Parse survey from backend JSON format to Survey model
  /// Backend returns: pk_survey_id, survey_title, survey_content, survey_category,
  /// survey_target_audience, survey_date_created, user_username, user_profile
  Survey _parseSurveyFromBackend(Map<String, dynamic> json) {
    // Handle target_audience which can be a list or string
    String targetAudience = '';
    if (json['survey_target_audience'] is List) {
      targetAudience = (json['survey_target_audience'] as List).join(', ');
    } else if (json['survey_target_audience'] is String) {
      targetAudience = json['survey_target_audience'] as String;
    }

    // Handle category/tags
    List<String> tags = [];
    if (json['survey_category'] != null) {
      if (json['survey_category'] is List) {
        tags = List<String>.from(json['survey_category']);
      } else if (json['survey_category'] is String) {
        tags = [json['survey_category'] as String];
      }
    }

    return Survey(
      id: json['pk_survey_id']?.toString() ?? '',
      postId: json['pk_survey_id'] as int?,
      title: json['survey_title'] ?? 'Untitled Survey',
      caption: '',
      description: json['survey_content'] ?? '',
      timeToComplete: _parseTimeToComplete(json['survey_approx_time']),
      tags: tags,
      targetAudience: targetAudience,
      creator: json['user_username'] ?? 'Unknown',
      createdAt: _parseDateTime(json['survey_date_created']),
      status: true,
      responses: 0,
      questions: [], // Questions are loaded separately when taking the survey
    );
  }

  DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    if (dateValue is String) {
      return DateTime.tryParse(dateValue) ?? DateTime.now();
    }
    return DateTime.now();
  }

  int _parseTimeToComplete(String? approxTime) {
    if (approxTime == null) return 5;
    // Parse strings like "10-15 min" to get the first number
    final match = RegExp(r'(\d+)').firstMatch(approxTime);
    return match != null ? int.tryParse(match.group(1)!) ?? 5 : 5;
  }

  @override
  Widget build(BuildContext context) {
    // Filtered list based on selectedFilter
    final filteredSurveys = selectedFilter == "All"
        ? _allSurveys 
        : _allSurveys.where((s) => s.tags.contains(selectedFilter)).toList();

    return Column(
      children: [
        const SizedBox(height: 10),

        // Filter section
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 10),
              CustomChoiceChip(
                label: "All",
                selected: selectedFilter == "All",
                onSelected: (selected) {
                  if (selected) setState(() => selectedFilter = "All");
                },
              ),
              const SizedBox(width: 8),
              CustomChoiceChip(
                label: "Business",
                selected: selectedFilter == "Business",
                onSelected: (selected) {
                  if (selected) setState(() => selectedFilter = "Business");
                },
              ),
              const SizedBox(width: 8),
              CustomChoiceChip(
                label: "Technology",
                selected: selectedFilter == "Technology",
                onSelected: (selected) {
                  if (selected) setState(() => selectedFilter = "Technology");
                },
              ),
              const SizedBox(width: 8),
              CustomChoiceChip(
                label: "Humanities",
                selected: selectedFilter == "Humanities",
                onSelected: (selected) {
                  if (selected) setState(() => selectedFilter = "Humanities");
                },
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Feed list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load surveys',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _loadSurveys,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : filteredSurveys.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.poll_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No surveys yet',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create your first survey!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _loadSurveys,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadSurveys,
                          child: ListView.builder(
                        itemCount: filteredSurveys.length,
                        itemBuilder: (context, index) {
                          final survey = filteredSurveys[index];
                          return SurveyCard(survey: survey);
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
