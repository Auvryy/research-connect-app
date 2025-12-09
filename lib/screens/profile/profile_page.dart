import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/widgets/profile_survey.dart';
import 'package:inquira/screens/profile/liked_surveys_page.dart';
import 'package:inquira/data/user_info.dart';
import 'package:inquira/models/survey.dart';
import 'package:inquira/data/api/auth_api.dart';
import 'package:inquira/data/api/otp_api.dart';
import 'package:inquira/data/api/survey_api.dart';

class ProfilePage extends StatefulWidget {
  /// forcedTab: 0 = My Surveys, 1 = Others; when set, tabs are hidden and the content is locked to that tab.
  final int? forcedTab;
  const ProfilePage({super.key, this.forcedTab});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late int _selectedTab; // 0 = My Surveys, 1 = Additional Information
  int _surveyStatusTab = 0; // 0 = All, 1 = Pending, 2 = Approved, 3 = Rejected
  List<Survey> _userSurveys = [];
  List<Survey> _rejectedSurveys = [];
  List<Survey> _likedSurveys = [];
  bool _isLoading = true;
  bool _isLoadingRejected = false;
  bool _isLoadingLiked = false;
  int _totalResponses = 0; // From backend

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.forcedTab ?? 0;
    _loadUserDataAndSurveys();
  }

  /// Load both user data and user's surveys from /api/auth/user_data endpoint
  /// This endpoint returns user_info and user_posts (user's own surveys)
  Future<void> _loadUserDataAndSurveys() async {
    setState(() => _isLoading = true);
    try {
      final response = await AuthAPI.getFullUserData();
      if (response['ok'] == true && response['data'] != null) {
        final data = response['data'];
        
        // Update user info
        final userInfo = data['user_info'];
        if (userInfo != null) {
          final updatedUser = UserInfo(
            id: userInfo['id'] as int?,
            username: userInfo['username'] as String? ?? currentUser?.username ?? '',
            profilePicUrl: userInfo['profile_pic_url'] as String?,
            role: userInfo['role'] as String?,
            email: userInfo['email'] as String? ?? currentUser?.email,
            school: userInfo['school'] as String? ?? currentUser?.school,
            program: userInfo['program'] as String? ?? currentUser?.program,
          );
          await UserInfo.saveUserInfo(updatedUser);
          if (mounted) setState(() => currentUser = updatedUser);
        }
        
        // Load user's surveys directly from response (no filtering needed!)
        final userPosts = data['user_posts'] as List? ?? [];
        final userSurveys = userPosts
            .map((json) => _parseSurveyFromBackend(json as Map<String, dynamic>))
            .toList();
        
        // Parse total_num_of_responses from backend
        final totalResponses = (userInfo?['total_num_of_responses'] as int?) ?? 0;
        
        if (mounted) {
          setState(() {
            _userSurveys = userSurveys;
            _totalResponses = totalResponses;
            _isLoading = false;
          });
        }
        
        // Load rejected surveys after initial load
        _loadRejectedSurveys();
      } else {
        // Fallback to local data
        final loadedUser = await UserInfo.loadUserInfo();
        if (loadedUser != null && mounted) setState(() => currentUser = loadedUser);
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading user data and surveys: $e');
      final loadedUser = await UserInfo.loadUserInfo();
      if (loadedUser != null && mounted) setState(() => currentUser = loadedUser);
      if (mounted) {
        setState(() {
          _userSurveys = [];
          _isLoading = false;
        });
      }
    }
  }

  /// Load rejected surveys from the backend
  Future<void> _loadRejectedSurveys() async {
    if (_isLoadingRejected) return;
    
    setState(() => _isLoadingRejected = true);
    
    try {
      final response = await SurveyAPI.getRejectedSurveys();
      
      if (response['ok'] == true) {
        final surveys = (response['surveys'] as List)
            .map((json) => _parseRejectedSurveyFromBackend(json as Map<String, dynamic>))
            .toList();
        
        if (mounted) {
          setState(() {
            _rejectedSurveys = surveys;
            _isLoadingRejected = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingRejected = false);
        }
      }
    } catch (e) {
      print('Error loading rejected surveys: $e');
      if (mounted) {
        setState(() => _isLoadingRejected = false);
      }
    }
  }
  
  /// Load liked surveys from the backend
  Future<void> _loadLikedSurveys() async {
    if (_isLoadingLiked) return;
    
    setState(() => _isLoadingLiked = true);
    
    try {
      final response = await SurveyAPI.getLikedSurveys();
      
      if (response['ok'] == true) {
        final surveys = (response['surveys'] as List)
            .map((json) => _parseSurveyFromBackend(json as Map<String, dynamic>))
            .toList();
        
        if (mounted) {
          setState(() {
            _likedSurveys = surveys;
            _isLoadingLiked = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingLiked = false);
        }
      }
    } catch (e) {
      print('Error loading liked surveys: $e');
      if (mounted) {
        setState(() => _isLoadingLiked = false);
      }
    }
  }
  
  Survey _parseRejectedSurveyFromBackend(Map<String, dynamic> json) {
    final survey = _parseSurveyFromBackend(json);
    // Store rejection message if available
    final rejectionMsg = json['rejection_msg'] as String?;
    // Backend has a typo: uses 'approved`' (with backtick) instead of 'approved'
    final approved = (json['approved`'] as bool?) ?? (json['approved'] as bool?) ?? false;
    // We'll use the caption field to store rejection message temporarily
    return Survey(
      id: survey.id,
      postId: survey.postId,
      title: survey.title,
      caption: rejectionMsg ?? survey.caption,
      description: survey.description,
      timeToComplete: survey.timeToComplete,
      tags: survey.tags,
      targetAudience: survey.targetAudience,
      creator: survey.creator,
      creatorProfileUrl: survey.creatorProfileUrl,
      createdAt: survey.createdAt,
      status: survey.status,
      approved: approved, // Parse approved status correctly
      archived: survey.archived,
      responses: survey.responses,
      numOfLikes: survey.numOfLikes,
      isLiked: survey.isLiked,
      questions: survey.questions,
    );
  }

  /// Legacy method for backward compatibility - just calls the combined method
  Future<void> _loadUserDataFromBackend() async {
    await _loadUserDataAndSurveys();
  }

  /// Legacy method for backward compatibility - just calls the combined method  
  Future<void> _loadUserSurveys() async {
    await _loadUserDataAndSurveys();
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

    // Parse response count, likes count, and liked status
    final numOfResponses = json['num_of_responses'] as int? ?? 0;
    final numOfLikes = json['num_of_likes'] as int? ?? 0;
    final isLiked = json['is_liked'] as bool? ?? false;

    // Parse approved and archived flags
    // Backend has a typo: uses 'approved`' (with backtick) instead of 'approved'
    final approved = (json['approved`'] as bool?) ?? (json['approved'] as bool?) ?? false;
    final archived = json['archived'] as bool? ?? false;
    
    // Parse creator profile URL
    final creatorProfileUrl = json['user_profile'] as String?;

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
      creatorProfileUrl: creatorProfileUrl,
      createdAt: _parseDateTime(json['survey_date_created']),
      status: isOpen,
      approved: approved,
      archived: archived,
      responses: numOfResponses,
      numOfLikes: numOfLikes,
      isLiked: isLiked,
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
          creatorProfileUrl: oldSurvey.creatorProfileUrl,
          createdAt: oldSurvey.createdAt,
          status: newStatus == 'open',
          approved: oldSurvey.approved,
          archived: oldSurvey.archived,
          responses: oldSurvey.responses,
          numOfLikes: oldSurvey.numOfLikes,
          isLiked: oldSurvey.isLiked,
          questions: oldSurvey.questions,
        );
      }
    });
  }

  /// Remove archived survey from local list
  /// This is needed because backend doesn't filter archived surveys in get_post()
  void _removeSurveyFromList(int surveyId) {
    setState(() {
      _userSurveys.removeWhere((s) => s.postId == surveyId);
    });
  }

  /// Build the survey list based on the selected status tab
  Widget _buildSurveyList() {
    List<Survey> surveysToShow;
    String emptyMessage;
    String emptySubMessage;
    IconData emptyIcon;
    Color emptyIconColor;
    
    switch (_surveyStatusTab) {
      case 1: // Pending
        surveysToShow = _userSurveys.where((s) => !s.approved).toList();
        emptyMessage = 'No pending surveys';
        emptySubMessage = 'All your surveys have been reviewed!';
        emptyIcon = Icons.pending_actions;
        emptyIconColor = Colors.orange;
        break;
      case 2: // Approved
        surveysToShow = _userSurveys.where((s) => s.approved).toList();
        emptyMessage = 'No approved surveys yet';
        emptySubMessage = 'Surveys will appear here once approved by admin.';
        emptyIcon = Icons.verified;
        emptyIconColor = Colors.green;
        break;
      case 3: // Rejected
        if (_isLoadingRejected) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        surveysToShow = _rejectedSurveys;
        emptyMessage = 'No rejected surveys';
        emptySubMessage = 'Great! None of your surveys have been rejected.';
        emptyIcon = Icons.check_circle;
        emptyIconColor = Colors.green;
        break;
      default: // All - Include approved, pending, and rejected surveys
        surveysToShow = [..._userSurveys, ..._rejectedSurveys];
        emptyMessage = 'No surveys yet';
        emptySubMessage = 'Create your first survey to get started!';
        emptyIcon = Icons.quiz_outlined;
        emptyIconColor = Colors.grey;
    }
    
    if (surveysToShow.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(emptyIcon, size: 64, color: emptyIconColor.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(emptyMessage, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text(emptySubMessage, style: TextStyle(fontSize: 14, color: Colors.grey[500]), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    
    // For rejected surveys, show special card with rejection message
    if (_surveyStatusTab == 3) {
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'These surveys were rejected by admin. Check the rejection reason for each survey.',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                  ),
                ),
              ],
            ),
          ),
          ...surveysToShow.map((survey) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _RejectedSurveyCard(survey: survey),
          )),
        ],
      );
    }
    
    return Column(
      children: surveysToShow.map((survey) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: ProfileSurvey(
          survey: survey,
          onSurveyUpdated: _loadUserSurveys,
          onStatusChanged: _updateSurveyStatus,
          onSurveyArchived: _removeSurveyFromList,
        ),
      )).toList(),
    );
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
          final normalized = result.trim();
          if (field == 'school') currentUser = currentUser?.copyWith(school: normalized.isEmpty ? null : normalized);
          else if (field == 'program') currentUser = currentUser?.copyWith(program: normalized.isEmpty ? null : normalized);
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
                    Expanded(child: _StatItem(label: "Total Responses", value: _totalResponses.toString())),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (widget.forcedTab == null) ...[
                Row(
                  children: [
                    _TabButton(text: "My Surveys", isSelected: _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0)),
                    const SizedBox(width: 10),
                    _TabButton(text: "Others", isSelected: _selectedTab == 1, onTap: () => setState(() => _selectedTab = 1)),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              if (_selectedTab == 0)
                _isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
                  : Column(
                      children: [
                        // Survey Status Filter Tabs
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _SurveyStatusChip(
                                label: 'All',
                                count: _userSurveys.length + _rejectedSurveys.length,
                                isSelected: _surveyStatusTab == 0,
                                onTap: () => setState(() => _surveyStatusTab = 0),
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              _SurveyStatusChip(
                                label: 'Pending',
                                count: _userSurveys.where((s) => !s.approved).length,
                                isSelected: _surveyStatusTab == 1,
                                onTap: () => setState(() => _surveyStatusTab = 1),
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              _SurveyStatusChip(
                                label: 'Approved',
                                count: _userSurveys.where((s) => s.approved).length,
                                isSelected: _surveyStatusTab == 2,
                                onTap: () => setState(() => _surveyStatusTab = 2),
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              _SurveyStatusChip(
                                label: 'Rejected',
                                count: _rejectedSurveys.length,
                                isSelected: _surveyStatusTab == 3,
                                onTap: () {
                                  setState(() => _surveyStatusTab = 3);
                                  if (_rejectedSurveys.isEmpty && !_isLoadingRejected) {
                                    _loadRejectedSurveys();
                                  }
                                },
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Info banner about approval process
                        if (_surveyStatusTab != 3)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'New surveys require admin approval before appearing in the public feed.',
                                    style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Survey List based on selected tab
                        _buildSurveyList(),
                      ],
                    )
              else
                // Others Tab content only
                Column(
                  children: [
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
                    _SettingsItem(
                      icon: Icons.favorite,
                      label: "Liked Posts",
                      onTap: () async {
                        if (_likedSurveys.isEmpty && !_isLoadingLiked) {
                          await _loadLikedSurveys();
                        }
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LikedSurveysPage(initialSurveys: _likedSurveys),
                          ),
                        );
                      },
                      iconColor: Colors.pink,
                    ),
                    const SizedBox(height: 12),
                    _SettingsItem(icon: Icons.school, label: currentUser?.school ?? "N/A", onTap: () => _showEditDialog('School', 'school', currentUser?.school, Icons.school, Colors.red), iconColor: Colors.red),
                    const SizedBox(height: 12),
                    _SettingsItem(icon: Icons.book, label: currentUser?.program ?? "N/A", onTap: () => _showEditDialog('Program', 'program', currentUser?.program, Icons.book, Colors.cyan), iconColor: Colors.cyan),
                    const SizedBox(height: 12),
                    _SettingsItem(icon: Icons.email, label: currentUser?.email ?? "N/A", onTap: _showEmailSetupDialog, iconColor: Colors.orange),
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
                const SizedBox(height: 16),
                // Resend OTP button
                if (_resendCountdown > 0)
                  Center(
                    child: Text(
                      'Resend OTP in ${_resendCountdown}s',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => _sendOtp(isResend: true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Resend OTP'),
                    ),
                  ),
                const SizedBox(height: 8),
                // Change Email button
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _isLoading ? null : () => setState(() { _isOtpSent = false; _otpController.clear(); _errorMessage = null; _resendTimer?.cancel(); _resendCountdown = 0; }),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Change Email'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
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
  const _SettingsItem({required this.icon, required this.label, required this.onTap, this.iconColor});

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
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87))),
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
          onPressed: () async {
            final discard = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Discard changes?'),
                content: const Text('Your edits will be lost.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Editing')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
                ],
              ),
            );
            if (discard == true) Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final newValue = _controller.text.trim();

            final proceed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Save changes?'),
                content: Text('Save ${widget.title.toLowerCase()} update?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Review')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
                ],
              ),
            );

            if (proceed != true) return;

            // Return raw value (can be empty string) to let caller decide display
            Navigator.pop(context, newValue);
          },
          style: ElevatedButton.styleFrom(backgroundColor: widget.color),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

/// Survey Status Filter Chip Widget
class _SurveyStatusChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _SurveyStatusChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.25) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rejected Survey Card Widget
class _RejectedSurveyCard extends StatelessWidget {
  final Survey survey;

  const _RejectedSurveyCard({required this.survey});

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yMMMd').format(survey.createdAt);
    // Caption stores the rejection message for rejected surveys
    final rejectionMessage = survey.caption.isNotEmpty ? survey.caption : 'No reason provided';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 3),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row with Rejected Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    survey.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cancel, size: 14, color: Colors.red.shade800),
                      const SizedBox(width: 4),
                      Text(
                        'Rejected',
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Date
            Row(
              children: [
                Icon(Icons.calendar_month, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Rejection Reason Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.message, size: 16, color: Colors.red.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Rejection Reason',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rejectionMessage,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red.shade900,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
