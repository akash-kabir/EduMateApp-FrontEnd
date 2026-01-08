import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class ApiService {
  // Helper method for GET requests
  static Future<Map<String, dynamic>> _makeGetRequest(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'available': false, 'message': 'Error: Server error'};
      }
    } catch (e) {
      return {'available': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> checkUsernameAvailability(
    String username,
  ) async {
    return _makeGetRequest(
      '${Config.BASE_URL}/api/users/check-username/$username',
    );
  }

  static Future<Map<String, dynamic>> checkEmailAvailability(
    String email,
  ) async {
    return _makeGetRequest(
      '${Config.BASE_URL}/api/users/check-email?email=$email',
    );
  }

  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(Config.registerEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message':
              jsonDecode(response.body)['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(Config.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usernameOrEmail': usernameOrEmail,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
