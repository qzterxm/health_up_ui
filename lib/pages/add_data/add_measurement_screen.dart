
import 'package:flutter/material.dart';
import 'package:health_up/services/user_data_service.dart';

class AddMeasurementScreen extends StatefulWidget {
  final String userId;

  const AddMeasurementScreen({super.key, required this.userId});

  @override
  State<AddMeasurementScreen> createState() => _AddMeasurementScreenState();
}

class _AddMeasurementScreenState extends State<AddMeasurementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _heartRateController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    super.dispose();
  }

  Future<void> _submitMeasurement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final result = await UserDataService.addMeasurement(
      userId: widget.userId,
      measuredAt: DateTime.now(),
      systolic: int.parse(_systolicController.text),
      diastolic: int.parse(_diastolicController.text),
      heartRate: int.parse(_heartRateController.text),
    );

    setState(() {
      _isLoading = false;
    });

    if (result["success"] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["message"] ?? "Measurement added successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop(true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["message"] ?? "Failed to add measurement"),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                'Blood Pressure & Heart Rate',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16.0),

              TextFormField(
                controller: _systolicController,
                decoration: const InputDecoration(
                  labelText: 'Systolic Pressure (mmHg)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monitor_heart),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter systolic value';
                  }
                  final val = int.tryParse(value);
                  if (val == null || val < 50 || val > 250) {
                    return 'Please enter a valid systolic value (50-250)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              TextFormField(
                controller: _diastolicController,
                decoration: const InputDecoration(
                  labelText: 'Diastolic Pressure (mmHg)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monitor_heart),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter diastolic value';
                  }
                  final val = int.tryParse(value);
                  if (val == null || val < 30 || val > 150) {
                    return 'Please enter a valid diastolic value (30-150)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              TextFormField(
                controller: _heartRateController,
                decoration: const InputDecoration(
                  labelText: 'Heart Rate (BPM)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.favorite),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter heart rate';
                  }
                  final val = int.tryParse(value);
                  if (val == null || val < 30 || val > 200) {
                    return 'Please enter a valid heart rate (30-200)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32.0),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitMeasurement,
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
                    'Add Measurement',
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
}