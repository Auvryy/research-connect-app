import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/data/user_info.dart';
import 'package:inquira/data/api/auth_api.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;

  Color _getRoleColor(String? role) {
    if (role == null) return AppColors.secondary;
    
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.error;
      case 'moderator':
        return AppColors.orange;
      case 'premium':
        return AppColors.purple;
      default:
        return AppColors.primary;
    }
  }

  String _getRoleDisplay(String? role) {
    if (role == null) return 'User';
    
    // Capitalize first letter
    return role[0].toUpperCase() + role.substring(1).toLowerCase();
  }

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
            decoration: BoxDecoration(
              color: AppColors.secondaryBG,
            ),
            child: Column(
              children: [
                // Profile Image
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: currentUser?.profilePicUrl != null && currentUser!.profilePicUrl!.isNotEmpty
                          ? NetworkImage(currentUser!.profilePicUrl!)
                          : null,
                      child: currentUser?.profilePicUrl == null || currentUser!.profilePicUrl!.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 45,
                              color: AppColors.primary.withOpacity(0.5),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/edit-profile');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // User Name
                Text(
                  currentUser?.username ?? 'User',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                // Role Badge
                if (currentUser?.role != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getRoleColor(currentUser?.role),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getRoleDisplay(currentUser?.role),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
                  trailing: Icon(Icons.chevron_right, color: AppColors.secondary),
                  onTap: () {
                    // TODO: navigate to account page
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.privacy_tip, color: AppColors.primary),
                  title: const Text("Privacy"),
                  subtitle: const Text("Manage privacy settings"),
                  trailing: Icon(Icons.chevron_right, color: AppColors.secondary),
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
                          content: const Text("Are you sure you want to log out?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () async {
                                try {
                                  final result = await AuthAPI.logout();
                                  
                                  // Clear current user
                                  currentUser = null;
                                  
                                  // Close the dialog
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                  }
                                  
                                  if (result['ok'] == true) {
                                    // Navigate to login page and remove all previous routes
                                    if (mounted) {
                                      Navigator.of(context).pushNamedAndRemoveUntil(
                                        '/login',
                                        (Route<dynamic> route) => false,
                                      );
                                    }
                                  } else {
                                    // Even if API logout fails, still redirect to login
                                    // since local data is cleared
                                    if (mounted) {
                                      Navigator.of(context).pushNamedAndRemoveUntil(
                                        '/login',
                                        (Route<dynamic> route) => false,
                                      );
                                    }
                                  }
                                } catch (e) {
                                  // Clear user and redirect even on error
                                  currentUser = null;
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pushNamedAndRemoveUntil(
                                      '/login',
                                      (Route<dynamic> route) => false,
                                    );
                                  }
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