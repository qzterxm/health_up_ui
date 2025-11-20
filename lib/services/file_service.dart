import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io';

class UserFile {
  final String id;
  final String? userId;
  final String fileName;
  final DateTime uploadedAt;
  final String? visitId;
  final String? contentType;

  UserFile({
    required this.id,
    this.userId,
    required this.fileName,
    this.contentType,
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

class UserNote {
  final String id;
  final String userId;
  final DateTime createdAt;
  final String noteText;

  UserNote({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.noteText,
  });

  factory UserNote.fromJson(Map<String, dynamic> json) {
    return UserNote(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      noteText: json['noteText'] ?? '',
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
        final decodedBody = json.decode(response.body);

        if (decodedBody is Map<String, dynamic> && decodedBody.containsKey("data") && decodedBody["data"] is List<dynamic>) {
          return {"success": true, "data": decodedBody["data"]};
        } else if (decodedBody is List<dynamic>) {
          return {"success": true, "data": decodedBody};
        }

        return {"success": false, "message": "Successful status but unexpected file data format."};

      } else {
        final errorBody = jsonDecode(response.body);
        return {"success": false, "message": errorBody["message"] ?? "Server error: ${response.statusCode}"};
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


class NoteService {
  static const String baseUrl = "https://localhost:7223";

  static Future<Map<String, dynamic>> getNotes({required String userId}) async {
    try {
      final url = Uri.parse("$baseUrl/get-note?userId=$userId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);

        if (decodedBody is List<dynamic>) {
          return {"success": true, "data": decodedBody};
        } else if (decodedBody is Map<String, dynamic> && decodedBody.containsKey("data") && decodedBody["data"] is List<dynamic>) {
          return {"success": true, "data": decodedBody["data"]};
        }

        return {"success": false, "message": "Unexpected note data format."};

      } else {
        final errorBody = jsonDecode(response.body);
        return {"success": false, "message": errorBody["message"] ?? "Failed to load notes: ${response.statusCode}"};
      }
    } catch (e) {
      return {"success": false, "message": "Error retrieving notes: $e"};
    }
  }

  static Future<Map<String, dynamic>> addNote({required String userId, required String text}) async {
    try {
      final url = Uri.parse("$baseUrl/add-note");

      final body = jsonEncode({
        "userId": userId,
        "noteText": text,
        "createdAt": DateTime.now().toIso8601String(),
      });

      final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: body
      );

      if (response.statusCode == 200) {
        return {"success": true, "message": "Note added successfully"};
      } else {
        final errorBody = jsonDecode(response.body);
        return {"success": false, "message": errorBody["message"] ?? "Failed to add note: ${response.statusCode}"};
      }
    } catch (e) {
      return {"success": false, "message": "Error adding note: $e"};
    }
  }

  static Future<Map<String, dynamic>> deleteNote({required String userId, required String noteId}) async {
    try {
      final url = Uri.parse("$baseUrl/delete-note?userId=$userId&noteId=$noteId");
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        return {"success": true, "message": "Note deleted successfully"};
      } else {
        final errorBody = jsonDecode(response.body);
        return {"success": false, "message": errorBody["message"] ?? "Failed to delete note: ${response.statusCode}"};
      }
    } catch (e) {
      return {"success": false, "message": "Error deleting note: $e"};
    }
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
      id: json['id'] ?? json['Id'],
      userId: json['userId'] ?? '',
      specialist: json['specialist'] ?? 'N/A',
      visitType: json['visitType'] ?? 'N/A',
      diagnosis: json['diagnosis'] ?? 'N/A',
      prescription: json['prescription'] ?? 'N/A',
      visitedAt: DateTime.tryParse(json['visitedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "specialist": specialist,
      "visitType": visitType,
      "diagnosis": diagnosis,
      "prescription": prescription,
      "visitedAt": visitedAt.toIso8601String(),
    };
  }
}


class DoctorVisitService {
  static const String baseUrl = "https://localhost:7223/doctorvisit";

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
        return {"success": true, "message": "Visit added successfully"};
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