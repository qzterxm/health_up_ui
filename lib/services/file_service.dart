import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io';

class UserFile {
  final String id;
  final String? userId;
  final String fileName;
  final String contentType;
  final DateTime uploadedAt;
  final String? visitId;

  UserFile({
    required this.id,
    this.userId,
    required this.fileName,
    required this.contentType,
    required this.uploadedAt,
    this.visitId,
  });

  factory UserFile.fromJson(Map<String, dynamic> json) {
    return UserFile(
      id: json['id'] ?? '',
      userId: json['userId'],
      fileName: json['fileName'] ?? '',
      contentType: json['contentType'] ?? '',
      uploadedAt: DateTime.parse(json['uploadedAt'] ?? DateTime.now().toIso8601String()),
      visitId: json['visitId'],
    );
  }
}

class FileService {
  static const String baseUrl = "https://localhost:7223/file";

  static Future<Map<String, dynamic>> getUserFiles({required String userId, String? token}) async {
    try {
      final url = Uri.parse("$baseUrl/user-files?userId=$userId");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        return jsonData;
      } else {

        return {
          "success": false,
          "message": "Server error: ${response.statusCode}"
        };
      }
    } catch (e) {

      return {"success": false, "message": "Error retrieving files: $e"};
    }
  }

  static Future<Map<String, dynamic>> uploadFile({
    required String userId,
    required File file,
    String? visitId,
  }) async {
    try {
      var url = Uri.parse('$baseUrl/upload?userId=$userId');
      if (visitId != null && visitId.isNotEmpty) {
        url = Uri.parse('$baseUrl/upload?userId=$userId&visitId=$visitId');
      }

      var request = http.MultipartRequest('POST', url);

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType('application', 'octet-stream'),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return {
          "success": true,
          "message": decoded["message"] ?? "File uploaded successfully",
          "data": UserFile.fromJson(decoded["data"] ?? {}),
        };
      } else {
        final errorBody = jsonDecode(response.body);
        return {
          "success": false,
          "message": errorBody["message"] ?? "Failed to upload file: ${response.body}",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "An error occurred: $e",
      };
    }
  }

  static Future<Map<String, dynamic>> downloadFile({
    required String userId,
    required String fileId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/download?userId=$userId&fileId=$fileId');

      final response = await http.get(url);

      if (response.statusCode == 200) {

        final contentType = response.headers['content-type'] ?? 'application/octet-stream';
        final contentDisposition = response.headers['content-disposition'] ?? '';
        String fileName = 'downloaded_file';

        final filenameMatch = RegExp(r'filename="([^"]+)"').firstMatch(contentDisposition);
        if (filenameMatch != null) {
          fileName = filenameMatch.group(1)!;
        }

        return {
          "success": true,
          "data": response.bodyBytes,
          "fileName": fileName,
          "contentType": contentType,
        };
      } else if (response.statusCode == 404) {
        return {
          "success": false,
          "message": "File not found",
        };
      } else {
        final errorBody = jsonDecode(response.body);
        return {
          "success": false,
          "message": errorBody["message"] ?? "Failed to download file: ${response.body}",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "An error occurred: $e",
      };
    }
  }

  static Future<Map<String, dynamic>> deleteFile({
    required String userId,
    required String fileId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/delete?userId=$userId&fileId=$fileId');

      final response = await http.delete(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return {
          "success": true,
          "message": decoded["message"] ?? "File deleted successfully",
        };
      } else {
        final errorBody = jsonDecode(response.body);
        return {
          "success": false,
          "message": errorBody["message"] ?? "Failed to delete file: ${response.body}",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "An error occurred: $e",
      };
    }
  }

  static Future<Map<String, dynamic>> getFileInfo({
    required String userId,
    required String fileId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/info?userId=$userId&fileId=$fileId');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return {
          "success": true,
          "message": decoded["message"] ?? "File info retrieved successfully",
          "data": UserFile.fromJson(decoded["data"] ?? {}),
        };
      } else {
        final errorBody = jsonDecode(response.body);
        return {
          "success": false,
          "message": errorBody["message"] ?? "Failed to get file info",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "An error occurred: $e",
      };
    }
  }
}