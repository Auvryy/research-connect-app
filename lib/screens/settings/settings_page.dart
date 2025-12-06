import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/data/user_info.dart';
import 'package:inquira/data/api/auth_api.dart';
import 'package:inquira/widgets/change_password_dialog.dart';

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
                const Divider(height: 1, thickness: 8, color: AppColors.background),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Privacy',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.lock, color: AppColors.primary),
                  title: const Text("Change Password"),
                  trailing: Icon(Icons.chevron_right, color: AppColors.secondary),
                  onTap: () async {
                    final userEmail = currentUser?.email;
                    if (userEmail == null || userEmail.isEmpty) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Email Required'),
                          content: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber, color: Colors.orange[700], size: 24),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text('You need to set up your email first before you can change your password. Go to Profile > Additional Information to set your email.', style: TextStyle(fontSize: 14)),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                          ],
                        ),
                      );
                      return;
                    }
                    
                    // Show confirmation dialog before sending OTP
                    final shouldProceed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Change Password'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.email_outlined, color: AppColors.primary, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'An OTP will be sent to:\n$userEmail',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Do you want to proceed?',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            child: const Text('Send OTP', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    
                    if (shouldProceed == true && mounted) {
                      showDialog(context: context, builder: (context) => ChangePasswordDialog(userEmail: userEmail));
                    }
                  },
                ),
                const Divider(height: 1),
                const Divider(height: 1, thickness: 8, color: AppColors.background),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Preferences',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.archive, color: Colors.orange),
                  title: const Text("Archived Surveys"),
                  trailing: Icon(Icons.chevron_right, color: AppColors.secondary),
                  onTap: () {
                    Navigator.pushNamed(context, '/archived-surveys');
                  },
                ),
                const Divider(height: 1),
                const Divider(height: 1, thickness: 8, color: AppColors.background),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
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