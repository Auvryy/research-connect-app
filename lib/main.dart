import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'data/api/dio_client.dart'; // Path to your DioClient.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences early
  try {
    print('Initializing SharedPreferences...');
    await SharedPreferences.getInstance();
    print('SharedPreferences initialized successfully');
  } catch (e) {
    print('WARNING: SharedPreferences initialization failed: $e');
    print('App will use in-memory storage');
  }
  
  await DioClient.init(); // Wait for Dio to set up cookies
  runApp(const MyApp());
}
