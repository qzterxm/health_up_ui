import 'dart:convert';

class TokenService {

  static Map<String, dynamic> decodeJwt(String token) {
    if (token.isEmpty) {
      return {};
    }

    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw const FormatException('Invalid JWT format');
      }

      final payload = parts[1];

      String normalized = base64Url.normalize(payload);
      final String decoded = utf8.decode(base64Url.decode(normalized));

      return json.decode(decoded);
    } catch (e) {
         return {};
    }
  }

  static String? getUserIdFromToken(String token) {
    final payload = decodeJwt(token);
    return payload['nameid'];
  }


  static String? getUserNameFromToken(String token) {
    final payload = decodeJwt(token);
    return (payload['unique_name'] as String?)?.trim();
  }
}