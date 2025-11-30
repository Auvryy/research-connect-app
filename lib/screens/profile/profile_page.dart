import 'dart:async';
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
  int _selectedTab = 0;
  List<Survey> _userSurveys = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserDataFromBackend();
    _loadUserSurveys();
  }

  Future<void> _loadUserDataFromBackend() async {
    try {
      final response = await AuthAPI.getUserData();
      if (response['ok'] == true && response['data'] != null) {
        final userData = response['data'];
        final updatedUser = UserInfo(
          id: userData['id'] as int?,
          username: userData['username'] as String? ?? currentUser?.username ?? '',
          profilePicUrl: userData['profile_pic_url'] as String?,
          role: userData['role'] as String?,
          email: userData['email'] as String? ?? currentUser?.email,
          school: userData['school'] as String? ?? currentUser?.school,
          program: userData['program'] as String? ?? currentUser?.program,
        );
        await UserInfo.saveUserInfo(updatedUser);
        if (mounted) setState(() => currentUser = updatedUser);
      } else {
        final loadedUser = await UserInfo.loadUserInfo();
        if (loadedUser != null && mounted) setState(() => currentUser = loadedUser);
      }
    } catch (e) {
      final loadedUser = await UserInfo.loadUserInfo();
      if (loadedUser != null && mounted) setState(() => currentUser = loadedUser);
    }
  }

  Future<void> _loadUserSurveys() async {
    setState(() => _isLoading = true);
    try {
      final backendData = await SurveyAPI.getAllSurveys();
      final userSurveys = backendData
          .where((json) => json['user_username'] == currentUser?.username)
          .map((json) => _parseSurveyFromBackend(json))
          .toList();
      setState(() {
        _userSurveys = userSurveys;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _userSurveys = [];
        _isLoading = false;
      });
    }
  }

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

    final caption = json['survey_content'] as String? ?? '';
    bool isOpen = true;
    if (json['status'] != null) {
      isOpen = json['status'].toString().toLowerCase() == 'open';
    } else if (json['survey_status'] != null) {
      isOpen = json['survey_status'].toString().toLowerCase() == 'open';
    }

    return Survey(
      id: json['pk_survey_id']?.toString() ?? '',
      postId: json['pk_survey_id'] as int?,
      title: json['survey_title'] ?? 'Untitled Survey',
      caption: caption,
      description: '',
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
    if (dateValue is String) return DateTime.tryParse(dateValue) ?? DateTime.now();
    return DateTime.now();
  }

  int _parseTimeToComplete(String? approxTime) {
    if (approxTime == null) return 5;
    final match = RegExp(r'(\d+)').firstMatch(approxTime);
    return match != null ? int.tryParse(match.group(1)!) ?? 5 : 5;
  }

  /// Update survey status locally without reloading from backend
  /// This is needed because backend's get_post() doesn't return the status field
  void _updateSurveyStatus(int surveyId, String newStatus) {
    setState(() {
      final index = _userSurveys.indexWhere((s) => s.postId == surveyId);
      if (index != -1) {
        final oldSurvey = _userSurveys[index];
        // Create a new Survey with updated status
        _userSurveys[index] = Survey(
          id: oldSurvey.id,
          postId: oldSurvey.postId,
          title: oldSurvey.title,
          caption: oldSurvey.caption,
          description: oldSurvey.description,
          timeToComplete: oldSurvey.timeToComplete,
          tags: oldSurvey.tags,
          targetAudience: oldSurvey.targetAudience,
          creator: oldSurvey.creator,
          createdAt: oldSurvey.createdAt,
          status: newStatus == 'open',
          responses: oldSurvey.responses,
          questions: oldSurvey.questions,
        );
      }
    });
  }

  Color _getRoleColor(String? role) {
    if (role == null) return AppColors.secondary;
    switch (role.toLowerCase()) {
      case 'admin': return AppColors.error;
      case 'moderator': return AppColors.orange;
      case 'premium': return AppColors.purple;
      default: return AppColors.primary;
    }
  }

  String _getRoleDisplay(String? role) {
    if (role == null) return 'User';
    return role[0].toUpperCase() + role.substring(1).toLowerCase();
  }

  Future<void> _refreshProfile() async {
    await Future.wait([_loadUserDataFromBackend(), _loadUserSurveys()]);
  }

  Future<void> _showEditDialog(String title, String field, String? currentValue, IconData icon, Color color) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _EditFieldDialog(
        title: title,
        field: field,
        currentValue: currentValue,
        icon: icon,
        color: color,
      ),
    );
    
    // Only save if result is returned (user pressed Save, not Cancel)
    if (result != null && mounted) {
      try {
        final response = await AuthAPI.updateUserProfile(
          school: field == 'school' ? result : null,
          program: field == 'program' ? result : null,
        );
        if (response['ok'] == true) {
          if (field == 'school') currentUser = currentUser?.copyWith(school: result);
          else if (field == 'program') currentUser = currentUser?.copyWith(program: result);
          if (currentUser != null) await UserInfo.saveUserInfo(currentUser!);
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title updated successfully!'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Failed to update $title'), backgroundColor: AppColors.error),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _showEmailSetupDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _EmailSetupDialog(initialEmail: currentUser?.email ?? ''),
    );
    if (result != null && result.isNotEmpty && mounted) {
      currentUser = currentUser?.copyWith(email: result);
      if (currentUser != null) await UserInfo.saveUserInfo(currentUser!);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email set successfully!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final userEmail = currentUser?.email;
    if (userEmail == null || userEmail.isEmpty) {
      final shouldSetEmail = await showDialog<bool>(
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
                  child: Text('You need to set up your email first before you can change your password.', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Set Email', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (shouldSetEmail == true && mounted) await _showEmailSetupDialog();
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
      await showDialog(context: context, builder: (context) => ChangePasswordDialog(userEmail: userEmail));
    }
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: currentUser?.profilePicUrl != null && currentUser!.profilePicUrl!.isNotEmpty
                        ? NetworkImage(currentUser!.profilePicUrl!) : null,
                    child: currentUser?.profilePicUrl == null || currentUser!.profilePicUrl!.isEmpty
                        ? Icon(Icons.person, size: 40, color: AppColors.primary.withOpacity(0.5)) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(currentUser?.username ?? 'User',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: _getRoleColor(currentUser?.role), borderRadius: BorderRadius.circular(12)),
                          child: Text(_getRoleDisplay(currentUser?.role),
                            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.primary),
                    onPressed: () async {
                      final result = await Navigator.pushNamed(context, '/edit-profile');
                      if (result == true && mounted) {
                        await _loadUserDataFromBackend();
                        setState(() {});
                      }
                    },
                    tooltip: 'Edit Profile',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Expanded(child: _StatItem(label: "Surveys Posted", value: _userSurveys.length.toString())),
                    const Expanded(child: _StatItem(label: "Total Responses", value: "0")),
                    const Expanded(child: _StatItem(label: "Response Rate", value: "0%")),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _TabButton(text: "My Surveys", isSelected: _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0)),
                  const SizedBox(width: 10),
                  _TabButton(text: "Settings", isSelected: _selectedTab == 1, onTap: () => setState(() => _selectedTab = 1)),
                ],
              ),
              const SizedBox(height: 20),
              if (_selectedTab == 0)
                _isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
                  : _userSurveys.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text('No surveys yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                                const SizedBox(height: 8),
                                Text('Create your first survey to get started!', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: _userSurveys.map((survey) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: ProfileSurvey(
                              survey: survey,
                              onSurveyUpdated: _loadUserSurveys,
                              onStatusChanged: _updateSurveyStatus,
                            ),
                          )).toList(),
                        )
              else
                Column(
                  children: [
                    Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('Additional Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]))),
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green[200]!)),
                      child: Row(
                        children: [
                          Icon(Icons.cloud_done, color: Colors.green[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Your information is synced with the server', style: TextStyle(fontSize: 12, color: Colors.green[900]))),
                        ],
                      ),
                    ),
                    _SettingsItem(icon: Icons.school, label: currentUser?.school ?? "N/A", onTap: () => _showEditDialog('School', 'school', currentUser?.school, Icons.school, Colors.red), iconColor: Colors.red),
                    const SizedBox(height: 12),
                    _SettingsItem(icon: Icons.book, label: currentUser?.program ?? "N/A", onTap: () => _showEditDialog('Program', 'program', currentUser?.program, Icons.book, Colors.cyan), iconColor: Colors.cyan),
                    const SizedBox(height: 12),
                    _SettingsItem(icon: Icons.email, label: currentUser?.email ?? "N/A", onTap: _showEmailSetupDialog, iconColor: Colors.orange),
                    const SizedBox(height: 20),
                    Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('Account Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]))),
                    _SettingsItem(icon: Icons.lock, label: "Change Password", onTap: _showChangePasswordDialog),
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
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
                            if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error logging out: \$e'), backgroundColor: AppColors.error));
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

class _EmailSetupDialog extends StatefulWidget {
  final String initialEmail;
  const _EmailSetupDialog({required this.initialEmail});
  @override
  State<_EmailSetupDialog> createState() => _EmailSetupDialogState();
}

class _EmailSetupDialogState extends State<_EmailSetupDialog> {
  late TextEditingController _emailController;
  late TextEditingController _otpController;
  final _formKey = GlobalKey<FormState>();
  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _errorMessage;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _resendCountdown--;
          if (_resendCountdown <= 0) timer.cancel();
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendOtp({bool isResend = false}) async {
    if (!isResend && !_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final response = await OtpAPI.sendOtp(_emailController.text.trim());
      if (mounted) {
        if (response['ok'] == true) {
          setState(() { _isOtpSent = true; _isLoading = false; if (isResend) _otpController.clear(); });
          _startResendCountdown();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isResend ? 'New OTP sent!' : 'OTP sent to your email!'), backgroundColor: Colors.green));
        } else {
          setState(() { _errorMessage = response['message'] ?? 'Failed to send OTP'; _isLoading = false; });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'Error: \$e'; _isLoading = false; });
    }
  }

  Future<void> _verifyOtpAndSetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final response = await OtpAPI.setEmailWithOtp(_otpController.text.trim());
      if (mounted) {
        if (response['ok'] == true) {
          Navigator.pop(context, _emailController.text.trim());
        } else {
          setState(() { _errorMessage = response['message'] ?? 'Failed to verify OTP'; _isLoading = false; });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'Error: \$e'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isOtpSent ? 'Verify OTP' : 'Set Email'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isOtpSent) ...[
                const Text('Enter your email address. We will send you an OTP to verify.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email, color: AppColors.primary), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), hintText: 'Enter your email'),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Email is required';
                    if (!value.trim().contains('@') || !value.trim().contains('.')) return 'Please enter a valid email';
                    return null;
                  },
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.withOpacity(0.3))),
                  child: Row(children: [
                    Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text('OTP sent to ${_emailController.text}', style: TextStyle(fontSize: 12, color: Colors.green[900]))),
                  ]),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _otpController,
                  decoration: InputDecoration(labelText: 'OTP Code', prefixIcon: Icon(Icons.lock_clock, color: AppColors.primary), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), hintText: 'Enter 6-digit OTP', counterText: ''),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'OTP is required';
                    if (value.trim().length != 6) return 'OTP must be 6 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Resend OTP and Change Email buttons in a column for better layout
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_resendCountdown > 0)
                      Text(
                        'Resend OTP in ${_resendCountdown}s',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      )
                    else
                      TextButton(
                        onPressed: _isLoading ? null : () => _sendOtp(isResend: true),
                        child: const Text('Resend OTP'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                      ),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: _isLoading ? null : () => setState(() { _isOtpSent = false; _otpController.clear(); _errorMessage = null; _resendTimer?.cancel(); _resendCountdown = 0; }),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Change Email'),
                      style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!, style: TextStyle(fontSize: 12, color: AppColors.error))),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading ? null : (_isOtpSent ? _verifyOtpAndSetEmail : _sendOtp),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(_isOtpSent ? 'Verify & Set Email' : 'Send OTP', style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.white70)),
    ]);
  }
}

