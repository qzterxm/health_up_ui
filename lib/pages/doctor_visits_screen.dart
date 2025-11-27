import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/file_service.dart';
import '../services/token_decoder.dart';

class DoctorVisitsScreen extends StatefulWidget {
  const DoctorVisitsScreen({super.key});

  @override
  State<DoctorVisitsScreen> createState() => _DoctorVisitsScreenState();
}

class _DoctorVisitsScreenState extends State<DoctorVisitsScreen> {
  List<DoctorVisit> visits = [];
  List<UserFile> allUserFiles = [];
  bool isLoading = false;
  String? currentUserId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken");

      if (token == null) {
        if (mounted) _showSnackBar("User not authenticated");
        return;
      }

      final userId = TokenService.getUserIdFromToken(token);
      if (userId == null) {
        if (mounted) _showSnackBar("Failed to decode userId");
        return;
      }

      currentUserId = userId;

      final results = await Future.wait([
        DoctorVisitService.getVisits(userId: userId),
        DoctorVisitService.getUserFiles(userId: userId)
      ]);

      final visitsResult = results[0];
      final filesResult = results[1];

      if (visitsResult["success"] == true) {
        final data = visitsResult["data"] as List<dynamic>;

        if (filesResult["success"] == true) {
          allUserFiles = filesResult["data"] as List<UserFile>;
        }

        if (mounted) {
          setState(() {
            visits = data.map((e) => DoctorVisit.fromJson(e as Map<String, dynamic>)).toList();
            visits.sort((a, b) => b.visitedAt.compareTo(a.visitedAt));
          });
        }
      } else {
        if (mounted) setState(() => _errorMessage = visitsResult["message"]);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = "Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    await _loadVisits();
  }

  Future<void> _attachNoteToVisit(DoctorVisit visit) async {
    if (currentUserId == null || visit.id == null) {
      _showSnackBar("Cannot attach file: missing user or visit ID.");
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) return;

    setState(() => isLoading = true);
    final file = File(result.files.single.path!);

    final uploadResult = await DoctorVisitService.attachNoteToVisit(
      userId: currentUserId!,
      visitId: visit.id!,
      file: file,
    );

    setState(() => isLoading = false);

    if (uploadResult["success"] == true) {
      _showSnackBar("Note/file attached successfully!");
      _loadVisits();
    } else {
      _showSnackBar(uploadResult["message"] ?? "Failed to attach file.");
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddVisitDialog(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Theme.of(context).colorScheme.primary,
        child: Stack(
          children: [
            if (_errorMessage != null)
              ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              )
            else if (visits.isEmpty && !isLoading)
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.medical_services_outlined,
                              size: 64,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No doctor visits recorded yet",
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Tap the '+' button to add your first visit",
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
            else
              ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                itemCount: visits.length,
                itemBuilder: (context, index) {
                  final visit = visits[index];
                  return _buildVisitTile(visit);
                },
              ),

            if (isLoading && visits.isEmpty)
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitTile(DoctorVisit visit) {
    final visitFiles = allUserFiles.where((file) =>
    file.visitId?.toLowerCase() == visit.id?.toLowerCase()).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      color: Theme.of(context).cardColor,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          Icons.medical_services_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          visit.specialist,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          "${_formatDate(visit.visitedAt)} | ${visit.visitType}",
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow("Diagnosis:", visit.diagnosis),
                _detailRow("Prescription:", visit.prescription),

                Divider(color: Theme.of(context).dividerColor),

                if (visitFiles.isNotEmpty) ...[
                  Text(
                    "Attached Files:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 5),
                  ...visitFiles.map((file) => Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.3),
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      leading: Icon(
                        Icons.insert_drive_file,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        file.fileName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      trailing: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                    ),
                  )),
                  const SizedBox(height: 10),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _attachNoteToVisit(visit),
                    icon: const Icon(Icons.attach_file),
                    label: const Text("Attach Note/File"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isId = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? "N/A" : value,
              style: TextStyle(
                fontStyle: isId ? FontStyle.italic : null,
                fontSize: isId ? 12 : 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddVisitDialog(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();

    final specialistController = TextEditingController();
    final visitTypeController = TextEditingController();
    final diagnosisController = TextEditingController();
    final prescriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    bool isSaving = false;

    await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Text(
              "Add New Doctor Visit",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: specialistController,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Specialist',
                        hintText: 'e.g., Cardiologist, Dentist',
                        labelStyle: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        hintStyle: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor.withOpacity(0.5),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter specialist';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: visitTypeController,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Visit Type',
                        hintText: 'e.g., Consultation, Check-up, Emergency',
                        labelStyle: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        hintStyle: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor.withOpacity(0.5),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter visit type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Theme.of(context).colorScheme.primary,
                                        onPrimary: Colors.white,
                                        surface: Theme.of(context).cardColor,
                                        onSurface: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                                      ),
                                      dialogBackgroundColor: Theme.of(context).cardColor,
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (pickedDate != null) {
                                setStateDialog(() {
                                  selectedDate = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    selectedTime.hour,
                                    selectedTime.minute,
                                  );
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Date',
                                labelStyle: TextStyle(
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Theme.of(context).cardColor.withOpacity(0.5),
                              ),
                              child: Text(
                                _formatDate(selectedDate),
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Theme.of(context).colorScheme.primary,
                                        onPrimary: Colors.white,
                                        surface: Theme.of(context).cardColor,
                                        onSurface: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                                      ),
                                      dialogBackgroundColor: Theme.of(context).cardColor,
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (pickedTime != null) {
                                setStateDialog(() {
                                  selectedTime = pickedTime;
                                  selectedDate = DateTime(
                                    selectedDate.year,
                                    selectedDate.month,
                                    selectedDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Time',
                                labelStyle: TextStyle(
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Theme.of(context).cardColor.withOpacity(0.5),
                              ),
                              child: Text(
                                selectedTime.format(context),
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: diagnosisController,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Diagnosis',
                        hintText: 'Medical diagnosis or findings',
                        labelStyle: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        hintStyle: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor.withOpacity(0.5),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: prescriptionController,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Prescription',
                        hintText: 'Medications, treatments, recommendations',
                        labelStyle: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        hintStyle: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor.withOpacity(0.5),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context, false),
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  if (_formKey.currentState!.validate() && currentUserId != null) {
                    final newVisit = DoctorVisit(
                      userId: currentUserId!,
                      specialist: specialistController.text.trim(),
                      visitType: visitTypeController.text.trim(),
                      diagnosis: diagnosisController.text.trim(),
                      prescription: prescriptionController.text.trim(),
                      visitedAt: selectedDate,
                    );

                    setStateDialog(() {
                      isSaving = true;
                    });

                    final result = await DoctorVisitService.addVisit(visit: newVisit);

                    if (context.mounted) {
                      if (result["success"] == true) {
                        _showSnackBar("Visit added successfully!");
                        Navigator.pop(context, true);
                      } else {
                        setStateDialog(() {
                          isSaving = false;
                        });
                        _showSnackBar(result["message"] ?? "Failed to add visit");
                      }
                    }
                  } else if (currentUserId == null) {
                    _showSnackBar("User not authenticated");
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  "Save Visit",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    ).then((result) {
      if (result == true) {
        _loadVisits();
      }
    });
  }
}