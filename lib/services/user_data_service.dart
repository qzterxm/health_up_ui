
import 'dart:convert';
import 'package:http/http.dart' as http;

class AverageUserData {
  final double averageHeartRate;
  final int averageSystolic;
  final int averageDiastolic;
  final int latestHeartRate;
  final int latestHeight;
  final String bloodGroup;
  final int latestWeight;
  final double imt;
  final double latestSugar;

  AverageUserData({
    required this.averageHeartRate,
    required this.averageSystolic,
    required this.averageDiastolic,
    required this.latestHeartRate,
    required this.latestHeight,
    required this.bloodGroup,
    required this.latestWeight,
    required this.imt,
    required this.latestSugar,
  });

  factory AverageUserData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    if (data == null) {
      return AverageUserData.empty();
    }

    String getFriendlyBloodGroup(String? enumString) {
      if (enumString == null || enumString.isEmpty || enumString == 'N/A') {
        return 'N/A';
      }
      return enumString.replaceAll('_', '').replaceAll('Positive', '+').replaceAll('Negative', '-');
    }


    return AverageUserData(
      averageHeartRate: (data['averageHeartRate'] as num?)?.toDouble() ?? 0.0,
      averageSystolic: (data['averageSystolic'] as num?)?.toInt() ?? 0,
      averageDiastolic: (data['averageDiastolic'] as num?)?.toInt() ?? 0,
      latestHeartRate: (data['latestHeartRate'] as num?)?.toInt() ?? 0,
      latestHeight: (data['latestHeight'] as num?)?.toInt() ?? 0,
      bloodGroup: getFriendlyBloodGroup(data['bloodGroup']?.toString()),
      latestWeight: (data['latestWeight'] as num?)?.toInt() ?? 0,
      imt: (data['imt'] as num?)?.toDouble() ?? 0.0,
      latestSugar: (data['latestSugar'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory AverageUserData.empty() {
    return AverageUserData(
      averageHeartRate: 0.0,
      averageSystolic: 0,
      averageDiastolic: 0,
      latestHeartRate: 0,
      latestHeight: 0,
      bloodGroup: 'N/A',
      latestWeight: 0,
      imt: 0.0,
      latestSugar: 0.0,
    );
  }
}

class UserDataService {
  static const String baseUrl = "http://localhost:5299/api/calculation";

  static Future<Map<String, dynamic>> addMeasurement({
    required String userId,
    required DateTime measuredAt,
    required int systolic,
    required int diastolic,
    required int heartRate,
  }) async {
    final url = Uri.parse('$baseUrl/add-measurement');
    final headers = {"Content-Type": "application/json"};

    final body = jsonEncode({
      "userId": userId,
      "measuredAt": measuredAt.toIso8601String(),
      "systolic": systolic,
      "diastolic": diastolic,
      "heartRate": heartRate,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return {
          "success": true,
          "message": decoded["message"] ?? "Measurement added successfully",
          "data": decoded["data"],
        };
      } else {
        final errorBody = jsonDecode(response.body);
        return {
          "success": false,
          "message": errorBody["message"] ?? "Failed to add measurement: ${response.body}",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "An error occurred: $e",
      };
    }
  }

  static Future<Map<String, dynamic>> addAnthropometry({
    required String userId,
    required DateTime measuredAt,
    required double weight,
    required double height,
    required double sugar,
    required String bloodType,
  }) async {
    final url = Uri.parse('$baseUrl/add-anthropometry');
    final headers = {"Content-Type": "application/json"};

    final body = jsonEncode({
      "userId": userId,
      "measuredAt": measuredAt.toIso8601String(),
      "weight": weight,
      "height": height.toInt(),
      "sugar": sugar,
      "bloodType": bloodType,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return {
          "success": true,
          "message": decoded["message"] ?? "Anthropometry data added successfully",
          "data": decoded["data"],
        };
      } else {
        final errorBody = jsonDecode(response.body);
        return {
          "success": false,
          "message": errorBody["message"] ?? "Failed to add anthropometry data: ${response.body}",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "An error occurred: $e",
      };
    }
  }

  static Future<Map<String, dynamic>> getAverageData({
    required String userId,
  }) async {
    final url = Uri.parse('$baseUrl/get-average?userId=$userId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

        if (responseBody['success'] == true) {
          return {
            "success": true,
            "message": responseBody["message"] ?? "Average data retrieved successfully",
            "data": AverageUserData.fromJson(responseBody),
          };
        } else {
          return {
            "success": false,
            "message": responseBody["message"] ?? "Failed to retrieve average data",
          };
        }
      } else {
        final errorBody = jsonDecode(response.body);
        return {
          "success": false,
          "message": errorBody["message"] ?? "HTTP Error ${response.statusCode}: ${response.body}",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "An error occurred during fetch: $e",
      };
    }
  }
}