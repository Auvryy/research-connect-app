import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/screens/survey/edit_survey_page.dart';
import 'package:inquira/screens/survey/survey_responses_page.dart';
import 'package:inquira/data/api/survey_api.dart';
import '../models/survey.dart';

class ProfileSurvey extends StatefulWidget {
  final Survey survey;
  final int responses; // later you can connect this dynamically
  final VoidCallback? onSurveyUpdated; // Callback when survey is edited (triggers full reload)
  final void Function(int surveyId, String newStatus)? onStatusChanged; // Callback for status-only changes
  final void Function(int surveyId)? onSurveyArchived; // Callback when survey is archived

  const ProfileSurvey({
    Key? key,
    required this.survey,
    this.responses = 0,
    this.onSurveyUpdated,
    this.onStatusChanged,
    this.onSurveyArchived,
  }) : super(key: key);

  @override
  State<ProfileSurvey> createState() => _ProfileSurveyState();
}

class _ProfileSurveyState extends State<ProfileSurvey> {
  bool _isArchiving = false;
  late bool _currentStatus; // Track status locally

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.survey.status;
  }

  @override
  void didUpdateWidget(ProfileSurvey oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local status if widget changes
    if (oldWidget.survey.status != widget.survey.status) {
      _currentStatus = widget.survey.status;
    }
  }

  Future<void> _archiveSurvey() async {
    if (widget.survey.postId == null) return;

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Survey'),
        content: const Text(
          'Are you sure you want to archive this survey? It will be removed from the public feed and no longer accept responses.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Archive', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isArchiving = true);

    try {
      final response = await SurveyAPI.archiveSurvey(widget.survey.postId!);

      if (mounted) {
        if (response['ok'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Survey archived successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Remove the survey from the local list immediately
          if (widget.onSurveyArchived != null) {
            widget.onSurveyArchived!(widget.survey.postId!);
          } else if (widget.onSurveyUpdated != null) {
            // Fallback to full reload if no archive callback
            widget.onSurveyUpdated!();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to archive survey'),
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
    } finally {
      if (mounted) {
        setState(() => _isArchiving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yMMMd').format(widget.survey.createdAt);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 3),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row with Edit and Archive Buttons
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.survey.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Edit Button
                if (widget.survey.postId != null)
                  IconButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditSurveyPage(survey: widget.survey),
                        ),
                      );
                      // Handle the returned data
                      if (result != null && result is Map) {
                        if (result['updated'] == true) {
                          // Update local status immediately for better UX
                          if (result['status'] != null) {
                            final newStatus = result['status'] as String;
                            setState(() {
                              _currentStatus = newStatus == 'open';
                            });
                            // Notify parent of status change without full reload
                            if (widget.onStatusChanged != null && widget.survey.postId != null) {
                              widget.onStatusChanged!(widget.survey.postId!, newStatus);
                            }
                          }
                          // Only trigger full refresh if other fields changed (title, caption, etc.)
                          // The status is already handled above
                          if (result['needsRefresh'] == true && widget.onSurveyUpdated != null) {
                            widget.onSurveyUpdated!();
                          }
                        }
                      } else if (result == true && widget.onSurveyUpdated != null) {
                        // Legacy support for old return type
                        widget.onSurveyUpdated!();
                      }
                    },
                    icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                    tooltip: "Edit Survey",
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const SizedBox(width: 8),
                // Archive Button
                if (widget.survey.postId != null)
                  _isArchiving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          onPressed: _archiveSurvey,
                          icon: const Icon(Icons.archive, color: Colors.orange, size: 20),
                          tooltip: "Archive Survey",
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
                  widget.survey.responses.toString() + " Responses",
                  style: const TextStyle(fontSize: 13, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.calendar_month,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 13, color: AppColors.primary),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Status + Summary Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status Badges Row
                Row(
                  children: [
                    // Approval Status Badge (Pending/Approved)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.survey.approved
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.survey.approved ? Icons.verified : Icons.pending,
                            size: 14,
                            color: widget.survey.approved
                                ? Colors.green.shade800
                                : Colors.orange.shade800,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.survey.approved ? "Approved" : "Pending",
                            style: TextStyle(
                              color: widget.survey.approved
                                  ? Colors.green.shade800
                                  : Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Open/Closed Status Badge
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _currentStatus
                            ? Colors.blue.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _currentStatus ? "Open" : "Closed",
                        style: TextStyle(
                          color:
                              _currentStatus ? Colors.blue.shade800 : Colors.red[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                // Summary Button - Navigate to Analytics
                IconButton(
                  onPressed: widget.survey.postId != null
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SurveyResponsesPage(
                                surveyId: widget.survey.postId!,
                                surveyTitle: widget.survey.title,
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: Icon(
                    Icons.bar_chart,
                    color: widget.survey.postId != null ? AppColors.primary : Colors.grey,
                  ),
                  tooltip: "View Analytics",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
