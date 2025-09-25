import 'package:flutter/material.dart';
import 'package:inquira/constants/colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: AppColors.secondaryBG,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Dark Mode"),
            value: false,
            onChanged: (bool value) {
              // TODO: toggle dark mode
            },
          ),
          ListTile(
            title: const Text("Account"),
            subtitle: const Text("Manage your account"),
            onTap: () {},
          ),
          ListTile(
            title: const Text("Privacy"),
            subtitle: const Text("Manage privacy settings"),
            onTap: () {},
          ),
          ListTile(
            title: const Text("Log Out"),
            textColor: Colors.red,
            onTap: () {
              // TODO: log out user
            },
          ),
        ],
      ),
    );
  }
}
