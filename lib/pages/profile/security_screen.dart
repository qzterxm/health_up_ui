import 'package:flutter/material.dart';
import 'package:health_up/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../welcome_screen.dart';

class SecurityScreen extends StatefulWidget {
  final String userId;
  final String userEmail;
  final Map<String, dynamic>? userData;
  final VoidCallback? onSecurityUpdated;

  const SecurityScreen({
    super.key,
    required this.userId,
    required this.userEmail,
    this.userData,
    this.onSecurityUpdated,
  });

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _emailController;

  bool _isSavingPassword = false;
  bool _isSavingEmail = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _emailController = TextEditingController(text: widget.userEmail);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      _showSnackBar("Please fill all password fields");
      return;
    }

    setState(() => _isSavingPassword = true);

    try {
      // 1. Get current user data
      final profileResult = await AuthService.getUserProfile(widget.userId);
      if (profileResult['success'] != true) {
        setState(() => _isSavingPassword = false);
        _showSnackBar("Failed to load user profile");
        return;
      }

      final userData = profileResult['data'] ?? {};

      // 2. Verify current password
      final loginResult = await AuthService.login(
        email: userData['email'],
        password: _currentPasswordController.text,
      );

      if (loginResult['success'] != true) {
        setState(() => _isSavingPassword = false);
        _showSnackBar("Current password is incorrect");
        return;
      }

      // 3. Prepare user object with only password updated
      final auth = AuthService();
      final updatedUser = {
        "id": widget.userId,
        "email": userData['email'], // keep current email
        "userName": userData['userName'] ?? 'user',
        "password": _newPasswordController.text, // new password
        "gender": userData['gender'] ?? 'Male',
        "age": userData['age'] ?? 0,
        "dateOfBirth": userData['dateOfBirth'] ?? '2000-01-01',
        "country": userData['country'] ?? 'Ukraine',
        "phoneNumber": userData['phoneNumber'] ?? '+380000000000',
        "userRole": userData['userRole'] ?? 'User',
        "profilePictureUrl": userData['profilePictureUrl'] ?? '',
      };

      // 4. Call update-user endpoint
      final result = await auth.updateUser(updatedUser);

      setState(() => _isSavingPassword = false);

      if (result) {
        _showSnackBar("Password changed successfully!");
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        _showSnackBar("Failed to change password");
      }
    } catch (e) {
      setState(() => _isSavingPassword = false);
      _showSnackBar("Error: $e");
    }
  }

  Future<void> _changeEmail() async {
    if (!_isValidEmail(_emailController.text)) {
      _showSnackBar("Invalid email");
      return;
    }

    setState(() => _isSavingEmail = true);

    try {
      final profileResult = await AuthService.getUserProfile(widget.userId);
      if (profileResult['success'] != true) {
        setState(() => _isSavingEmail = false);
        _showSnackBar("Failed to load user profile");
        return;
      }

      final userData = profileResult['data'] ?? {};

      // Ask for current password
      final password = await _showPasswordDialog();
      if (password == null) {
        setState(() => _isSavingEmail = false);
        return;
      }

      final loginResult = await AuthService.login(
        email: userData['email'],
        password: password,
      );

      if (loginResult['success'] != true) {
        setState(() => _isSavingEmail = false);
        _showSnackBar("Password incorrect. Email not updated");
        return;
      }

      final auth = AuthService();
      final updatedUser = {
        "id": widget.userId,
        "email": _emailController.text, // new email
        "userName": userData['userName'] ?? 'user',
        "password": password, // current password
        "gender": userData['gender'] ?? 'Male',
        "age": userData['age'] ?? 0,
        "dateOfBirth": userData['dateOfBirth'] ?? '2000-01-01',
        "country": userData['country'] ?? 'Ukraine',
        "phoneNumber": userData['phoneNumber'] ?? '+380000000000',
        "userRole": userData['userRole'] ?? 'User',
        "profilePictureUrl": userData['profilePictureUrl'] ?? '',
      };

      final result = await auth.updateUser(updatedUser);

      setState(() => _isSavingEmail = false);

      if (result) {
        _showSnackBar("Email updated successfully!");
        widget.onSecurityUpdated?.call();
      } else {
        _showSnackBar("Failed to update email");
      }
    } catch (e) {
      setState(() => _isSavingEmail = false);
      _showSnackBar("Error: $e");
    }
  }



  Future<void> _confirmDeleteAccount() async {
    final passwordController = TextEditingController();
    bool obscure = true;

    final password = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text("Delete Account"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "This action cannot be undone.\n\nPlease enter your password to confirm:",
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: "Current Password",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => obscure = !obscure);
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () =>
                    Navigator.pop(context, passwordController.text),
                child: const Text("Delete",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );

    if (password == null || password.isEmpty) return;
    await _deleteAccount(password);
  }



  Future<void> _deleteAccount(String password) async {
    final loginResult = await AuthService.login(
      email: widget.userEmail,
      password: password,
    );

    if (loginResult['success'] != true) {
      _showSnackBar('Password incorrect. Account not deleted.');
      return;
    }

    final auth = AuthService();
    final deleteResult = await auth.deleteUser(widget.userId);

    if (deleteResult) {
      _showSnackBar('Your account has been deleted.');

      // Clear saved tokens/preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Redirect to WelcomeScreen and remove SecurityScreen from stack
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    } else {
      _showSnackBar('Failed to delete account.');
    }
  }


  Future<String?> _showPasswordDialog() async {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Please enter your current password to continue:"),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: "Current Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(obscurePassword
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(passwordController.text),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getValidPhoneNumber(dynamic phoneNumber) {
    if (phoneNumber == null || phoneNumber.toString().isEmpty) {
      return '+380000000000';
    }
    String phone = phoneNumber.toString();
    if (phone.startsWith('+')) return phone;
    if (phone.startsWith('0')) return '+38$phone';
    if (phone.length >= 9) return '+380$phone';
    return '+380000000000';
  }

  String _formatGender(dynamic gender) {
    if (gender == null) return 'Male';
    if (gender is String) return gender;
    if (gender == 1) return 'Female';
    if (gender == 0) return 'Male';
    return 'Male';
  }

  String _formatDateOfBirth(dynamic dateOfBirth) {
    if (dateOfBirth == null) return '2000-01-01';
    if (dateOfBirth is String) {
      if (dateOfBirth.contains('-')) return dateOfBirth;
      try {
        final date = DateTime.parse(dateOfBirth);
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      } catch (_) {
        return '2000-01-01';
      }
    }
    return '2000-01-01';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Security Settings",
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 24),

            // Change Password Section
            _buildSectionHeader("Change Password"),
            const SizedBox(height: 16),
            _buildPasswordField(
              "Current Password",
              Icons.lock_outline,
              _currentPasswordController,
              obscureText: _obscureCurrentPassword,
              onToggleObscure: () {
                setState(() {
                  _obscureCurrentPassword = !_obscureCurrentPassword;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              "New Password",
              Icons.lock_reset_outlined,
              _newPasswordController,
              obscureText: _obscureNewPassword,
              onToggleObscure: () {
                setState(() {
                  _obscureNewPassword = !_obscureNewPassword;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              "Confirm New Password",
              Icons.lock_reset_outlined,
              _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              onToggleObscure: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSavingPassword ? null : _changePassword,
                icon: _isSavingPassword
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.lock, color: Colors.white),
                label: Text(
                  _isSavingPassword ? 'Changing Password...' : 'Change Password',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),

            // Change Email Section
            _buildSectionHeader("Change Email Address"),
            const SizedBox(height: 16),
            _buildInputField("New Email Address", Icons.mail_outline, _emailController,
                isEditable: true, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSavingEmail ? null : _changeEmail,
                icon: _isSavingEmail
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.mail, color: Colors.white),
                label: Text(
                  _isSavingEmail ? 'Updating Email...' : 'Change Email',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),

            // Delete Account Section
            _buildSectionHeader("Delete Account"),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _confirmDeleteAccount,
                icon: const Icon(Icons.delete_forever, color: Colors.white),
                label: const Text("Delete My Account",
                    style: TextStyle(fontSize: 18, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Icon(Icons.security_outlined, color: Colors.grey[600], size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                color: Colors.grey[800], fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInputField(
      String label,
      IconData icon,
      TextEditingController controller, {
        bool isEditable = false,
        TextInputType keyboardType = TextInputType.text,
        bool readOnly = false,
        VoidCallback? onTap,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          style: TextStyle(color: Colors.grey[900], fontSize: 16),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            suffixIcon:
            isEditable && !readOnly ? Icon(Icons.edit_outlined, color: Colors.grey[400]) : null,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(
      String label,
      IconData icon,
      TextEditingController controller, {
        required bool obscureText,
        required VoidCallback onToggleObscure,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: TextStyle(color: Colors.grey[900], fontSize: 16),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            suffixIcon: IconButton(
              icon: Icon(
                  obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.grey[600]),
              onPressed: onToggleObscure,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ],
    );
  }
}
