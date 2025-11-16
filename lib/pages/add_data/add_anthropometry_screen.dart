
import 'package:flutter/material.dart';
import 'package:health_up/services/user_data_service.dart';

class AddAnthropometryScreen extends StatefulWidget {
  final String userId;

  const AddAnthropometryScreen({super.key, required this.userId});

  @override
  State<AddAnthropometryScreen> createState() => _AddAnthropometryScreenState();
}

class _AddAnthropometryScreenState extends State<AddAnthropometryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _sugarController = TextEditingController();

  String _selectedBloodType = 'O_Positive';
  bool _isLoading = false;

  final List<String> _bloodTypes = [
    'A_Positive',
    'A_Negative',
    'B_Positive',
    'B_Negative',
    'AB_Positive',
    'AB_Negative',
    'O_Positive',
    'O_Negative',
  ];

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _sugarController.dispose();
    super.dispose();
  }

  Future<void> _submitAnthropometry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final weight = double.parse(_weightController.text);
      final height = double.parse(_heightController.text);
      final sugar = double.parse(_sugarController.text);

      // Логи перед запитом
      debugPrint('=== ADD ANTHROPOMETRY REQUEST ===');
      debugPrint('UserId: ${widget.userId}');
      debugPrint('Weight: $weight, Height: $height, Sugar: $sugar');
      debugPrint('BloodType: $_selectedBloodType');
      debugPrint('MeasuredAt: ${DateTime.now()}');

      final result = await UserDataService.addAnthropometry(
        userId: widget.userId,
        measuredAt: DateTime.now(),
        weight: weight,
        height: height,
        sugar: sugar,
        bloodType: _selectedBloodType,
      );

      // Лог результату
      debugPrint('=== ADD ANTHROPOMETRY RESPONSE ===');
      debugPrint(result.toString());

      if (result["success"] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result["message"] ?? "Anthropometry data added successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result["message"] ?? "Failed to add anthropometry data"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('=== ADD ANTHROPOMETRY ERROR ===');
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Material(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Body Measurements & Blood Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16.0),

              // Weight Input
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter weight';
                  }
                  final val = double.tryParse(value);
                  if (val == null || val <= 0 || val > 300) {
                    return 'Please enter a valid weight (1-300 kg)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Height Input
              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.height),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter height';
                  }
                  final val = double.tryParse(value);
                  if (val == null || val <= 0 || val > 250) {
                    return 'Please enter a valid height (1-250 cm)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Sugar Level Input
              TextFormField(
                controller: _sugarController,
                decoration: const InputDecoration(
                  labelText: 'Sugar Level (mmol/L)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.bloodtype),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter sugar level';
                  }
                  final val = double.tryParse(value);
                  if (val == null || val < 0 || val > 50) {
                    return 'Please enter a valid sugar level (0-50 mmol/L)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Blood Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedBloodType,
                decoration: const InputDecoration(
                  labelText: 'Blood Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.bloodtype),
                ),
                items: _bloodTypes.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(_formatBloodTypeForDisplay(value)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedBloodType = newValue!;
                  });
                },
              ),
              const SizedBox(height: 32.0),


              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitAnthropometry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    'Add Anthropometry Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBloodTypeForDisplay(String bloodType) {
    return bloodType.replaceAll('_', ' ');
  }
}