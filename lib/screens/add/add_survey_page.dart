import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';

class AddSurveyPage extends StatelessWidget {
  const AddSurveyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Create Survey"),
        backgroundColor: AppColors.secondaryBG,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: "Survey Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: save survey
              },
              child: const Text("Publish Survey"),
            ),
          ],
        ),
      ),
    );
  }
}
