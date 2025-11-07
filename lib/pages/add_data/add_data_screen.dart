
import 'package:flutter/material.dart';
import 'package:health_up/pages/add_data/add_anthropometry_screen.dart';
import 'package:health_up/pages/add_data/add_measurement_screen.dart';
import 'package:health_up/services/user_data_service.dart';

class AddDataScreen extends StatefulWidget {
  final String userId;

  const AddDataScreen({super.key, required this.userId});

  @override
  State<AddDataScreen> createState() => _AddDataScreenState();
}

class _AddDataScreenState extends State<AddDataScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Health Data'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Material(
        child: Column(
          children: [

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: [
                    _buildSegment('Measurement', 0),
                    _buildSegment('Anthropometry', 1),
                  ],
                ),
              ),
            ),

            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  AddMeasurementScreen(userId: widget.userId),
                  AddAnthropometryScreen(userId: widget.userId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(String title, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[600] : Colors.transparent,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}