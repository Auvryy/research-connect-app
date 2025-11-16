// lib/data/user_info.dart
import 'package:shared_preferences/shared_preferences.dart';

class UserInfo {
  final int? id;
  final String username;
  final String? name;
  final String? email;
  final String? phone;
  final String? school;
  final String? course;
  final String? profilePicUrl;

  UserInfo({
    this.id,
    required this.username,
    this.name,
    this.email,
    this.phone,
    this.school,
    this.course,
    this.profilePicUrl,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as int?,
      username: json['username'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      school: json['school'] as String?,
      course: json['course'] as String?,
      profilePicUrl: json['profile_pic'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'phone': phone,
      'school': school,
      'course': course,
      'profile_pic': profilePicUrl,
    };
  }

  /// Save user info to SharedPreferences
  static Future<bool> saveUserInfo(UserInfo user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save each field individually for easier access
      await prefs.setInt('user_id', user.id ?? 0);
      await prefs.setString('username', user.username);
      if (user.name != null) await prefs.setString('user_name', user.name!);
      if (user.email != null) await prefs.setString('user_email', user.email!);
      if (user.phone != null) await prefs.setString('user_phone', user.phone!);
      if (user.school != null) await prefs.setString('user_school', user.school!);
      if (user.course != null) await prefs.setString('user_course', user.course!);
      if (user.profilePicUrl != null) await prefs.setString('user_profile_pic', user.profilePicUrl!);
      
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
        name: prefs.getString('user_name'),
        email: prefs.getString('user_email'),
        phone: prefs.getString('user_phone'),
        school: prefs.getString('user_school'),
        course: prefs.getString('user_course'),
        profilePicUrl: prefs.getString('user_profile_pic'),
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
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('user_phone');
      await prefs.remove('user_school');
      await prefs.remove('user_course');
      await prefs.remove('user_profile_pic');
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
