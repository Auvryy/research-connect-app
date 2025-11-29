import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/widgets/profile_survey.dart';
import 'package:inquira/widgets/change_password_dialog.dart';
import 'package:inquira/data/user_info.dart';
import 'package:inquira/models/survey.dart';
import 'package:inquira/data/api/auth_api.dart';
import 'package:inquira/data/api/survey_api.dart';
import 'package:inquira/data/api/otp_api.dart';

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
  /// Backend response from get_post():
  /// - survey_content = Posts.content (this is the caption/post content)
  /// - survey_title, survey_category, survey_target_audience, etc.
  /// - Note: survey description is not returned in list view, only in questionnaire endpoint
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

    // Backend: survey_content from get_post() is actually Posts.content (caption)
    // The actual survey description is only available via questionnaire endpoint
    final caption = json['survey_content'] as String? ?? '';
    
    // Parse status from backend if available (defaults to 'open')
    // Backend stores status as 'open' or 'closed' string
    bool isOpen = true;
    if (json['status'] != null) {
      isOpen = json['status'].toString().toLowerCase() == 'open';
    }

    return Survey(
      id: json['pk_survey_id']?.toString() ?? '',
      postId: json['pk_survey_id'] as int?,
      title: json['survey_title'] ?? 'Untitled Survey',
      caption: caption, // Caption is the post content
      description: '', // Description only available from questionnaire endpoint
      timeToComplete: _parseTimeToComplete(json['approx_time']),
      tags: tags,
      targetAudience: targetAudience,
      creator: json['user_username'] ?? 'Unknown',
      createdAt: _parseDateTime(json['survey_date_created']),
      status: isOpen,
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
    final controller = TextEditingController(
      text: (currentValue == null || currentValue.isEmpty || currentValue == 'N/A') ? '' : currentValue,
    );
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit $title'),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: title,
                    prefixIcon: Icon(icon, color: color),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    hintText: 'Enter $title (leave empty for N/A)',
                  ),
                  keyboardType: TextInputType.text,
                  enabled: !isLoading,
                  validator: (value) {
                    if (value != null && value.trim().length > 256) {
                      return '$title must not exceed 256 characters';
                    }
                    return null;
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    if (!formKey.currentState!.validate()) return;
                    
                    setDialogState(() => isLoading = true);
                    
                    final newValue = controller.text.trim();
                    final valueToSave = newValue.isEmpty ? 'N/A' : newValue;
                    
                    try {
                      final response = await AuthAPI.updateUserProfile(
                        school: field == 'school' ? valueToSave : null,
                        program: field == 'program' ? valueToSave : null,
                      );
                      
                      if (response['ok'] == true) {
                        if (field == 'school') {
                          currentUser = currentUser?.copyWith(school: valueToSave);
                        } else if (field == 'program') {
                          currentUser = currentUser?.copyWith(program: valueToSave);
                        }
                        if (currentUser != null) {
                          await UserInfo.saveUserInfo(currentUser!);
                        }
                        
                        if (mounted) {
                          Navigator.pop(dialogContext);
                          setState(() {});
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('$title updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        setDialogState(() => isLoading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(response['message'] ?? 'Failed to update $title'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      setDialogState(() => isLoading = false);
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
  }

  /// Show email setup dialog with OTP verification flow
  /// Flow: Enter email -> Send OTP -> Enter OTP -> Email is set
  Future<void> _showEmailSetupDialog() async {
    final emailController = TextEditingController(text: currentUser?.email ?? '');
    final otpController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isOtpSent = false;
    bool isLoading = false;
    String? errorMessage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isOtpSent ? 'Verify OTP' : 'Set Email'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isOtpSent) ...[
                      const Text(
                        'Enter your email address. We will send you an OTP to verify.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email, color: AppColors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          hintText: 'Enter your email',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isLoading,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ] else ...[
                      Text(
                        'OTP sent to ${emailController.text}',
                        style: const TextStyle(fontSize: 13, color: Colors.green),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: otpController,
                        decoration: InputDecoration(
                          labelText: 'OTP Code',
                          prefixIcon: Icon(Icons.lock_clock, color: AppColors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          hintText: 'Enter 6-digit OTP',
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        enabled: !isLoading,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'OTP is required';
                          }
                          if (value.trim().length != 6) {
                            return 'OTP must be 6 digits';
                          }
                          return null;
                        },
                      ),
                    ],
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        style: TextStyle(fontSize: 12, color: AppColors.error),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () {
                    if (isOtpSent) {
                      // Go back to email entry
                      setDialogState(() {
                        isOtpSent = false;
                        otpController.clear();
                        errorMessage = null;
                      });
                    } else {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: Text(isOtpSent ? 'Back' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    if (!formKey.currentState!.validate()) return;
                    
                    setDialogState(() {
                      isLoading = true;
                      errorMessage = null;
                    });

                    try {
                      if (!isOtpSent) {
                        // Step 1: Send OTP
                        final response = await OtpAPI.sendOtp(emailController.text.trim());
                        
                        if (response['ok'] == true) {
                          setDialogState(() {
                            isOtpSent = true;
                            isLoading = false;
                          });
                        } else {
                          setDialogState(() {
                            errorMessage = response['message'] ?? 'Failed to send OTP';
                            isLoading = false;
                          });
                        }
                      } else {
                        // Step 2: Verify OTP and set email
                        final response = await OtpAPI.setEmailWithOtp(otpController.text.trim());
                        
                        if (response['ok'] == true) {
                          // Update local user info with the new email
                          if (currentUser != null) {
                            currentUser = currentUser!.copyWith(email: emailController.text.trim());
                            await UserInfo.saveUserInfo(currentUser!);
                          }
                          
                          if (mounted) {
                            Navigator.pop(dialogContext);
                            setState(() {}); // Refresh UI
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Email set successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else {
                          setDialogState(() {
                            errorMessage = response['message'] ?? 'Failed to verify OTP';
                            isLoading = false;
                          });
                        }
                      }
                    } catch (e) {
                      setDialogState(() {
                        errorMessage = 'Error: $e';
                        isLoading = false;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isOtpSent ? 'Verify & Set Email' : 'Send OTP',
                        style: const TextStyle(color: Colors.white),
                      ),
                ),
              ],
            );
          },
        );
      },
    );
    
    emailController.dispose();
    otpController.dispose();
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
                  // Info box about server sync
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
                            'Your information is synced with the server',
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
                    icon: Icons.school,
                    label: currentUser?.school != null && currentUser!.school!.isNotEmpty
                        ? currentUser!.school!
                        : "N/A",
                    onTap: () => _showEditDialog('School', 'school', currentUser?.school, Icons.school, Colors.red),
                    iconColor: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  _SettingsItem(
                    icon: Icons.book,
                    label: currentUser?.program != null && currentUser!.program!.isNotEmpty
                        ? currentUser!.program!
                        : "N/A",
                    onTap: () => _showEditDialog('Program', 'program', currentUser?.program, Icons.book, Colors.cyan),
                    iconColor: Colors.cyan,
                  ),
                  const SizedBox(height: 12),
                  _SettingsItem(
                    icon: Icons.email,
                    label: currentUser?.email != null && currentUser!.email!.isNotEmpty
                        ? currentUser!.email!
                        : "N/A",
                    onTap: _showEmailSetupDialog,
                    iconColor: Colors.orange,
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
