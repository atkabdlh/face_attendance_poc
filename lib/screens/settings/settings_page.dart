import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: Text('Coach Name'),
              subtitle: const Text('Last updated: 12/12/2023'),
              onTap: () {
                // Navigate to change password screen
              },
            ),
            ListTile(
              title: Text('Logout'),
              onTap: () {
                // Navigate to change password screen
              },
            ),
          ],
        ),
      ),
    );
  }
}
