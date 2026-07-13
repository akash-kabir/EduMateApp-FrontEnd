import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'shared_preferences_service.dart';

/// Service to handle silent token refresh when the access token expires.
/// 
/// Usage:
/// ```dart
/// // Before making an authenticated request, ensure a valid token:
/// final token = await TokenRefreshService.getValidToken();
/// if (token == null) {
///   // Redirect to login
/// }
/// ```
class TokenRefreshService {
  static bool _isRefreshing = false;

  /// Attempts to refresh the access token using the stored refresh token.
  /// Returns the new access token on success, or null if refresh fails.
  static Future<String?> refreshToken() async {
    if (_isRefreshing) return null;
    _isRefreshing = true;

    try {
      final refreshToken = await SharedPreferencesService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('No refresh token available');
        return null;
      }

      final response = await http.post(
        Uri.parse(Config.refreshEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final newToken = data['token'] as String;
          final newRefreshToken = data['refreshToken'] as String;

          await SharedPreferencesService.setToken(newToken);
          await SharedPreferencesService.setRefreshToken(newRefreshToken);

          debugPrint('Token refreshed successfully');
          return newToken;
        }
      }

      debugPrint('Token refresh failed: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Returns a valid access token. If the current token results in a 401,
  /// it will attempt a silent refresh. Returns null if both fail (user must re-login).
  static Future<String?> getValidToken() async {
    final token = await SharedPreferencesService.getToken();
    if (token == null || token.isEmpty) {
      // Try refreshing
      return await refreshToken();
    }
    return token;
  }

  /// Makes an authenticated GET request with automatic token refresh on 401.
  static Future<http.Response> authenticatedGet(String url) async {
    var token = await SharedPreferencesService.getToken();

    var response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    // If 401, try refreshing the token and retry once
    if (response.statusCode == 401) {
      final newToken = await refreshToken();
      if (newToken != null) {
        response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
        );
      }
    }

    return response;
  }

  /// Makes an authenticated POST request with automatic token refresh on 401.
  static Future<http.Response> authenticatedPost(String url, {Map<String, dynamic>? body}) async {
    var token = await SharedPreferencesService.getToken();

    var response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body != null ? jsonEncode(body) : null,
    );

    // If 401, try refreshing the token and retry once
    if (response.statusCode == 401) {
      final newToken = await refreshToken();
      if (newToken != null) {
        response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
          body: body != null ? jsonEncode(body) : null,
        );
      }
    }

    return response;
  }

  /// Makes an authenticated PUT request with automatic token refresh on 401.
  static Future<http.Response> authenticatedPut(String url, {Map<String, dynamic>? body}) async {
    var token = await SharedPreferencesService.getToken();

    var response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body != null ? jsonEncode(body) : null,
    );

    // If 401, try refreshing the token and retry once
    if (response.statusCode == 401) {
      final newToken = await refreshToken();
      if (newToken != null) {
        response = await http.put(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
          body: body != null ? jsonEncode(body) : null,
        );
      }
    }

    return response;
  }
}
