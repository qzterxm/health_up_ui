
import 'package:flutter/material.dart';
import 'package:health_up/main.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String _userEmail = "solokha.nataliy@gmail.com";
  void _showEditProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: EditProfileScreen(
            userName: widget.userName,
            userEmail: _userEmail,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfoCard(
              widget.userName,
              _userEmail,
            ),
            const SizedBox(height: 24.0),
            _buildSectionHeader("General Settings"),
            const SizedBox(height: 8.0),
            _buildSettingsList(
              [
                _buildSettingsTile(
                  "Personal Info",
                  Icons.person_outline,
                  onTap: _showEditProfileSheet,
                ),
                _buildSettingsTile("Notification", Icons.notifications_outlined),
                _buildSettingsTile("Preferences", Icons.settings_outlined),
                _buildSettingsTile("Security", Icons.lock_outline),
              ],
            ),
            const SizedBox(height: 24.0),
            _buildSectionHeader("Accessibility"),
            const SizedBox(height: 8.0),
            _buildSettingsList(
              [
                _buildSettingsTile("Language", Icons.language_outlined),
                _buildSettingsTile(
                  "Dark Mode",
                  Icons.dark_mode_outlined,
                  hasToggle: true,
                  isToggled: isDarkMode,
                  onToggle: (value) {
                    MyApp.of(context)?.changeTheme(
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            _buildSectionHeader("Help & Support"),
            const SizedBox(height: 8.0),
            _buildSettingsList(
              [
                _buildSettingsTile("About", Icons.info_outline),
                _buildSettingsTile("Help Center", Icons.help_outline),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(String name, String email) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30.0,
            backgroundColor: Colors.grey,
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: _showEditProfileSheet,
          ),
        ],
      ),
    );
  }

  // Заголовок секції (напр. "General Settings")
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.grey[700],
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }
  Widget _buildSettingsList(List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: tiles.asMap().entries.map((entry) {
          int idx = entry.key;
          Widget tile = entry.value;
          return Column(
            children: [
              tile,
              if (idx < tiles.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsTile(
      String title,
      IconData icon, {
        bool hasToggle = false,
        VoidCallback? onTap,
        bool isToggled = false,
        ValueChanged<bool>? onToggle,
      }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: hasToggle
          ? Switch(
        value: isToggled,
        onChanged: onToggle,
        activeColor: Colors.blue,
      )
          : Icon(
        Icons.arrow_forward_ios,
        size: 16.0,
        color: Colors.grey[600],
      ),
      onTap: hasToggle ? null : onTap,
    );
  }
}