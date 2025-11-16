import 'package:flutter/material.dart';
import 'package:health_up/main.dart';
import 'package:health_up/pages/profile/security_screen.dart';
import 'package:health_up/pages/welcome_screen.dart';
import 'package:health_up/services/auth_service.dart';
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
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await AuthService.getUserProfile(widget.userId);

      setState(() {
        _isLoading = false;
        if (result["success"] == true && result["data"] != null) {
          _userData = result["data"];
        } else {
          _errorMessage = result["message"] ?? "Failed to load user data";
          // Provide default data to prevent null errors
          _userData = {
            'email': "email@gmail.com", // Use default email instead of widget.userEmail
            'userName': widget.userName,
            'gender': 'Not specified',
            'age': 0,
            'dateOfBirth': 'Not specified',
            'country': 'Not specified',
            'phoneNumber': 'Not specified',
            'userRole': 'User'
          };
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Unexpected error: $e";
        // Provide default data
        _userData = {
          'email': "email@gmail.com", // Use default email instead of widget.userEmail
          'userName': widget.userName,
          'gender': 'Not specified',
          'age': 0,
          'dateOfBirth': 'Not specified',
          'country': 'Not specified',
          'phoneNumber': 'Not specified',
          'userRole': 'User'
        };
      });
    }
  }

  String get _userEmail => _userData?['email'] ?? "email@gmail.com";
  String get _userName => _userData?['userName'] ?? widget.userName;
  String get _userGender => _userData?['gender']?.toString() ?? 'Not specified';
  int get _userAge => _userData?['age'] is int ? _userData!['age'] :
  (_userData?['age'] is String ? int.tryParse(_userData!['age']) ?? 0 : 0);
  String get _userDateOfBirth => _userData?['dateOfBirth']?.toString() ?? 'Not specified';
  String get _userCountry => _userData?['country']?.toString() ?? 'Not specified';
  String get _userPhone => _userData?['phoneNumber']?.toString() ?? 'Not specified';
  String get _userRole => _userData?['userRole']?.toString() ?? 'User';

  void _showEditProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: EditProfileScreen(
            userId: widget.userId,
            userName: _userName,
            userEmail: _userEmail,
            userData: _userData,
            onProfileUpdated: _loadUserData, // Callback to refresh data
          ),
        );
      },
    );
  }

  void _showUserDetailsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("User Details"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow("Name", _userName),
                _buildDetailRow("Email", _userEmail),
                _buildDetailRow("Gender", _userGender),
                _buildDetailRow("Age", _userAge.toString()),
                _buildDetailRow("Date of Birth", _userDateOfBirth),
                _buildDetailRow("Country", _userCountry),
                _buildDetailRow("Phone", _userPhone),
                _buildDetailRow("Role", _userRole),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
  void _showSecurityScreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SecurityScreen(
          userId: widget.userId,
          userEmail: _userEmail,
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value.isEmpty ? "Not specified" : value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              "Unable to load profile",
              style: TextStyle(
                color: Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUserData,
              icon: Icon(Icons.refresh),
              label: Text("Try Again"),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfoCard(_userName, _userEmail),
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
                _buildSettingsTile(
                  "View Details",
                  Icons.info_outline,
                  onTap: _showUserDetailsDialog,
                ),
                _buildSettingsTile("Notification", Icons.notifications_outlined),
                _buildSettingsTile("Preferences", Icons.settings_outlined),
                _buildSettingsTile(
                  "Security",
                  Icons.lock_outline,
                  onTap: _showSecurityScreen, // ← Add this line!
                ),
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
            const SizedBox(height: 24.0),
            _buildSectionHeader("Account"),
            const SizedBox(height: 8.0),
            _buildSettingsList(
              [
                _buildSettingsTile(
                  "Refresh Data",
                  Icons.refresh,
                  onTap: _loadUserData,
                ),
                _buildSettingsTile(
                  "Logout",
                  Icons.logout,
                  onTap: _logout,
                ),
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
          CircleAvatar(
            radius: 30.0,
            backgroundColor: Colors.white.withOpacity(0.3),
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
                if (_userRole.isNotEmpty)
                  Text(
                    _userRole,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
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

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                );
                print("Logout pressed");
              },
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

}