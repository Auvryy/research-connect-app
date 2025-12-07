import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/data/api/survey_api.dart';
import 'package:inquira/models/survey.dart';
import 'package:inquira/widgets/profile_survey.dart';

class LikedSurveysPage extends StatefulWidget {
  final List<Survey> initialSurveys;
  const LikedSurveysPage({super.key, this.initialSurveys = const []});

  @override
  State<LikedSurveysPage> createState() => _LikedSurveysPageState();
}

class _LikedSurveysPageState extends State<LikedSurveysPage> {
  bool _isLoading = true;
  String? _error;
  List<Survey> _surveys = [];

  @override
  void initState() {
    super.initState();
    _surveys = List<Survey>.from(widget.initialSurveys);
    _isLoading = _surveys.isEmpty;
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await SurveyAPI.getLikedSurveys();
      if (res['ok'] == true) {
        final list = (res['surveys'] as List)
            .map((json) => _parseSurvey(json as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() {
            _surveys = list;
            _isLoading = false;
            _error = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = res['message']?.toString();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Liked Posts', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _surveys.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _surveys.length,
                        itemBuilder: (context, index) {
                          final survey = _surveys[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ProfileSurvey(survey: survey),
                          );
                        },
                      ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Icon(Icons.favorite_border, size: 80, color: Colors.grey),
        SizedBox(height: 12),
        Center(child: Text('No liked posts yet', style: TextStyle(fontSize: 16))),
        SizedBox(height: 4),
        Center(child: Text('Tap the heart on surveys to save them here', style: TextStyle(color: Colors.grey))),
      ],
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
        const SizedBox(height: 16),
        Text(
          'Failed to load liked posts',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade700),
        ),
        const SizedBox(height: 8),
        if (_error != null)
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        ),
      ],
    );
  }

  Survey _parseSurvey(Map<String, dynamic> json) {
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
    final isLiked = json['is_liked'] as bool? ?? true; // from liked list

    final approved = (json['approved`'] as bool?) ?? (json['approved'] as bool?) ?? false;
    final archived = json['archived'] as bool? ?? false;
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
      questions: const [],
    );
  }

  int _parseTimeToComplete(dynamic approxTime) {
    if (approxTime == null) return 5;
    if (approxTime is int) return approxTime;
    if (approxTime is String) {
      final parsed = int.tryParse(approxTime);
      return parsed ?? 5;
    }
    return 5;
  }

  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return DateTime.now();
    }
  }
}
