import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/data/mock_survey.dart';
import 'package:inquira/widgets/profile_survey.dart';
import 'package:inquira/widgets/profile_info_item.dart';
import 'package:inquira/widgets/confirmation_dialog.dart';
import 'package:inquira/data/user_info.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedTab = 0; // 0 = My Surveys, 1 = Profile Information

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          // wrap everything in a column
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Profile Header ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('assets/images/guts-image.jpeg'),
                ),
                const SizedBox(width: 16), // spacing between image and text
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUser.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      currentUser.course,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      currentUser.school,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- Stats Row ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.primary, // background color
                borderRadius: BorderRadius.circular(16), // rounded corners
              ),
              child: Row(
                children: const [
                  Expanded(
                    child: _StatItem(label: "Surveys Posted", value: "13"),
                  ),
                  Expanded(
                    child: _StatItem(label: "Total Responses", value: "2.4k"),
                  ),
                  Expanded(
                    child: _StatItem(label: "Response Rate", value: "92%"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- Tabs ---
            Row(
              children: [
                _TabButton(
                  text: "My Surveys",
                  isSelected: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                ),
                const SizedBox(width: 10),
                _TabButton(
                  text: "Profile Information",
                  isSelected: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- Tab Content ---
            if (_selectedTab == 0)
              Column(
                children: mockSurveys.map((survey) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ProfileSurvey(survey: survey),
                  );
                }).toList(),
              )
            else
              Column(
                children: [
                  ProfileInfoItem(
                    icon: Icons.person,
                    label: "Full Name",
                    value: currentUser.name,
                    iconColor: AppColors.blue,
                    onEdit: () async {
                      final confirmed = await showConfirmationDialog(
                        context,
                        title: "Confirm Edit",
                        message: "Are you sure you want to edit your name?",
                      );

                      if (confirmed) {
                        print("User wants to edit name!");
                        // 👉 here you can open another dialog with a TextField
                        // or update the value directly
                      } else {
                        print("User cancelled editing.");
                      }
                    },
                  ),
                  ProfileInfoItem(
                    icon: Icons.mail,
                    label: "Email",
                    value: currentUser.email,
                    iconColor: AppColors.purple,
                    onEdit: () => print("hello"),
                  ),
                  ProfileInfoItem(
                    icon: Icons.phone,
                    label: "Phone Number",
                    value: currentUser.phone,
                    iconColor: AppColors.green,
                    onEdit: () => print("hello"),
                  ),
                  ProfileInfoItem(
                    icon: Icons.school,
                    label: "School",
                    value: currentUser.school,
                    iconColor: AppColors.orange,
                    onEdit: () => print("hello"),
                  ),
                  ProfileInfoItem(
                    icon: Icons.book,
                    label: "Course",
                    value: currentUser.course,
                    iconColor: AppColors.pink,
                    onEdit: () => print("hello"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.secondaryBG,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
