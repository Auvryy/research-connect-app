// lib/data/user_info.dart
import 'package:shared_preferences/shared_preferences.dart';

class UserInfo {
  final int? id;
  final String username;
  final String? profilePicUrl;
  final String? role;
  final String? email;
  final String? school;
  final String? program;

  UserInfo({
    this.id,
    required this.username,
    this.profilePicUrl,
    this.role,
    this.email,
    this.school,
    this.program,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as int?,
      username: (json['username'] ?? '') as String,
      // Backend returns 'profile_pic_url' from get_user()
      profilePicUrl: json['profile_pic_url'] as String?,
      role: json['role'] as String?,
      email: json['email'] as String?,
      school: json['school'] as String?,
      program: json['program'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'profile_pic_url': profilePicUrl,
      'role': role,
      'email': email,
      'school': school,
      'program': program,
    };
  }

  /// Create a copy with updated fields
  UserInfo copyWith({
    int? id,
    String? username,
    String? profilePicUrl,
    String? role,
    String? email,
    String? school,
    String? program,
  }) {
    return UserInfo(
      id: id ?? this.id,
      username: username ?? this.username,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      role: role ?? this.role,
      email: email ?? this.email,
      school: school ?? this.school,
      program: program ?? this.program,
    );
  }

  /// Save user info to SharedPreferences
  static Future<bool> saveUserInfo(UserInfo user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save each field individually for easier access
      await prefs.setInt('user_id', user.id ?? 0);
      await prefs.setString('username', user.username);
      if (user.profilePicUrl != null) await prefs.setString('user_profile_pic', user.profilePicUrl!);
      if (user.role != null) await prefs.setString('user_role', user.role!);
      if (user.email != null) await prefs.setString('user_email', user.email!);
      if (user.school != null) await prefs.setString('user_school', user.school!);
      if (user.program != null) await prefs.setString('user_program', user.program!);
      
      print('UserInfo saved successfully: ${user.username}');
      return true;
    } catch (e) {
      print('Error saving UserInfo: $e');
      return false;
    }
  }

  /// Load user info from SharedPreferences
  static Future<UserInfo?> loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final username = prefs.getString('username');
      
      if (userId == null || username == null) {
        print('No user info found in SharedPreferences');
        return null;
      }
      
      return UserInfo(
        id: userId,
        username: username,
        profilePicUrl: prefs.getString('user_profile_pic'),
        role: prefs.getString('user_role'),
        email: prefs.getString('user_email'),
        school: prefs.getString('user_school'),
        program: prefs.getString('user_program'),
      );
    } catch (e) {
      print('Error loading UserInfo: $e');
      return null;
    }
  }

  /// Clear user info from SharedPreferences
  static Future<void> clearUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('username');
      await prefs.remove('user_profile_pic');
      await prefs.remove('user_role');
      await prefs.remove('user_email');
      await prefs.remove('user_school');
      await prefs.remove('user_program');
      print('UserInfo cleared from SharedPreferences');
    } catch (e) {
      print('Error clearing UserInfo: $e');
    }
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('user_id') && prefs.containsKey('username');
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }
}

// Current user singleton
UserInfo? currentUser;
