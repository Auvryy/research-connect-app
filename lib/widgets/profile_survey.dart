import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/screens/survey/edit_survey_page.dart';
import '../models/survey.dart';

class ProfileSurvey extends StatelessWidget {
  final Survey survey;
  final int responses; // later you can connect this dynamically
  final VoidCallback? onSurveyUpdated; // Callback when survey is edited

  const ProfileSurvey({
    Key? key,
    required this.survey,
    this.responses = 0,
    this.onSurveyUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yMMMd').format(survey.createdAt);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 3),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row with Edit Button
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
                // Edit Button
                if (survey.postId != null)
                  IconButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditSurveyPage(survey: survey),
                        ),
                      );
                      if (result == true && onSurveyUpdated != null) {
                        onSurveyUpdated!();
                      }
                    },
                    icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                    tooltip: "Edit Survey",
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
                  survey.responses.toString() + " Responses",
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
                // Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: survey.status
                        ? Colors.blue.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    survey.status ? "ACTIVE" : "CLOSED",
                    style: TextStyle(
                      color:
                          survey.status ? Colors.blue.shade800 : Colors.red[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),

                // Summary Button
                IconButton(
                  onPressed: () {
                    // TODO: Implement navigation to summary page
                  },
                  icon: const Icon(Icons.bar_chart, color: Colors.black87),
                  tooltip: "View Summary",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
