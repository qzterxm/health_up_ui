import 'dart:convert';
import 'package:http/http.dart' as http;

enum MedicationType { capsule, tablet, drops, other }

extension MedicationTypeExtension on MedicationType {
  String get stringValue {
    switch (this) {
      case MedicationType.capsule: return "Capsule";
      case MedicationType.tablet: return "Tablet";
      case MedicationType.drops: return "Drops";
      case MedicationType.other: return "Other";
    }
  }

  static MedicationType fromString(String? value) {
    switch (value) {
      case "Capsule": return MedicationType.capsule;
      case "Tablet": return MedicationType.tablet;
      case "Drops": return MedicationType.drops;
      case "Other": return MedicationType.other;
      default: return MedicationType.other;
    }
  }
}

class MedicationTime {
  final String time;

  MedicationTime({required this.time});

  factory MedicationTime.fromJson(Map<String, dynamic> json) {
    return MedicationTime(time: json['time'] ?? '00:00');
  }

  Map<String, dynamic> toJson() {
    return {"time": time};
  }
}

class Medication {
  String? id;
  String userId;
  String nameOfMedication;
  String dose;
  List<MedicationTime> times;
  List<String> weekDays;
  MedicationType type;
  DateTime startDate;
  DateTime? endDate;
  String duration;

  Medication({
    this.id,
    required this.userId,
    required this.nameOfMedication,
    required this.dose,
    required this.times,
    this.weekDays = const [],
    this.type = MedicationType.capsule,
    DateTime? startDate,
    this.endDate,
    this.duration = "1 month",
  }) : startDate = startDate ?? DateTime.now();

  bool isActiveOnDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);

    if (normalizedDate.isBefore(normalizedStart)) return false;
    if (endDate != null) {
      final normalizedEnd = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (normalizedDate.isAfter(normalizedEnd)) return false;
    }
    return true;
  }

  bool get isActiveToday {
    return isActiveOnDate(DateTime.now());
  }
  DateTime calculateEndDate() {
    final now = DateTime.now();
    switch (duration) {
      case "1 week":
        return now.add(const Duration(days: 7));
      case "2 weeks":
        return now.add(const Duration(days: 14));
      case "1 month":
        return DateTime(now.year, now.month + 1, now.day);
      case "3 months":
        return DateTime(now.year, now.month + 3, now.day);
      case "6 months":
        return DateTime(now.year, now.month + 6, now.day);
      case "1 year":
        return DateTime(now.year + 1, now.month, now.day);
      case "Indefinite":
      default:
        return DateTime(now.year + 10, now.month, now.day);
    }
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    final timesJson = json['timesJson'] as String? ?? '[]';
    final timesList = (jsonDecode(timesJson) as List<dynamic>)
        .map((e) => MedicationTime.fromJson(e as Map<String, dynamic>))
        .toList();

    final weekDaysJson = json['weekDaysJson'] as String? ?? '[]';
    final weekDaysList = (jsonDecode(weekDaysJson) as List<dynamic>)
        .map((e) => e as String)
        .toList();

    DateTime startDate;
    try {
      startDate = DateTime.parse(json['startDate'] ?? DateTime.now().toString());
    } catch (e) {
      startDate = DateTime.now();
    }

    DateTime? endDate;
    try {
      if (json['endDate'] != null) {
        endDate = DateTime.parse(json['endDate']);
      }
    } catch (e) {
      endDate = null;
    }

    return Medication(
      id: json['id'],
      userId: json['userId'],
      nameOfMedication: json['nameOfMedication'],
      dose: json['dose'],
      times: timesList,
      weekDays: weekDaysList,
      type: MedicationTypeExtension.fromString(json['type'] as String?),
      startDate: startDate,
      endDate: endDate,
      duration: json['duration'] as String? ?? '1 month',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "userId": userId,
      "nameOfMedication": nameOfMedication,
      "dose": dose,
      "timesJson": jsonEncode(times.map((e) => e.toJson()).toList()),
      "weekDaysJson": jsonEncode(weekDays),
      "type": type.stringValue,
      "startDate": startDate.toIso8601String(),
      "duration": duration,
    };

    if (endDate != null) {
      data["endDate"] = endDate!.toIso8601String();
    }
    if (id != null) {
      data["id"] = id;
    }

    return data;
  }
}

class MedicationService {
  static const String baseUrl = "https://localhost:7223/api/Medications";

  Future<List<Medication>> getMedications(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$userId'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final data = responseBody['data'] as List<dynamic>;

        final medications = data.map((e) => Medication.fromJson(e)).toList();
        final activeMeds = medications.where((med) => med.isActiveToday).toList();
        return activeMeds;
      } else {
        throw Exception('Failed to load medications. Status: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Medication> addMedication(Medication medication) async {
    try {
      if (medication.endDate == null) {
        medication.endDate = medication.calculateEndDate();
      }
      final body = medication.toJson();

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final data = responseBody['data'];
        return Medication.fromJson(data);
      } else {
        throw Exception('Failed to add medication. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {

      rethrow;
    }
  }

  Future<Medication> updateMedication(Medication medication) async {
    try {
      if (medication.id == null) {
        throw Exception('Medication ID is missing, cannot update.');
      }

      if (medication.endDate == null) {
        medication.endDate = medication.calculateEndDate();
      }

      final body = medication.toJson();

      final response = await http.put(
        Uri.parse('$baseUrl/${medication.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );


      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final data = responseBody['data'];
        return Medication.fromJson(data);
      } else {
        throw Exception('Failed to update medication. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('Exception in updateMedication: $e');
      rethrow;
    }
  }

  Future<bool> deleteMedication(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        return responseBody['success'] == true;
      } else {
        throw Exception('Failed to delete medication. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in deleteMedication: $e');
      rethrow;
    }
  }
}