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
  String duration;

  Medication({
    this.id,
    required this.userId,
    required this.nameOfMedication,
    required this.dose,
    required this.times,
    this.weekDays = const [],
    this.type = MedicationType.capsule,
    this.duration = "1 month",
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    final timesJson = json['timesJson'] as String? ?? '[]';
    final timesList = (jsonDecode(timesJson) as List<dynamic>)
        .map((e) => MedicationTime.fromJson(e as Map<String, dynamic>))
        .toList();

    final weekDaysJson = json['weekDaysJson'] as String? ?? '[]';
    final weekDaysList = (jsonDecode(weekDaysJson) as List<dynamic>)
        .map((e) => e as String)
        .toList();

    return Medication(
      id: json['id'],
      userId: json['userId'],
      nameOfMedication: json['nameOfMedication'],
      dose: json['dose'],
      times: timesList,
      weekDays: weekDaysList,
      type: MedicationTypeExtension.fromString(json['type'] as String?),
      duration: json['duration'] as String? ?? '1 month',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "nameOfMedication": nameOfMedication,
      "dose": dose,
      "timesJson": jsonEncode(times.map((e) => e.toJson()).toList()),
      "weekDaysJson": jsonEncode(weekDays),
      "type": type.stringValue,
      "duration": duration,
    };
  }
}
class MedicationService {
  static const String baseUrl = "https://localhost:7223/api/Medications";

  Future<List<Medication>> getMedications(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/$userId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'] as List<dynamic>;
      return data.map((e) => Medication.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load medications');
    }
  }

  Future<Medication> addMedication(Medication medication) async {
    final body = medication.toJson();
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body)['data'];
      return Medication.fromJson(data);
    } else {
      throw Exception('Failed to add medication. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }
  Future<Medication> updateMedication(Medication medication) async {
    if (medication.id == null) {
      throw Exception('Medication ID is missing, cannot update.');
    }

    final body = medication.toJson();
    final response = await http.put(
      Uri.parse('$baseUrl/${medication.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      return Medication.fromJson(data);
    } else {
      throw Exception('Failed to update medication. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }


  Future<bool> deleteMedication(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    return response.statusCode == 200;
  }
}