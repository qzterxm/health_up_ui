import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'file_service.dart';

class DoctorVisitService {
  static const String baseUrl = "https://localhost:7223/doctorvisit";
  static const String fileBaseUrl = "https://localhost:7223/file";

  static Future<Map<String, dynamic>> getVisits({required String userId}) async {
    try {
      final url = Uri.parse("$baseUrl/get-visits?userId=$userId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);

        if (decodedBody is List<dynamic>) {
          return {"success": true, "data": decodedBody};
        }

        if (decodedBody is Map<String, dynamic> && decodedBody.containsKey("data") && decodedBody["data"] is List<dynamic>) {
          return {"success": true, "data": decodedBody["data"]};
        }

        return {"success": false, "message": "Unexpected data format for visits."};
      } else {
        final errorBody = jsonDecode(response.body);
        return {"success": false, "message": errorBody["message"] ?? "Failed to load visits: ${response.statusCode}"};
      }
    } catch (e) {
      return {"success": false, "message": "Error retrieving visits: $e"};
    }
  }


  static Future<Map<String, dynamic>> getUserFiles({required String userId}) async {
    final result = await FileService.getUserFiles(userId: userId);

    if (result["success"] == true) {
      final List<dynamic> rawList = result["data"];
      // Конвертуємо JSON у список об'єктів UserFile
      final List<UserFile> files = rawList.map((json) => UserFile.fromJson(json)).toList();
      return {
        "success": true,
        "data": files
      };
    }
    return result;
  }

  static Future<Map<String, dynamic>> addVisit({required DoctorVisit visit}) async {
    try {
      final url = Uri.parse("$baseUrl/add-visit");
      final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(visit.toJson())
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return {
          "success": true,
          "message": "Visit added successfully",
          "data": decoded
        };
      } else {
        final errorBody = jsonDecode(response.body);
        return {"success": false, "message": errorBody["message"] ?? "Failed to add visit: ${response.statusCode}"};
      }
    } catch (e) {
      return {"success": false, "message": "Error adding visit: $e"};
    }
  }

  static Future<Map<String, dynamic>> attachNoteToVisit({
    required String userId,
    required String visitId,
    required File file,
  }) async {

    final uploadResult = await FileService.uploadFile(
      userId: userId,
      file: file,
      visitId: visitId,
    );

    return uploadResult;
  }
}
class DoctorVisit {
  final String? id;
  final String userId;
  final String specialist;
  final String visitType;
  final String diagnosis;
  final String prescription;
  final DateTime visitedAt;

  DoctorVisit({
    this.id,
    required this.userId,
    required this.specialist,
    required this.visitType,
    required this.diagnosis,
    required this.prescription,
    required this.visitedAt,
  });

  factory DoctorVisit.fromJson(Map<String, dynamic> json) {
    return DoctorVisit(
      id: json['id'],
      userId: json['userId'] ?? '',
      specialist: json['specialist'] ?? '',
      visitType: json['visitType'] ?? '',
      diagnosis: json['diagnosis'] ?? '',
      prescription: json['prescription'] ?? '',
      visitedAt: DateTime.parse(json['visitedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'specialist': specialist,
      'visitType': visitType,
      'diagnosis': diagnosis,
      'prescription': prescription,
      'visitedAt': visitedAt.toIso8601String(),
    };
  }
}