import 'package:flutter/material.dart';
import 'package:inquira/widgets/custom_choice_chip.dart';
import 'package:inquira/widgets/survey_card.dart';
import 'package:inquira/data/survey_service.dart';
import 'package:inquira/data/api/survey_api.dart';
import 'package:inquira/models/survey.dart';

class HomeFeed extends StatefulWidget {
  const HomeFeed({super.key});

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  String selectedFilter = "All";
  List<Survey> _allSurveys = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSurveys();
  }

  Future<void> _loadSurveys() async {
    setState(() => _isLoading = true);
    
    try {
      // Try to fetch surveys from backend first
      List<Survey> backendSurveys = [];
      try {
        final backendData = await SurveyAPI.getAllSurveys();
        backendSurveys = backendData.map((json) => _parseSurveyFromBackend(json)).toList();
        print('HomeFeed: Loaded ${backendSurveys.length} surveys from backend');
      } catch (e) {
        print('HomeFeed: Could not fetch from backend: $e');
      }
      
      // Also load local surveys
      final localSurveys = await SurveyService.getAllSurveys();
      
      // Combine: backend surveys first, then local surveys (avoiding duplicates)
      final allSurveys = [...backendSurveys];
      for (var local in localSurveys) {
        if (!allSurveys.any((s) => s.id == local.id)) {
          allSurveys.add(local);
        }
      }
      
      setState(() {
        _allSurveys = allSurveys;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading surveys: $e');
      setState(() {
        _allSurveys = [];
        _isLoading = false;
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
