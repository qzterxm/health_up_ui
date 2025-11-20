import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/medication_service.dart';
import 'dart:async';

class AddMedicationScreen extends StatefulWidget {
  final String userId;
  final Medication? medicationToEdit;
  const AddMedicationScreen({
    super.key,
    required this.userId,
    this.medicationToEdit,
  });

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = MedicationService();

  final _nameController = TextEditingController();
  final _doseController = TextEditingController();

  MedicationType _selectedType = MedicationType.capsule;
  final List<TimeOfDay> _times = [];

  String _duration = "6 months";
  final List<String> _durationOptions = [
    "1 week",
    "2 weeks",
    "1 month",
    "3 months",
    "6 months",
    "1 year",
    "Indefinite"
  ];

  final List<String> _dayNames = const [
    "Sun",
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat"
  ];
  List<bool> _selectedDays = List.generate(7, (index) => true);
  bool get isEditing => widget.medicationToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final med = widget.medicationToEdit!;
      _nameController.text = med.nameOfMedication;
      _doseController.text = med.dose;
      _selectedType = med.type;
      _duration = med.duration;
      _times.addAll(med.times.map((t) => TimeOfDay(
        hour: int.parse(t.time.split(':')[0]),
        minute: int.parse(t.time.split(':')[1]),
      )));
      List<bool> days = List.generate(7, (index) => false);
      for (String dayName in med.weekDays) {
        int index = _dayNames.indexOf(dayName);
        if (index != -1) {
          days[index] = true;
        }
      }
      _selectedDays = days;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null && !_times.contains(time)) {
      setState(() {
        _times.add(time);
        _times.sort((a, b) => a.hour.compareTo(b.hour) == 0
            ? a.minute.compareTo(b.minute)
            : a.hour.compareTo(b.hour));
      });
    }
  }

  Future<void> _selectDuration() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Duration"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _durationOptions.length,
            itemBuilder: (context, index) {
              final duration = _durationOptions[index];
              return ListTile(
                title: Text(duration),
                trailing: _duration == duration
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () => Navigator.pop(context, duration),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _duration = result;
      });
    }
  }

  String _getDurationDisplayText() {
    return _duration;
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one time slot")),
      );
      return;
    }

    final List<String> selectedDayNames = _selectedDays
        .asMap()
        .entries
        .where((e) => e.value)
        .map((e) => _dayNames[e.key])
        .toList();

    final med = Medication(
      id: isEditing ? widget.medicationToEdit!.id : null,
      userId: widget.userId,
      nameOfMedication: _nameController.text,
      dose: _doseController.text,
      weekDays: selectedDayNames,
      duration: _duration,
      type: _selectedType,
      times: _times
          .map((t) => MedicationTime(
          time:
          "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}"))
          .toList(),
    );

    try {
      if (isEditing) {
        await _service.updateMedication(med);
      } else {
        await _service.addMedication(med);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save medication: $e")),
        );
      }
    }
  }

  Future<void> _deleteMedication() async {
    if (!isEditing || widget.medicationToEdit?.id == null) return;

    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Medication?'),
          content: const Text(
              'Are you sure you want to delete this medication reminder? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (didConfirm != true) {
      return;
    }

    try {
      await _service.deleteMedication(widget.medicationToEdit!.id!);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete medication: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit medication" : "New medication"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteMedication,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Type"),
              _buildTypeSelector(),
              const SizedBox(height: 24),
              _buildSectionTitle("General information"),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Name',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) => v!.isEmpty ? "Please enter a name" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _doseController,
                decoration: InputDecoration(
                  hintText: 'Dose (e.g., 30mg, 20ml)',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) => v!.isEmpty ? "Please enter a dose" : null,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle("Timeline & schedule"),
              _buildTimeSelector(),
              const SizedBox(height: 12),
              _buildDurationSelector(),
              const SizedBox(height: 12),
              _buildFrequencySelector(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _saveMedication,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          child: Text(isEditing ? "Save changes" : "Next"),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTypeChip(
          MedicationType.capsule,
          "Capsule",
          const Icon(LucideIcons.pill, size: 28),
        ),

        _buildTypeChip(
          MedicationType.tablet,
          "Tablet",
          SvgPicture.asset(
            'assets/icons/pill.svg',
            color: Colors.green,
            width: 180000,
          ),
        ),

        _buildTypeChip(
          MedicationType.drops,
          "Drops",
          const Icon(LucideIcons.droplet, size: 28),
        ),

        _buildTypeChip(
          MedicationType.other,
          "Other",
          const Icon(Icons.more_horiz, size: 28),
        ),
      ],
    );
  }

  Widget _buildTypeChip(MedicationType type, String label, Widget icon) {
    final isSelected = _selectedType == type;
    final primaryColor = Theme.of(context).primaryColor;
    final iconColor = isSelected ? primaryColor : Colors.grey.shade700;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: IconTheme(
                data: IconThemeData(color: iconColor, size: 28),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                  child: icon,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ..._times.map((time) => Chip(
          label: Text(time.format(context),
              style: const TextStyle(fontWeight: FontWeight.w500)),
          onDeleted: () => setState(() => _times.remove(time)),
          backgroundColor: Colors.grey.shade100,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade200)),
        )),
        GestureDetector(
          onTap: _pickTime,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        title: const Text("Duration", style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(_getDurationDisplayText(),
            style: const TextStyle(color: Colors.black54, fontSize: 14)),
        trailing: const Icon(Icons.arrow_drop_down, color: Colors.black54),
        onTap: _selectDuration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }

  Widget _buildFrequencySelector() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Frequency",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _dayNames[index],
                    style: TextStyle(
                      color: _selectedDays[index]
                          ? Colors.blue
                          : Colors.grey.shade700,
                      fontWeight: _selectedDays[index]
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  Checkbox(
                    value: _selectedDays[index],
                    onChanged: (bool? value) {
                      setState(() {
                        _selectedDays[index] = value ?? false;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}