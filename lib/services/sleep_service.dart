import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class SleepEntry {
  final String id;
  final String userId;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final int totalDurationMinutes;
  final int sleepScore;
  final String sleepStatus;

  SleepEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.totalDurationMinutes,
    required this.sleepScore,
    required this.sleepStatus,
  });

  double get totalHours => totalDurationMinutes / 60.0;
  double get remHours => (totalDurationMinutes * 0.25) / 60.0;

  factory SleepEntry.fromJson(Map<String, dynamic> json) {
    return SleepEntry(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      date: DateTime.parse(json['date']),
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      totalDurationMinutes: json['totalDurationMinutes'] ?? 0,
      sleepScore: json['sleepScore'] ?? 0,
      sleepStatus: json['sleepStatus'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.isEmpty ? null : id,
      'userId': userId,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'startTime': startTime.toUtc().toIso8601String(),
      'endTime': endTime.toUtc().toIso8601String(),
      'totalDurationMinutes': totalDurationMinutes,
      'sleepScore': sleepScore,
      'sleepStatus': sleepStatus,
    };
  }
}

class SleepService {
  static const String baseUrl = "https://localhost:7223/api/sleep";

  Future<List<SleepEntry>> getSleepHistory(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/$userId');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((item) => SleepEntry.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load sleep data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching sleep history: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSleepHistoryWithStats(String userId) async {
    try {
      final data = await getSleepHistory(userId);

      final Map<DateTime, SleepEntry> sleepMap = {};
      for (var entry in data) {
        final normalizedDate = DateTime.utc(entry.date.year, entry.date.month, entry.date.day);
        sleepMap[normalizedDate] = entry;
      }

      final stats = _calculateStatistics(data);

      return {
        'sleepHistory': sleepMap,
        'statistics': stats
      };
    } catch (e) {
      print('Error: $e');
      return {
        'sleepHistory': <DateTime, SleepEntry>{},
        'statistics': {'Message': 'No sleep data available'}
      };
    }
  }

  Map<String, dynamic> _calculateStatistics(List<SleepEntry> data) {
    if (data.isEmpty) return {'Message': 'No sleep data available'};

    final now = DateTime.now();
    final last7Days = data.where((s) => s.date.isAfter(now.subtract(const Duration(days: 7)))).toList();
    final last30Days = data.where((s) => s.date.isAfter(now.subtract(const Duration(days: 30)))).toList();

    double avgDuration7 = last7Days.isNotEmpty
        ? last7Days.map((s) => s.totalHours).reduce((a, b) => a + b) / last7Days.length
        : 0.0;

    double avgDuration30 = last30Days.isNotEmpty
        ? last30Days.map((s) => s.totalHours).reduce((a, b) => a + b) / last30Days.length
        : 0.0;

    double avgScore7 = last7Days.isNotEmpty
        ? last7Days.map((s) => s.sleepScore).reduce((a, b) => a + b) / last7Days.length
        : 0.0;

    return {
      'AverageDurationLast7Days': avgDuration7,
      'AverageDurationLast30Days': avgDuration30,
      'AverageScoreLast7Days': avgScore7,
      'BestSleepDay': data.isNotEmpty
          ? data.reduce((a, b) => a.sleepScore > b.sleepScore ? a : b).date.toIso8601String()
          : null,
    };
  }

  Future<bool> addSleepEntry(SleepEntry entry) async {
    try {
      final url = Uri.parse(baseUrl);
      final Map<String, dynamic> requestBody = {
        'userId': entry.userId,
        'date': DateFormat('yyyy-MM-dd').format(entry.date),
        'startTime': entry.startTime.toUtc().toIso8601String(),
        'endTime': entry.endTime.toUtc().toIso8601String(),
      };


      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error adding sleep entry: $e');
      return false;
    }
  }
}