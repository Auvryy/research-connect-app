import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/widgets/profile_survey.dart';
import 'package:inquira/widgets/change_password_dialog.dart';
import 'package:inquira/data/user_info.dart';
import 'package:inquira/models/survey.dart';
import 'package:inquira/data/api/auth_api.dart';
import 'package:inquira/data/api/survey_api.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedTab = 0; // 0 = My Surveys, 1 = Profile Information
  List<Survey> _userSurveys = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserDataFromBackend();
    _loadUserSurveys();
  }

  /// Load user data from backend (not just local cache)
  Future<void> _loadUserDataFromBackend() async {
    try {
      print('ProfilePage: Fetching user data from backend...');
      final response = await AuthAPI.getUserData();
      
      if (response['ok'] == true && response['data'] != null) {
        final userData = response['data'];
        final updatedUser = UserInfo(
          id: userData['id'] as int?,
          username: userData['username'] as String? ?? currentUser?.username ?? '',
          profilePicUrl: userData['profile_pic_url'] as String?,
          role: userData['role'] as String?,
          email: currentUser?.email, // Keep local email
          school: userData['school'] as String? ?? currentUser?.school,
          program: userData['program'] as String? ?? currentUser?.program,
        );
        
        // Save updated user info
        await UserInfo.saveUserInfo(updatedUser);
        
        if (mounted) {
          setState(() {
            currentUser = updatedUser;
          });
        }
        print('ProfilePage: User data loaded from backend');
      } else {
        // Fallback to local cache
        final loadedUser = await UserInfo.loadUserInfo();
        if (loadedUser != null && mounted) {
          setState(() {
            currentUser = loadedUser;
          });
        }
      }
    } catch (e) {
      print('ProfilePage: Error loading user data from backend: $e');
      // Fallback to local cache
      final loadedUser = await UserInfo.loadUserInfo();
      if (loadedUser != null && mounted) {
        setState(() {
          currentUser = loadedUser;
        });
      }
    }
  }

  /// Load user's surveys from backend
  Future<void> _loadUserSurveys() async {
    setState(() => _isLoading = true);
    
    try {
      // Fetch all surveys from backend and filter by current user
      print('ProfilePage: Fetching user surveys from backend...');
      final backendData = await SurveyAPI.getAllSurveys();
      
      // Filter surveys by current user's username
      final userSurveys = backendData
          .where((json) => json['user_username'] == currentUser?.username)
          .map((json) => _parseSurveyFromBackend(json))
          .toList();
      
      print('ProfilePage: Found ${userSurveys.length} surveys for user ${currentUser?.username}');
      
      setState(() {
        _userSurveys = userSurveys;
        _isLoading = false;
      });
    } catch (e) {
      print('ProfilePage: Error loading user surveys: $e');
      setState(() {
        _userSurveys = [];
        _isLoading = false;
      });
    }
  }

  /// Parse survey from backend JSON format
  Survey _parseSurveyFromBackend(Map<String, dynamic> json) {
    String targetAudience = '';
    if (json['survey_target_audience'] is List) {
      targetAudience = (json['survey_target_audience'] as List).join(', ');
    } else if (json['survey_target_audience'] is String) {
      targetAudience = json['survey_target_audience'] as String;
    }

    List<String> tags = [];
    if (json['survey_category'] != null) {
      if (json['survey_category'] is List) {
        tags = List<String>.from(json['survey_category']);
      } else if (json['survey_category'] is String) {
        tags = [json['survey_category'] as String];
      }
    }

    return Survey(
      id: json['pk_survey_id']?.toString() ?? '',
      postId: json['pk_survey_id'] as int?,
      title: json['survey_title'] ?? 'Untitled Survey',
      caption: '',
      description: json['survey_content'] ?? '',
      timeToComplete: _parseTimeToComplete(json['survey_approx_time']),
      tags: tags,
      targetAudience: targetAudience,
      creator: json['user_username'] ?? 'Unknown',
      createdAt: _parseDateTime(json['survey_date_created']),
      status: true,
      responses: 0,
      questions: [],
    );
  }

  DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    if (dateValue is String) {
      return DateTime.tryParse(dateValue) ?? DateTime.now();
    }
    return DateTime.now();
  }

  int _parseTimeToComplete(String? approxTime) {
    if (approxTime == null) return 5;
    final match = RegExp(r'(\d+)').firstMatch(approxTime);
    return match != null ? int.tryParse(match.group(1)!) ?? 5 : 5;
  }

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

  Future<void> _refreshProfile() async {
    await Future.wait([
      _loadUserDataFromBackend(),
      _loadUserSurveys(),
    ]);
  }

  Future<void> _showEditDialog(String title, String field, String? currentValue, IconData icon, Color color) async {
    final controller = TextEditingController(text: currentValue ?? '');
    final formKey = GlobalKey<FormState>();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: title,
              prefixIcon: Icon(icon, color: color),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: field == 'school' || field == 'program' 
                  ? 'Min 2 characters' 
                  : field == 'email' ? 'Stored locally' : null,
            ),
            keyboardType: field == 'email' ? TextInputType.emailAddress : TextInputType.text,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field cannot be empty';
              }
              if (field == 'email' && !value.contains('@')) {
                return 'Please enter a valid email';
              }
              // Validate length for backend fields
              if (field == 'school' || field == 'program') {
                if (value.trim().length < 2) {
                  return '${title} must be at least 2 characters';
                }
                if (value.trim().length > 256) {
                  return '${title} must not exceed 256 characters';
                }
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (result == true && mounted) {
      final newValue = controller.text.trim();
      if (currentUser != null) {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
        
        try {
          if (field == 'school' || field == 'program') {
            // Update via backend API
            final response = await AuthAPI.updateUserProfile(
              school: field == 'school' ? newValue : currentUser?.school,
              program: field == 'program' ? newValue : currentUser?.program,
            );
            
            // Close loading dialog
            if (mounted) Navigator.of(context).pop();
            
            if (response['ok'] == true) {
              // Update local state
              if (field == 'school') {
                currentUser = currentUser!.copyWith(school: newValue);
              } else if (field == 'program') {
                currentUser = currentUser!.copyWith(program: newValue);
              }
              
              // Save to SharedPreferences
              await UserInfo.saveUserInfo(currentUser!);
              setState(() {});
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$title updated successfully!'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(response['message'] ?? 'Failed to update $title'),
                    backgroundColor: AppColors.error,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            }
          } else if (field == 'email') {
            // Email is local only (backend doesn't support direct email update)
            currentUser = currentUser!.copyWith(email: newValue);
            
            // Close loading dialog
            if (mounted) Navigator.of(context).pop();
            
            // Save to SharedPreferences
            await UserInfo.saveUserInfo(currentUser!);
            setState(() {});
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title updated locally!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        } catch (e) {
          // Close loading dialog
          if (mounted) Navigator.of(context).pop();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating $title: $e'),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
          // wrap everything in a column
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Profile Header ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: currentUser?.profilePicUrl != null && currentUser!.profilePicUrl!.isNotEmpty
                      ? NetworkImage(currentUser!.profilePicUrl!)
                      : null,
                  child: currentUser?.profilePicUrl == null || currentUser!.profilePicUrl!.isEmpty
                      ? Icon(
                          Icons.person,
                          size: 40,
                          color: AppColors.primary.withOpacity(0.5),
                        )
                      : null,
                ),
                const SizedBox(width: 16), // spacing between image and text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.username ?? 'User',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(currentUser?.role),
                          borderRadius: BorderRadius.circular(12),
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
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () async {
                    final result = await Navigator.pushNamed(context, '/edit-profile');
                    if (result == true && mounted) {
                      // Reload user data and page from backend
                      await _loadUserDataFromBackend();
                      setState(() {});
                    }
                  },
                  tooltip: 'Edit Profile',
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
                children: [
                  Expanded(
                    child: _StatItem(
                      label: "Surveys Posted",
                      value: _userSurveys.length.toString(),
                    ),
                  ),
                  const Expanded(
                    child: _StatItem(label: "Total Responses", value: "0"),
                  ),
                  const Expanded(
                    child: _StatItem(label: "Response Rate", value: "0%"),
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
                  text: "Settings",
                  isSelected: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- Tab Content ---
            if (_selectedTab == 0)
              _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _userSurveys.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.quiz_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No surveys yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create your first survey to get started!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: _userSurveys.map((survey) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: ProfileSurvey(
                              survey: survey,
                              onSurveyUpdated: _loadUserSurveys,
                            ),
                          );
                        }).toList(),
                      )
            else
              Column(
                children: [
                  // Profile Information Header
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Additional Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  // Info box about storage
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_done, color: Colors.green[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'School and Program are synced with the server',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.email,
                    label: currentUser?.email != null && currentUser!.email!.isNotEmpty
                        ? currentUser!.email!
                        : "Email (Not set)",
                    onTap: () => _showEditDialog('Email', 'email', currentUser?.email, Icons.email, Colors.purple),
                    iconColor: Colors.purple,
                    subtitle: 'Stored locally',
                  ),
                  const SizedBox(height: 12),
                  _SettingsItem(
                    icon: Icons.school,
                    label: currentUser?.school != null && currentUser!.school!.isNotEmpty
                        ? currentUser!.school!
                        : "School (Not set)",
                    onTap: () => _showEditDialog('School', 'school', currentUser?.school, Icons.school, Colors.red),
                    iconColor: Colors.red,
                    subtitle: 'Synced with server',
                  ),
                  const SizedBox(height: 12),
                  _SettingsItem(
                    icon: Icons.book,
                    label: currentUser?.program != null && currentUser!.program!.isNotEmpty
                        ? currentUser!.program!
                        : "Program (Not set)",
                    onTap: () => _showEditDialog('Program', 'program', currentUser?.program, Icons.book, Colors.cyan),
                    iconColor: Colors.cyan,
                    subtitle: 'Synced with server',
                  ),
                  const SizedBox(height: 20),
                  // Account Actions Header
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Account Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.lock,
                    label: "Change Password",
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (context) => const ChangePasswordDialog(),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _SettingsItem(
                    icon: Icons.logout,
                    label: "Logout",
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                              ),
                              child: const Text('Logout', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && mounted) {
                        try {
                          await AuthAPI.logout();
                          await UserInfo.clearUserInfo();
                          currentUser = null;
                          
                          if (mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error logging out: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                    iconColor: AppColors.error,
                    textColor: AppColors.error,
                  ),
                ],
              ),
          ],
        ),
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

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  final String? subtitle;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor ?? Colors.black87,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
