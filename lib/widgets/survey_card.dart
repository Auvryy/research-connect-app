import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/data/api/survey_api.dart';
import '../models/survey.dart';

class SurveyCard extends StatefulWidget {
  final Survey survey;
  final VoidCallback? onLikeChanged; // Optional callback when like status changes

  const SurveyCard({Key? key, required this.survey, this.onLikeChanged}) : super(key: key);

  @override
  _SurveyCardState createState() => _SurveyCardState();
}

class _SurveyCardState extends State<SurveyCard> {
  bool _isExpanded = false;
  bool _isLiking = false;
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.survey.isLiked;
    _likeCount = widget.survey.numOfLikes;
  }

  @override
  void didUpdateWidget(SurveyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.survey.postId != widget.survey.postId) {
      _isLiked = widget.survey.isLiked;
      _likeCount = widget.survey.numOfLikes;
    }
  }

  Future<void> _toggleLike() async {
    if (_isLiking || widget.survey.postId == null) return;

    setState(() => _isLiking = true);

    // Optimistic update
    final previousLiked = _isLiked;
    final previousCount = _likeCount;
    setState(() {
      _isLiked = !_isLiked;
      _likeCount = _isLiked ? _likeCount + 1 : (_likeCount > 0 ? _likeCount - 1 : 0);
    });

    try {
      final response = await SurveyAPI.likeSurvey(widget.survey.postId!);
      
      if (response['ok'] != true) {
        // Revert on failure
        setState(() {
          _isLiked = previousLiked;
          _likeCount = previousCount;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to update like'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Update the survey model
        widget.survey.isLiked = _isLiked;
        widget.survey.numOfLikes = _likeCount;
        widget.onLikeChanged?.call();
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _isLiked = previousLiked;
        _likeCount = previousCount;
      });
    } finally {
      if (mounted) {
        setState(() => _isLiking = false);
      }
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  bool _shouldTruncateAudience(String audience) {
    if (audience.trim().isEmpty) {
      return false;
    }
    final parts = audience.split(',');
    if (parts.length > 1) {
      return true;
    }
    return audience.trim().length > 24;
  }

  String _buildAudienceText(String audience) {
    final trimmed = audience.trim();
    if (_isExpanded || !_shouldTruncateAudience(trimmed)) {
      return trimmed;
    }
    final parts = trimmed.split(',');
    if (parts.isNotEmpty) {
      final first = parts.first.trim();
      if (parts.length > 1) {
        return '$first...';
      }
      if (first.length <= 24) {
        return '$first...';
      }
      return '${first.substring(0, 24)}...';
    }
    return trimmed.length <= 24 ? trimmed : '${trimmed.substring(0, 24)}...';
  }

  @override
  Widget build(BuildContext context) {
    final survey = widget.survey;
    final captionText = survey.caption.trim();
    final hasCaption = captionText.isNotEmpty;
    final shouldTruncateAudience = _shouldTruncateAudience(survey.targetAudience);
    final isExpandable = hasCaption || shouldTruncateAudience;

    return GestureDetector(
      onTap: isExpandable ? _toggleExpanded : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER: Avatar + Author Info
              Row(
                children: [
                  // Avatar - Show profile picture or fallback to initials
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryText,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: survey.creatorProfileUrl != null && survey.creatorProfileUrl!.isNotEmpty
                          ? Image.network(
                              survey.creatorProfileUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback to initials if image fails to load
                                return Center(
                                  child: Text(
                                    survey.creator.isNotEmpty 
                                        ? survey.creator.length >= 2 
                                            ? survey.creator.substring(0, 2).toUpperCase()
                                            : survey.creator[0].toUpperCase()
                                        : 'MC',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Text(
                                survey.creator.isNotEmpty 
                                    ? survey.creator.length >= 2 
                                        ? survey.creator.substring(0, 2).toUpperCase()
                                        : survey.creator[0].toUpperCase()
                                    : 'MC',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Author name and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          survey.creator,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Posted a survey',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.shadedPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: survey.status ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      survey.status ? 'Open' : 'Closed',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: survey.status ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // TITLE
              Text(
                survey.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // TAGS
              if (survey.tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: survey.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
              
              // METADATA ROW (Target Audience + Time)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.people_outline,
                      size: 16,
                      color: AppColors.shadedPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _buildAudienceText(survey.targetAudience),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.shadedPrimary,
                      ),
                      maxLines: _isExpanded ? null : 1,
                      overflow: _isExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.shadedPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${survey.timeToComplete} min',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.shadedPrimary,
                    ),
                  ),
                ],
              ),
              
              // EXPANDED CAPTION (only when expanded)
              if (_isExpanded && hasCaption) ...[
                const SizedBox(height: 12),
                Divider(
                  height: 24,
                  thickness: 1,
                  color: Colors.grey.shade200,
                ),
                const SizedBox(height: 4),
                Text(
                  captionText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryText,
                    height: 1.5,
                  ),
                ),
              ],
              
              // SHOW MORE/LESS BUTTON
              if (isExpandable) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _toggleExpanded,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text(
                            _isExpanded ? 'Show less' : 'Show more',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: Colors.blue.shade700,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // LIKE AND RESPONSES ROW
              Row(
                children: [
                  // Like Button
                  InkWell(
                    onTap: _isLiking ? null : _toggleLike,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _isLiking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  _isLiked ? Icons.favorite : Icons.favorite_border,
                                  size: 20,
                                  color: _isLiked ? Colors.red : AppColors.shadedPrimary,
                                ),
                          const SizedBox(width: 4),
                          Text(
                            '$_likeCount',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _isLiked ? Colors.red : AppColors.shadedPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Response Count
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 20,
                        color: AppColors.shadedPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${survey.responses} responses',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.shadedPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              
              // TAKE SURVEY BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to TakeSurveyPage
                    // Use postId if available, otherwise try to parse id as int
                    final effectivePostId = survey.postId ?? int.tryParse(survey.id) ?? 0;
                    if (effectivePostId == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cannot take this survey - missing ID')),
                      );
                      return;
                    }
                    Navigator.pushNamed(
                      context,
                      '/take-survey',
                      arguments: {
                        'surveyId': survey.id,
                        'postId': effectivePostId,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryText,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Take Survey',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
