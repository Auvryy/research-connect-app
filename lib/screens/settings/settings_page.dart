import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/data/user_info.dart';
import 'package:inquira/data/api/auth_api.dart';
import 'package:inquira/data/api/dio_client.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Settings",
          style: TextStyle(
            fontFamily: 'Giaza',
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.secondaryBG,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Profile Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(color: AppColors.secondaryBG),
            child: Column(
              children: [
                // Profile Image
                Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        image: const DecorationImage(
                          image: AssetImage('assets/images/guts-image.jpeg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // User Name
                Text(
                  "Dr. ${currentUser.name.split(' ')[0]} ${currentUser.name.split(' ')[currentUser.name.split(' ').length - 1]}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                // Course
                Text(
                  currentUser.course,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 2),
                // School
                Text(
                  currentUser.school,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Settings List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                SwitchListTile(
                  title: const Text("Dark Mode"),
                  subtitle: const Text("Toggle dark theme"),
                  value: _isDarkMode,
                  activeColor: AppColors.accent1,
                  onChanged: (bool value) {
                    setState(() {
                      _isDarkMode = value;
                    });
                    // TODO: Apply theme when theme system is implemented
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.account_circle, color: AppColors.primary),
                  title: const Text("Account"),
                  subtitle: const Text("Manage your account"),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: AppColors.secondary,
                  ),
                  onTap: () {
                    // TODO: navigate to account page
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.privacy_tip, color: AppColors.primary),
                  title: const Text("Privacy"),
                  subtitle: const Text("Manage privacy settings"),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: AppColors.secondary,
                  ),
                  onTap: () {
                    // TODO: navigate to privacy page
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.pink),
                  title: const Text(
                    "Log Out",
                    style: TextStyle(color: AppColors.pink),
                  ),
                  onTap: () {
                    // Show logout confirmation dialog
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Log Out"),
                          content: const Text(
                            "Are you sure you want to log out?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.of(
                                  context,
                                ).pop(); // close the dialog first

                                try {
                                  final response = await AuthAPI.logout();

                                  if (response["ok"] == true) {
                                    // clear local cookies/session
                                    DioClient.cookieJar.deleteAll();

                                    // show confirmation
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Logged out successfully",
                                        ),
                                      ),
                                    );

                                    // navigate back to login screen and clear previous pages
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/login',
                                      (route) => false,
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          response["message"].toString(),
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Logout failed: $e"),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                "Log Out",
                                style: TextStyle(color: AppColors.pink),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
