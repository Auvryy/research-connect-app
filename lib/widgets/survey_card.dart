import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import '../models/survey.dart';

class SurveyCard extends StatefulWidget {
  final Survey survey;

  const SurveyCard({Key? key, required this.survey}) : super(key: key);

  @override
  _SurveyCardState createState() => _SurveyCardState();
}

class _SurveyCardState extends State<SurveyCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final survey = widget.survey;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TITLE + TOGGLE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    survey.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: _isExpanded ? 3 : 1,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Text(
                    _isExpanded ? "Less ▲" : "More ▼",
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // AUTHOR
            Text(
              "by ${survey.creator} • ${survey.targetAudience}",
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.shadedPrimary,
              ),
            ),

            const SizedBox(height: 8),

            // TAGS
            Wrap(
              spacing: 7,
              children: survey.tags.map((tag) {
                return Chip(
                  label: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryText, // text color
                    ),
                  ),
                  backgroundColor: AppColors.secondary2, // background color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20), // border radius
                    side: BorderSide.none, // no border
                  ),
                  visualDensity: const VisualDensity(
                    horizontal: 0,
                    vertical: -4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  labelPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 0,
                  ),
                );
              }).toList(),
            ),

            if (_isExpanded) ...[
              const SizedBox(height: 8),

              // DESCRIPTION (only when expanded)
              Text(
                survey.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primaryText,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // FOOTER: TIME + BUTTON
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text("~${survey.timeToComplete}m"),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to TakeSurveyPage
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent1,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text("Take Survey"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
