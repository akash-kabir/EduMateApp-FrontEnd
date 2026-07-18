import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class HolidayService {
  static Future<Map<String, dynamic>> fetchHolidays(int year) async {
    try {
      final response = await http.get(Uri.parse('${Config.holidayBaseEndpoint}/$year'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'data': data['data'],
          };
        }
      }
      return {
        'success': false,
        'message': 'Failed to fetch holidays',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}
