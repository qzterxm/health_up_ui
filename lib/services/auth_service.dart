import 'dart:convert';
import 'package:http/http.dart' as http;


class AuthService {
  //10.0.2.2
  static const String baseUrl = "http://localhost:5299/api/auth";

  static Future<Map<String, dynamic>> register({
    required String email,
    required String userName,
    required String password,
    String role = "User",
  }) async {
    final url = Uri.parse('$baseUrl/register');

    final body = jsonEncode({
      "email": email,
      "userName": userName,
      "password": password,
      "role": role
    });

    final headers = {"Content-Type": "application/json"};

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return {
        "success": true,
        "data": jsonDecode(response.body),
      };
    } else {
      return {
        "success": false,
        "message": response.body,
      };
    }
  }


  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    final url = Uri.parse('$baseUrl/login');

    final body = jsonEncode({
      "email": email,
      "password": password,
      "rememberMe": rememberMe
    });

    final headers = {"Content-Type": "application/json"};

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      return {
        "success": true,
        "message": decoded["message"],
        "accessToken": decoded["data"]["accessToken"],
        "refreshToken": decoded["data"]["refreshToken"],
        "expiresAt": decoded["data"]["expiresAt"],
      };
    } else {
      return {
        "success": false,
        "message": "Login failed: ${response.body}",
      };
    }
  }


  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
    int resetCode = 0,
  }) async {
    final url = Uri.parse('$baseUrl/recover-password');

    final body = jsonEncode({
      "email": email,
      "resetCode": resetCode,
      "newPassword": newPassword
    });

    final headers = {"Content-Type": "application/json"};

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return {"success": true, "message": "Password reset successful"};
    } else if (response.statusCode == 401) {
      return {"success": false, "message": "Unauthorized (invalid code or email)"};
    } else {
      return {"success": false, "message": response.body};
    }
  }



  static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    final url = Uri.parse('$baseUrl/request');
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({"email": email});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        "success": data["success"],
        "message": data["message"] ?? "Password reset code sent"
      };
    } else {
      return {
        "success": false,
        "message": "Error: ${response.body}"
      };
    }
  }

  static Future<Map<String, dynamic>> recoverPassword({
    required String email,
    required int resetCode,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/recover-password');
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "email": email,
      "resetCode": resetCode,
      "newPassword": newPassword
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        "success": data["success"],
        "message": data["message"] ?? "Password reset successful"
      };
    } else {
      return {
        "success": false,
        "message": "Error: ${response.body}"
      };
    }
  }
}
