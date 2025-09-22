import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inquira/constants/colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // Example pages for navigation
  final List<Widget> _pages = [
    const Center(child: Text("Home Page (Your feed will go here)")),
    const Center(child: Text("Profile Page")),
    const Center(child: Text("Add Page")),
    const Center(child: Text("Settings Page")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
        leading: const Padding(
          padding: EdgeInsets.only(left: 15),
          child: CircleAvatar(
            radius: 16,
            backgroundImage: AssetImage('assets/images/guts-image.jpeg'),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // search functionality
            },
            icon: SvgPicture.asset(
              'assets/icons/search-icon.svg',
              height: 30,
              width: 30,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.secondaryBG,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.secondary,
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: SizedBox(
              height: 40,
              width: 40,
              child: SvgPicture.asset(
                'assets/icons/house-icon.svg',
                color: _currentIndex == 0 ? AppColors.primary : AppColors.secondary,
              ),
            ),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              height: 40,
              width: 40,
              child: SvgPicture.asset(
                'assets/icons/profile-icon.svg',
                color: _currentIndex == 1 ? AppColors.primary: AppColors.secondary,
              ),
            ),
            label: "Profile",
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              height: 40,
              width: 40,
              child: SvgPicture.asset(
                'assets/icons/plus-icon.svg',
                color: _currentIndex == 2 ? AppColors.primary : AppColors.secondary,
              ),
            ),
            label: "Add",
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              height: 40,
              width: 40,
              child: SvgPicture.asset(
                'assets/icons/settings-icon.svg',
                color: _currentIndex == 3 ? AppColors.primary: AppColors.secondary,
              ),
            ),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
