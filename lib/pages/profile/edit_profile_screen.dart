import 'package:flutter/material.dart';
import 'package:health_up/services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userEmail;
  final Map<String, dynamic>? userData;
  final VoidCallback? onProfileUpdated;

  const EditProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userData,
    this.onProfileUpdated,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;
  late TextEditingController _phoneController;
  late TextEditingController _countryController;
  late TextEditingController _ageController;
  late TextEditingController _passwordController;

  String? _selectedGender;
  bool _isSaving = false;

  String formatDateForApi(String input) {
    // Converts DD/MM/YYYY -> YYYY-MM-DD
    final parts = input.split('/');
    if (parts.length != 3) return input;
    final day = parts[0].padLeft(2, '0');
    final month = parts[1].padLeft(2, '0');
    final year = parts[2];
    return "$year-$month-$day";
  }
  final List<String> _genders = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with user data
    _fullNameController = TextEditingController(text: widget.userName);
    _emailController = TextEditingController(text: widget.userEmail);
    _dobController = TextEditingController(
        text: widget.userData?['dateOfBirth'] ?? "20/05/2005"
    );
    _phoneController = TextEditingController(
        text: widget.userData?['phoneNumber'] ?? ""
    );
    _countryController = TextEditingController(
        text: widget.userData?['country'] ?? ""
    );
    _ageController = TextEditingController(
        text: widget.userData?['age']?.toString() ?? ""
    );
    _passwordController = TextEditingController();
    _selectedGender = widget.userData?['gender'] ?? 'Male';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_fullNameController.text.isEmpty || _emailController.text.isEmpty) {
      _showSnackBar("Please fill in all required fields");
      return;
    }

    setState(() => _isSaving = true);

    try {
      final auth = AuthService();

      // Форматування даних перед відправкою
      final formattedPhone = _phoneController.text.startsWith('+')
          ? _phoneController.text
          : '${_phoneController.text}';
      final formattedCountry = _countryController.text.trim().isNotEmpty
          ? '${_countryController.text[0].toUpperCase()}${_countryController.text.substring(1)}'
          : 'Unknown';
      final formattedDob = formatDateForApi(_dobController.text);
      final gender = _selectedGender ?? 'Male';

      final payload = {
        "id": widget.userId,
        "email": _emailController.text,
        "userName": _fullNameController.text,
        "password": _passwordController.text.isNotEmpty
            ? _passwordController.text
            : widget.userData?["password"] ?? "",
        "gender": gender,
        "age": int.tryParse(_ageController.text) ?? widget.userData?["age"] ?? 0,
        "dateOfBirth": formattedDob,
        "country": formattedCountry,
        "phoneNumber": formattedPhone,
        "userRole": widget.userData?["userRole"] ?? "User",
        "profilePictureUrl": widget.userData?["profilePictureUrl"] ?? "",
      };

      // 🔹 Логи для перевірки перед відправкою
      print("=== UPDATE USER PAYLOAD ===");
      payload.forEach((key, value) => print("$key: $value"));
      print("============================");

      final result = await auth.updateUser(payload);

      setState(() => _isSaving = false);

      // 🔹 Логи після отримання відповіді
      print("=== UPDATE USER RESULT ===");
      print(result);
      print("===========================");

      if (result) {
        _showSnackBar("Profile updated successfully!");
        widget.onProfileUpdated?.call();

        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) Navigator.of(context).pop();
        });
      } else {
        _showSnackBar("Failed to update profile. Check backend logs.");
      }
    } catch (e) {
      setState(() => _isSaving = false);
      print("=== UPDATE USER ERROR ===");
      print(e);
      print("==========================");
      _showSnackBar("An error occurred: $e");
    }
  }



  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24.0),

            Text(
              "Personal Information",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 24.0),

            Stack(
              children: [
                const CircleAvatar(
                  radius: 50.0,
                  backgroundColor: Colors.grey,
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      // TODO: Add photo logic
                      print("Edit photo tapped!");
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32.0),

            _buildInputField(
              "Full Name *",
              Icons.person_outline,
              _fullNameController,
              isEditable: true,
            ),
            const SizedBox(height: 16.0),

            _buildInputField(
              "Email Address *",
              Icons.mail_outline,
              _emailController,
              isEditable: true,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16.0),

            _buildInputField(
              "Phone Number",
              Icons.phone_outlined,
              _phoneController,
              isEditable: true,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16.0),

            _buildInputField(
              "Country",
              Icons.location_on_outlined,
              _countryController,
              isEditable: true,
            ),
            const SizedBox(height: 16.0),

            _buildInputField(
              "Age",
              Icons.cake_outlined,
              _ageController,
              isEditable: true,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16.0),

            _buildGenderDropdown(),
            const SizedBox(height: 16.0),

            _buildInputField(
              "Date of Birth",
              Icons.calendar_today_outlined,
              _dobController,
              isEditable: true,
              readOnly: true,
              onTap: () => _selectDate(context),
            ),

            const SizedBox(height: 32.0),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                icon: _isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.check, color: Colors.white),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save Changes',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
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
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8.0),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          style: TextStyle(color: Colors.grey[900], fontSize: 16),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            suffixIcon: isEditable && !readOnly
                ? Icon(Icons.edit_outlined, color: Colors.grey[400])
                : null,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14.0,
              horizontal: 16.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Gender",
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8.0),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedGender,
            onChanged: (String? newValue) {
              setState(() {
                _selectedGender = newValue;
              });
            },
            items: _genders.map((String gender) {
              return DropdownMenuItem<String>(
                value: gender,
                child: Text(gender),
              );
            }).toList(),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.transgender, color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14.0,
                horizontal: 16.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            colorScheme: const ColorScheme.light(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Save in DD/MM/YYYY format for display
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

}