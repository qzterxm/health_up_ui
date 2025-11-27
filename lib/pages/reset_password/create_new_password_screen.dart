import 'package:flutter/material.dart';
import 'package:health_up/pages/sign_in_screen.dart';
import 'package:health_up/services/auth_service.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  final String email;
  final int resetCode;

  const CreateNewPasswordScreen({
    super.key,
    required this.email,
    required this.resetCode,
  });

  @override
  State<CreateNewPasswordScreen> createState() => _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Стиль для підказок (сірий текст під полями)
    final TextStyle hintStyle = TextStyle(
        color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey[500],
        fontSize: 13
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Create New Password',
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Enter new password below to complete the reset process',
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 16
                ),
              ),
              const SizedBox(height: 32.0),


              TextField(
                controller: _passwordController,
                obscureText: _isPasswordHidden,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 14
                  ),
                  prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.6)
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordHidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordHidden = !_isPasswordHidden;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0, left: 12.0),
                child: Text('Password must contain at least 6 characters',
                    style: hintStyle),
              ),
              const SizedBox(height: 24.0),


              TextField(
                controller: _confirmPasswordController,
                obscureText: _isConfirmPasswordHidden,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  labelText: 'Confirm password',
                  labelStyle: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 14
                  ),
                  prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.6)
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordHidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordHidden = !_isConfirmPasswordHidden;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0, left: 12.0),
                child: Text('Password must be identical', style: hintStyle),
              ),
              const SizedBox(height: 48.0),


              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                onPressed: _isLoading
                    ? null
                    : () async {
                  final newPassword = _passwordController.text.trim();
                  final confirmPassword =
                  _confirmPasswordController.text.trim();

                  if (newPassword.isEmpty || confirmPassword.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Enter and confirm password")),
                    );
                    return;
                  }
                  if (newPassword != confirmPassword) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Password doesn't match")),
                    );
                    return;
                  }
                  if (newPassword.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "Password must contain at least 6 characters")),
                    );
                    return;
                  }

                  setState(() => _isLoading = true);

                  final result = await AuthService.recoverPassword(
                    email: widget.email,
                    resetCode: widget.resetCode,
                    newPassword: newPassword,
                  );

                  setState(() => _isLoading = false);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result["message"])),
                  );

                  if (result["success"]) {

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SignInScreen(),
                      ),
                          (route) => false,
                    );
                  }
                },
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Reset Password',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}