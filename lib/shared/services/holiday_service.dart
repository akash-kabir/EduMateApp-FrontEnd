import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/shared/config.dart';
import 'package:app/shared/services/shared_preferences_service.dart';

class HolidayService {
  static Future<Map<String, dynamic>> fetchHolidays(int year) async {
    final cacheKey = 'holidays_cache_$year';
    
    try {
      final response = await http.get(
        Uri.parse('${Config.holidayBaseEndpoint}/$year')
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          // Cache the data
          await SharedPreferencesService.setString(cacheKey, json.encode(data['data']));
          return {
            'success': true,
            'data': data['data'],
          };
        }
      }
      throw Exception('Failed to fetch holidays');
    } catch (e) {
      // Fallback to offline cache
      final cachedStr = await SharedPreferencesService.getString(cacheKey);
      if (cachedStr != null) {
        try {
          return {
            'success': true,
            'data': json.decode(cachedStr),
          };
        } catch (_) {}
      }

      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}
