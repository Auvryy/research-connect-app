import 'package:flutter/material.dart';
import 'screens/login/create_account_page.dart';
import 'screens/login/login_page.dart';
import 'screens/home/home_page.dart';
import 'screens/add/create_survey_page.dart';
import 'screens/add/target_audience_page.dart';
import 'screens/add/questions_page.dart';
import 'screens/add/survey_review_page.dart';
import 'models/survey_creation.dart';
import 'data/auth_guard.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inquira',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF151515),
        fontFamily: 'Poppins',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGuard(child: HomePage()),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const CreateAccountPage(),
        '/home': (context) => const AuthGuard(child: HomePage()),
        '/create-survey': (context) => const AuthGuard(child: CreateSurveyPage()),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/create-survey/audience') {
          return MaterialPageRoute(
            builder: (context) => TargetAudiencePage(
              surveyData: settings.arguments as SurveyCreation,
            ),
          );
        }
        if (settings.name == '/create-survey/questions') {
          return MaterialPageRoute(
            builder: (context) => QuestionsPage(
              surveyData: settings.arguments as SurveyCreation,
            ),
          );
        }
        if (settings.name == '/create-survey/review') {
          return MaterialPageRoute(
            builder: (context) => SurveyReviewPage(
              surveyData: settings.arguments as SurveyCreation,
            ),
          );
        }
        return null;
      },
    );
  }
}
