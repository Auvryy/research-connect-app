import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/data/api/survey_api.dart';
import 'package:inquira/models/survey.dart';

class ArchivedSurveysPage extends StatefulWidget {
  const ArchivedSurveysPage({super.key});

  @override
  State<ArchivedSurveysPage> createState() => _ArchivedSurveysPageState();
}

class _ArchivedSurveysPageState extends State<ArchivedSurveysPage> {
  List<Survey> _archivedSurveys = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadArchivedSurveys();
  }

  Future<void> _loadArchivedSurveys() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await SurveyAPI.getArchivedSurveys();
      
      if (response['ok'] == true) {
        final surveys = (response['surveys'] as List)
            .map((json) => _parseSurveyFromBackend(json as Map<String, dynamic>))
            .toList();
        
        if (mounted) {
          setState(() {
            _archivedSurveys = surveys;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response['message'] ?? 'Failed to load archived surveys';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('ArchivedSurveysPage: Error loading surveys: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Survey _parseSurveyFromBackend(Map<String, dynamic> json) {
    String targetAudience = '';
    if (json['survey_target_audience'] is List) {
      targetAudience = (json['survey_target_audience'] as List).join(', ');
    } else if (json['survey_target_audience'] is String) {
      targetAudience = json['survey_target_audience'] as String;
    }

    List<String> tags = [];
    if (json['survey_category'] != null) {
      if (json['survey_category'] is List) {
        tags = List<String>.from(json['survey_category']);
      } else if (json['survey_category'] is String) {
        tags = [json['survey_category'] as String];
      }
    }

    final caption = json['survey_content'] as String? ?? '';
    bool isOpen = true;
    if (json['status'] != null) {
      isOpen = json['status'].toString().toLowerCase() == 'open';
    } else if (json['survey_status'] != null) {
      isOpen = json['survey_status'].toString().toLowerCase() == 'open';
    }

    final numOfResponses = json['num_of_responses'] as int? ?? 0;
    final numOfLikes = json['num_of_likes'] as int? ?? 0;
    final isLiked = json['is_liked'] as bool? ?? false;

    // Parse approved and archived flags (archived surveys are always archived=true)
    // Backend has a typo: uses 'approved`' (with backtick) instead of 'approved'
    final approved = (json['approved`'] as bool?) ?? (json['approved'] as bool?) ?? false;
    final archived = json['archived'] as bool? ?? true; // Default true for this page
    
    // Parse creator profile URL
    final creatorProfileUrl = json['user_profile'] as String?;

    return Survey(
      id: json['pk_survey_id']?.toString() ?? '',
      postId: json['pk_survey_id'] as int?,
      title: json['survey_title'] ?? 'Untitled Survey',
      caption: caption,
      description: '',
      timeToComplete: _parseTimeToComplete(json['approx_time']),
      tags: tags,
      targetAudience: targetAudience,
      creator: json['user_username'] ?? 'Unknown',
      creatorProfileUrl: creatorProfileUrl,
      createdAt: _parseDateTime(json['survey_date_created']),
      status: isOpen,
      approved: approved,
      archived: archived,
      responses: numOfResponses,
      numOfLikes: numOfLikes,
      isLiked: isLiked,
      questions: [],
    );
  }

  DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    if (dateValue is String) return DateTime.tryParse(dateValue) ?? DateTime.now();
    return DateTime.now();
  }

  int _parseTimeToComplete(String? approxTime) {
    if (approxTime == null) return 5;
    final match = RegExp(r'(\d+)').firstMatch(approxTime);
    return match != null ? int.tryParse(match.group(1)!) ?? 5 : 5;
  }

  Future<void> _unarchiveSurvey(Survey survey) async {
    if (survey.postId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unarchive Survey'),
        content: const Text(
          'Are you sure you want to unarchive this survey? It will be restored to the public feed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Unarchive', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await SurveyAPI.unarchiveSurvey(survey.postId!);

      if (mounted) {
        if (response['ok'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Survey unarchived successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Remove from local list
          setState(() {
            _archivedSurveys.removeWhere((s) => s.postId == survey.postId);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to unarchive survey'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Surveys'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load archived surveys',
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
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadArchivedSurveys,
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
              : _archivedSurveys.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.archive_outlined, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No archived surveys',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Surveys you archive will appear here',
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadArchivedSurveys,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _archivedSurveys.length,
                        itemBuilder: (context, index) {
                          final survey = _archivedSurveys[index];
                          return _ArchivedSurveyCard(
                            survey: survey,
                            onUnarchive: () => _unarchiveSurvey(survey),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _ArchivedSurveyCard extends StatelessWidget {
  final Survey survey;
  final VoidCallback onUnarchive;

  const _ArchivedSurveyCard({
    required this.survey,
    required this.onUnarchive,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yMMMd').format(survey.createdAt);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row with Unarchive Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    survey.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onUnarchive,
                  icon: const Icon(Icons.unarchive, color: AppColors.primary, size: 20),
                  tooltip: "Unarchive Survey",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Responses + Date
            Row(
              children: [
                const Icon(Icons.people, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  '${survey.responses} Responses',
                  style: const TextStyle(fontSize: 13, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.calendar_month, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 13, color: AppColors.primary),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tags
            if (survey.tags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: survey.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary2,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 12),

            // Archived Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.archive, size: 14, color: Colors.orange.shade800),
                  const SizedBox(width: 4),
                  Text(
                    'Archived',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
