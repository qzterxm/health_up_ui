import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/medication_service.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';

class MedicationSchedule extends StatefulWidget {
  final String userId;
  const MedicationSchedule({super.key, required this.userId});

  @override
  State<MedicationSchedule> createState() => _MedicationScheduleState();
}
class _MedicationScheduleState extends State<MedicationSchedule> {
  final MedicationService _service = MedicationService();
  late Future<List<Medication>> _medicationsFuture;
  final Set<String> _takenMedIds = {};
  final Set<String> _skippedMedIds = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    _takenMedIds.clear();
    _skippedMedIds.clear();

    setState(() {
      _medicationsFuture = _service.getMedications(widget.userId);
    });
  }

  void _navigateToAddScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicationScreen(
          userId: widget.userId,
          medicationToEdit: null,
        ),
      ),
    );
    if (result == true) {
      _refresh();
    }
  }
  void _navigateToEditScreen(Medication med) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicationScreen(
          userId: widget.userId,
          medicationToEdit: med,
        ),
      ),
    );
    if (result == true) {
      _refresh();
    }
  }
  Future<String?> _showMedicationMenu(
      BuildContext context, RelativeRect position, Medication med) async {
    if (med.id == null) return null;

    return showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem<String>(
          value: 'take',
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Text('Take'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, color: Colors.blue),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddScreen,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Medication>>(
        future: _medicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final meds = snapshot.data ?? [];

          final Map<String, List<Medication>> groupedMeds = {};
          for (final med in meds) {
            for (final time in med.times) {
              groupedMeds.putIfAbsent(time.time, () => []).add(med);
            }
          }
          final sortedTimes = groupedMeds.keys.toList()..sort();

          if (meds.isEmpty) {
            return const Center(
              child: Text(
                "No medications scheduled.\nTap '+' to add one.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final TimeOfDay now = TimeOfDay.now();
          final double nowInMinutes = now.hour * 60.0 + now.minute;
          String? currentActiveTimeGroup;

          for (final timeStr in sortedTimes) {
            final groupTime = TimeOfDay(
                hour: int.parse(timeStr.split(':')[0]),
                minute: int.parse(timeStr.split(':')[1]));
            final groupTimeInMinutes =
                groupTime.hour * 60.0 + groupTime.minute;

            if (groupTimeInMinutes <= nowInMinutes) {
              currentActiveTimeGroup = timeStr;
            } else {
              break;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  children: const [
                    SizedBox(
                      width: 70,
                      child: Text(
                        "Time",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Medication",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...sortedTimes.map((time) {
                final medsAtTime = groupedMeds[time]!;
                final bool isActive = (time == currentActiveTimeGroup); 
                return _buildTimeGroup(context, time, medsAtTime,
                    isActive: isActive);
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeGroup(
      BuildContext context, String rawTime, List<Medication> meds,
      {bool isActive = false}) { 
    final displayTime = _formatDisplayTime(context, rawTime);

    return Padding(
      padding: const EdgeInsets.only(bottom: 0), 
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              displayTime,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 24),

          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: -25,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.blue.shade300
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < meds.length; i++) ...[
                      _buildMedicationCard(meds[i], isActive: isActive),
                      if (i < meds.length - 1)
                        Divider(
                          color: (isActive
                              ? Colors.blue.shade300
                              : Colors.grey.shade300)
                              .withOpacity(0.5),
                          height: 16,
                          thickness: 1,
                          indent: 16,
                          endIndent: 16,
                        )
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildMedicationCard(Medication med, {bool isActive = false}) {
    final bool isTaken = med.id != null && _takenMedIds.contains(med.id);
    final bool isSkipped = med.id != null && _skippedMedIds.contains(med.id);
    final bool isDone = isTaken || isSkipped;

    final Color bgColor = isTaken
        ? Colors.green.shade100.withOpacity(0.4)
        : isSkipped
        ? Colors.red.shade100.withOpacity(0.4)
        : isActive
        ? Colors.blue.withOpacity(0.18)
        : Colors.grey.shade200;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.nameOfMedication,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getDoseSubtitle(med),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'take' && med.id != null) {
                setState(() {
                  _takenMedIds.add(med.id!);
                  _skippedMedIds.remove(med.id!);
                });
              } else if (value == 'edit') {
                _navigateToEditScreen(med);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'take',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Take'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: med.type == MedicationType.tablet
                  ? SvgPicture.asset(
                'assets/icons/pill.svg',
                color: Colors.green,
              )
                  : Icon(
                med.type == MedicationType.capsule
                    ? LucideIcons.pill
                    : LucideIcons.droplet,
                color: med.type == MedicationType.capsule
                    ? Colors.blue
                    : Colors.orange,
                size: 26,
              ),
            ),
          )
        ],
      ),
    );
  }
  (IconData, Color) _getMedicationTypeVisuals(MedicationType type) {
    switch (type) {
      case MedicationType.capsule:
        return (LucideIcons.pill, const Color(0xFF6C77FF));
      case MedicationType.tablet:
        return (LucideIcons.circle, const Color(0xFF8BC34A));
      case MedicationType.drops:
        return (LucideIcons.droplet, const Color(0xFFFF8A65));
      default:
        return (Icons.more_horiz, const Color(0xFFBA68C8));
    }
  }

  String _getDoseSubtitle(Medication med) {
    switch (med.type) {
      case MedicationType.capsule:
        return "1 capsule";
      case MedicationType.tablet:
        return "1 tablet";
      case MedicationType.drops:
        return "${med.dose.split(' ')[0]} drops";
      default:
        return med.dose;
    }
  }

  String _formatDisplayTime(BuildContext context, String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute).format(context);
    } catch (e) {
      return time;
    }
  }
}


class AddMedicationScreen extends StatefulWidget {
  final String userId;
  final Medication? medicationToEdit;
  const AddMedicationScreen({super.key, required this.userId, this.medicationToEdit,});

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

  Future<void> _editDuration() async {
    final controller = TextEditingController(text: _duration);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit duration"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "e.g., 7 days, 2 weeks, 3 months",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _duration = result;
      });
    }
  }
  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one time slot")),
      );
      return;
    }

    final List<String> selectedDayNames = _selectedDays.asMap().entries
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
              _buildScheduleTile("Duration", _duration, _editDuration),
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
        _buildTypeChip(MedicationType.capsule, "Capsule", LucideIcons.pill),
        _buildTypeChip(MedicationType.tablet, "Tablet", LucideIcons.circle), //TODO:change icon for svg
        _buildTypeChip(MedicationType.drops, "Drops", LucideIcons.droplet),
        _buildTypeChip(MedicationType.other, "Other", Icons.more_horiz),
      ],
    );
  }

  Widget _buildTypeChip(MedicationType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    final color = Theme.of(context).primaryColor;

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
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected ? color : Colors.grey.shade700, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
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

  Widget _buildScheduleTile(String title, String value, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: const TextStyle(color: Colors.black54, fontSize: 16)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.black54),
          ],
        ),
        onTap: onTap,
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