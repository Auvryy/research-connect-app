import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inquira/constants/colors.dart';
import 'package:inquira/screens/add/create_survey_page.dart';
import 'package:inquira/data/user_info.dart';

// Import your new pages
import 'package:inquira/screens/home/home_feed.dart';
import 'package:inquira/screens/profile/profile_page.dart';
import 'package:inquira/screens/settings/settings_page.dart';

class HomePage extends StatefulWidget {
  final int initialTab;
  
  const HomePage({super.key, this.initialTab = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      // AddSurvey → new page without bottom nav
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreateSurveyPage()),
      );
      return;
    }
    if (index == 4) {
      // Settings → new page without bottom nav
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage()),
      );
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  /// ✅ Builds different AppBars depending on tab
  PreferredSizeWidget? _buildAppBar() {
    if (_currentIndex == 0) {
      // Home AppBar
      return AppBar(
        backgroundColor: AppColors.secondaryBG,
        centerTitle: true,
        title: const Text(
          "Inquira",
          style: TextStyle(
            fontSize: 24,
            fontFamily: 'Giaza',
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _currentIndex = 1; // jump to Profile tab
              });
            },
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: currentUser?.profilePicUrl != null && currentUser!.profilePicUrl!.isNotEmpty
                  ? NetworkImage(currentUser!.profilePicUrl!)
                  : null,
              child: currentUser?.profilePicUrl == null || currentUser!.profilePicUrl!.isEmpty
                  ? Icon(
                      Icons.person,
                      size: 20,
                      color: AppColors.primary.withOpacity(0.5),
                    )
                  : null,
            ),
          ),
        ),
        actions: const [
          SizedBox(width: 12), // Keep some padding
        ],
      );
    } else if (_currentIndex == 1) {
      // Profile AppBar
      return AppBar(
        backgroundColor: AppColors.secondaryBG,
        centerTitle: true,
        title: const Text(
          "Profile",
          style: TextStyle(
            fontFamily: 'Giaza',
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (_currentIndex == 3) {
      return AppBar(
        backgroundColor: AppColors.secondaryBG,
        centerTitle: true,
        title: const Text(
          "My Surveys",
          style: TextStyle(
            fontFamily: 'Giaza',
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return null;
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const HomeFeed();
      case 1:
        return const ProfilePage(key: ValueKey('profile-others'), forcedTab: 1); // Others only
      case 3:
        return const ProfilePage(key: ValueKey('profile-my-surveys'), forcedTab: 0); // My Surveys only
      default:
        return const HomeFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.secondaryBG,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.secondary,
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/house-icon.svg',
              height: 30,
              color: _currentIndex == 0 ? AppColors.primary : AppColors.secondary,
            ),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/profile-icon.svg',
              height: 30,
              color: _currentIndex == 1 ? AppColors.primary : AppColors.secondary,
            ),
            label: "Profile",
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/plus-icon.svg',
              height: 30,
              color: AppColors.primary,
            ),
            label: "Add",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt, size: 28, color: _currentIndex == 3 ? AppColors.primary : AppColors.secondary),
            label: "My Surveys",
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/settings-icon.svg',
              height: 30,
              color: AppColors.secondary, // stays grey
            ),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
