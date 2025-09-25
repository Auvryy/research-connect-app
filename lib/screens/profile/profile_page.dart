import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage('assets/images/guts-image.jpeg'),
            ),
            const SizedBox(height: 10),
            const Text(
              "John Doe",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "johndoe@example.com",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondary,
              ),
            ),
            const Divider(height: 30),
            const Text(
              "My Surveys",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                title: const Text("Survey about Social Media"),
                subtitle: const Text("Created on Sep 23, 2025"),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("Survey about Psychology"),
                subtitle: const Text("Created on Sep 20, 2025"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
