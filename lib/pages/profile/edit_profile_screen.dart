
import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  const EditProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {

  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.userName);
    _emailController = TextEditingController(text: widget.userEmail);
    _dobController = TextEditingController(text: "20/05/2005");
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    print("Full Name: ${_fullNameController.text}");
    print("Email: ${_emailController.text}");
    print("Date of Birth: ${_dobController.text}");
    Navigator.of(context).pop();
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
                      // TODO:lогіка фото
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
              "Full Name",
              Icons.person_outline,
              _fullNameController,
              isEditable: true,
            ),
            const SizedBox(height: 16.0),

            _buildInputField(
              "Email Address",
              Icons.mail_outline,
              _emailController,
              isEditable: true,
              keyboardType: TextInputType.emailAddress,
            ),
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
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 18, color: Colors.white),
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
            buttonTheme:
            const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            colorScheme: const ColorScheme.light(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }
}