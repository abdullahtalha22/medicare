// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0f8b8e), Color(0xFF2a86d6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _glassTile(
              context,
              icon: Icons.person,
              title: "Account",
              subtitle: "Manage your profile",
              iconColor: Colors.blueAccent,
              textColor: textColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _glassTile(
              context,
              icon: themeProvider.isDarkMode
                  ? Icons.dark_mode
                  : Icons.light_mode,
              title: "Dark Mode",
              subtitle: "Switch app theme",
              iconColor: themeProvider.isDarkMode ? Colors.amber : Colors.blue,
              textColor: textColor,
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (val) => themeProvider.toggleTheme(val),
              ),
            ),
            const SizedBox(height: 12),
            _glassTile(
              context,
              icon: Icons.info,
              title: "About",
              subtitle: "MediCare v1.0.0",
              iconColor: Colors.green,
              textColor: textColor,
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: "MediCare",
                  applicationVersion: "1.0.0",
                  applicationIcon: const Icon(Icons.medical_services,
                      color: Colors.blue, size: 40),
                  children: const [
                    Text(
                        "MediCare helps you track and manage your medicines with reminders, schedules, and insights."),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            _glassTile(
              context,
              icon: Icons.logout,
              title: "Logout",
              subtitle: "Sign out from your account",
              iconColor: Colors.redAccent,
              textColor: textColor,
              onTap: () {
                // Add your logout logic here
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color iconColor,
        required Color textColor,
        VoidCallback? onTap,
        Widget? trailing,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.4),
              Colors.white.withOpacity(0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 13, color: textColor.withOpacity(0.7))),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
