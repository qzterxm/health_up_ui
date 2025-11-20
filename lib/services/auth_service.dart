import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "https://localhost:7223/api/auth";

  static Future<Map<String, dynamic>> register({
    required String email,
    required String userName,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'userName': userName,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        "success": false,
        "message": "Failed to register user: ${response.statusCode}"
      };
    }
  }
  static Future<void> saveTokens(
      String accessToken, String refreshToken, String expiresAt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessToken);
    await prefs.setString('refreshToken', refreshToken);
    await prefs.setString('expiresAt', expiresAt);
  }

  static Future<Map<String, String?>> getTokens() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'accessToken': prefs.getString('accessToken'),
      'refreshToken': prefs.getString('refreshToken'),
      'expiresAt': prefs.getString('expiresAt'),
    };
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("accessToken");
    await prefs.remove("refreshToken");
    await prefs.remove("expiresAt");
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) return jsonDecode(response.body);
    return {"success": false, "message": "Invalid credentials or user doesn't exist"};
  }

  static const String userBaseUrl = "https://localhost:7223/api/user";

  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final url = Uri.parse('$userBaseUrl/get-by-id?id=$userId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return {
          "success": json["success"] ?? true,
          "message": json["message"] ?? "",
          "data": json["data"],
        };
      } else {
        return {
          "success": false,
          "message": "HTTP ${response.statusCode} error",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Unexpected error: $e"};
    }
  }


  Future<Map<String, dynamic>?> getUserById(String id) async {
    final url = Uri.parse("$baseUrl/api/user/get-by-id?id=$id");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["data"];
    }

    return null;
  }
  static Future<Map<String, dynamic>> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final url = '$baseUrl/users/$userId/change-password';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        print('RESPONSE JSON: $jsonResp');
        return jsonResp;
      }

      return {"success": false, "message": "Failed to change password: HTTP ${response.statusCode}"};
    } catch (e) {
      return {"success": false, "message": "Error changing password: $e"};
    }
  }
  static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    final url = Uri.parse('$baseUrl/request');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if ([200, 400, 500].contains(response.statusCode)) {
        return jsonDecode(response.body);
      } else {
        return {"success": false, "message": "Unexpected server response"};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> recoverPassword({
    required String email,
    required int resetCode,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/recover-password');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "resetCode": resetCode,
          "newPassword": newPassword,
        }),
      );

      if ([200, 400, 500].contains(response.statusCode)) {
        return jsonDecode(response.body);
      } else {
        return {"success": false, "message": "Unexpected server response"};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  Future<bool> updateUser(Map<String, dynamic> user) async {
    final url = "https://localhost:7223/api/user/update-user";

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(user),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    final url = Uri.parse("$userBaseUrl/delete-user?id=$id");
    print("DELETE URL: $url");

    final response = await http.delete(url);
    return response.statusCode == 200;
  }

  Future<void> logout() async {
    await clearTokens();
  }



}
