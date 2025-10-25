import 'package:flutter/material.dart';
import 'app.dart';
import 'data/api/dio_client.dart'; // Path to your DioClient.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DioClient.init(); // Wait for Dio to set up cookies
  runApp(const MyApp());
}
