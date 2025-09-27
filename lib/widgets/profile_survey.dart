import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inquira/constants/colors.dart';
import '../models/survey.dart';

class ProfileSurvey extends StatelessWidget {
  final Survey survey;
  final int responses; // later you can connect this dynamically

  const ProfileSurvey({
    Key? key,
    required this.survey,
    this.responses = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yMMMd').format(survey.createdAt);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              survey.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Responses + Date
            Row(
              children: [
                const Icon(Icons.people, size: 16, color: Colors.black54),
                const SizedBox(width: 4),
                Text(
                  "$responses Responses",
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.calendar_month,
                    size: 16, color: Colors.black54),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
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
