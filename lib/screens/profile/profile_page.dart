import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/widgets/profile_survey.dart';
import 'package:inquira/widgets/profile_info_item.dart';
import 'package:inquira/data/user_info.dart';
import 'package:inquira/data/survey_service.dart';
import 'package:inquira/models/survey.dart';

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
    _loadUserSurveys();
  }

  Future<void> _loadUserSurveys() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current user ID
      final userId = await SurveyService.getCurrentUserId();
      
      // Load user's surveys from local storage
      final surveys = await SurveyService.getUserSurveys(userId);
      
      setState(() {
        _userSurveys = surveys;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user surveys: $e');
      setState(() {
        _userSurveys = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          // wrap everything in a column
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Profile Header ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('assets/images/guts-image.jpeg'),
                ),
                const SizedBox(width: 16), // spacing between image and text
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUser?.name ?? currentUser?.username ?? 'User',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (currentUser?.course != null)
                      Text(
                        currentUser!.course!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.secondary,
                        ),
                      ),
                    if (currentUser?.course != null) const SizedBox(height: 2),
                    if (currentUser?.school != null)
                      Text(
                        currentUser!.school!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.secondary,
                        ),
                      ),
                  ],
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
                  text: "Profile Information",
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
                            child: ProfileSurvey(survey: survey),
                          );
                        }).toList(),
                      )
            else
              Column(
                children: [
                  ProfileInfoItem(
                    icon: Icons.person,
                    label: "Full Name",
                    value: currentUser?.name ?? currentUser?.username ?? 'Not set',
                    iconColor: AppColors.blue,
                  ),
                  ProfileInfoItem(
                    icon: Icons.mail,
                    label: "Email",
                    value: currentUser?.email ?? 'Not set',
                    iconColor: AppColors.purple,
                  ),
                  ProfileInfoItem(
                    icon: Icons.phone,
                    label: "Phone Number",
                    value: currentUser?.phone ?? 'Not set',
                    iconColor: AppColors.green,
                  ),
                  ProfileInfoItem(
                    icon: Icons.school,
                    label: "School",
                    value: currentUser?.school ?? 'Not set',
                    iconColor: AppColors.orange,
                  ),
                  ProfileInfoItem(
                    icon: Icons.book,
                    label: "Course",
                    value: currentUser?.course ?? 'Not set',
                    iconColor: AppColors.pink,
                  ),
                ],
              ),
          ],
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