class _TabButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  const _TabButton({required this.text, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? AppColors.primary : AppColors.secondaryBG, borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(text, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold))),
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
  const _SettingsItem({required this.icon, required this.label, required this.onTap, this.iconColor, this.textColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: (iconColor ?? AppColors.primary).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor ?? AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor ?? Colors.black87))),
          Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[400]),
        ]),
      ),
    );
  }
}

/// Edit Field Dialog - Separate StatefulWidget to prevent crashes on cancel
class _EditFieldDialog extends StatefulWidget {
  final String title;
  final String field;
  final String? currentValue;
  final IconData icon;
  final Color color;

  const _EditFieldDialog({
    required this.title,
    required this.field,
    required this.currentValue,
    required this.icon,
    required this.color,
  });

  @override
  State<_EditFieldDialog> createState() => _EditFieldDialogState();
}

class _EditFieldDialogState extends State<_EditFieldDialog> {
  late TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final val = widget.currentValue;
    _controller = TextEditingController(
      text: (val == null || val.isEmpty || val == 'N/A') ? '' : val,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.title}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.title,
            prefixIcon: Icon(widget.icon, color: widget.color),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: 'Enter ${widget.title} (leave empty for N/A)',
          ),
          keyboardType: TextInputType.text,
          validator: (value) {
            if (value != null && value.trim().length > 256) {
              return '${widget.title} must not exceed 256 characters';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // Cancel - return null
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final newValue = _controller.text.trim();
            final valueToSave = newValue.isEmpty ? 'N/A' : newValue;
            Navigator.pop(context, valueToSave); // Return the value to save
          },
          style: ElevatedButton.styleFrom(backgroundColor: widget.color),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
