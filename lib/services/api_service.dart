import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class ApiService {
  // Persistent HTTP client for connection pooling
  static final http.Client _httpClient = http.Client();

  // Helper method for GET requests
  static Future<Map<String, dynamic>> _makeGetRequest(String url) async {
    try {
      final response = await _httpClient.get(Uri.parse(url));
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
      final response = await _httpClient.post(
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
      final response = await _httpClient.post(
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

  // ==================== Profile Management ====================

  /// Check if user has completed their profile setup
  static Future<Map<String, dynamic>> checkProfileStatus({
    required String userId,
    required String token,
  }) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('${Config.checkProfileStatusEndpoint}/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'isProfileCompleted': data['isProfileCompleted'] ?? false,
          'data': data,
        };
      } else {
        return {'success': false, 'message': 'Failed to check profile status'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Get user's complete profile data
  static Future<Map<String, dynamic>> getUserProfile({
    required String token,
  }) async {
    try {
      final response = await _httpClient.get(
        Uri.parse(Config.getProfileDataEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Failed to fetch profile data'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Update user's profile with roll number, year, and semester
  static Future<Map<String, dynamic>> updateUserProfile({
    required String token,
    required String rollNo,
    required String year,
    required String semester,
    required String branch,
  }) async {
    try {
      final response = await _httpClient.put(
        Uri.parse(Config.updateProfileEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'rollNo': rollNo,
          'year': year,
          'semester': semester,
          'branch': branch,
          'isProfileCompleted': true,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Profile updated successfully',
          'data': data,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Update user profile with additional fields
  static Future<Map<String, dynamic>> updateUserProfileWithFields({
    required String token,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      // Ensure isProfileCompleted is set to true
      profileData['isProfileCompleted'] = true;

      final response = await _httpClient.put(
        Uri.parse(Config.updateProfileEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(profileData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Profile updated successfully',
          'data': data,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
