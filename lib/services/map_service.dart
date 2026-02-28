import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import 'shared_preferences_service.dart';

class MapService {
  static const String _mapboxKeyCache = 'mapbox_public_key';

  // Retry logic for handling Vercel cold starts
  static Future<http.Response> _getWithRetry(
    Uri url, {
    Map<String, String>? headers,
    String? body,
    int maxRetries = 2,
    bool isPost = false,
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        late http.Response response;

        if (isPost) {
          response = await http
              .post(url, headers: headers ?? {}, body: body)
              .timeout(const Duration(seconds: 15));
        } else {
          response = await http
              .get(url, headers: headers)
              .timeout(const Duration(seconds: 15));
        }

        return response;
      } catch (e) {
        if (attempt == maxRetries) {
          rethrow;
        }
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
      }
    }
    throw Exception('Max retries exceeded');
  }

  static Future<Map<String, dynamic>> getDirections({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    try {
      final url = Uri.parse('${Config.BASE_URL}/api/maps/directions');
      final response = await _getWithRetry(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'originLat': originLat,
          'originLng': originLng,
          'destinationLat': destinationLat,
          'destinationLng': destinationLng,
        }),
        isPost: true,
        maxRetries: 2,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to get directions');
        }
      } else {
        throw Exception(
          'Failed to get directions (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Error getting directions: $e');
    }
  }

  static Future<String> getMapboxPublicKey() async {
    try {
      // Check cache first
      final cachedKey = await SharedPreferencesService.getString(
        _mapboxKeyCache,
      );
      if (cachedKey != null && cachedKey.isNotEmpty) {
        return cachedKey;
      }

      // Fetch from backend if not cached
      final url = Uri.parse('${Config.BASE_URL}/api/maps/config');
      final response = await _getWithRetry(url, maxRetries: 2);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final publicKey = data['data']['publicKey'];
          // Cache the key for future use
          await SharedPreferencesService.setString(_mapboxKeyCache, publicKey);
          return publicKey;
        } else {
          throw Exception('Failed to get mapbox config');
        }
      } else {
        throw Exception(
          'Failed to get mapbox config (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Error getting mapbox key: $e');
    }
  }
}
