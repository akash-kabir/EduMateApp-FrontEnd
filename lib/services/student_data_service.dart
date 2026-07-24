import 'dart:convert';
import '../config.dart';
import 'token_refresh_service.dart';

class StudentDataService {
  /// Look up a student's academic details by roll number.
  /// Returns { success: true, data: { rollNo, year, semester, branch, section, electives } }
  /// or { success: false, message: 'Roll number not found' }
  static Future<Map<String, dynamic>> lookupRollNo(String rollNo) async {
    try {
      final response = await TokenRefreshService.authenticatedGet(
        '${Config.studentDataBaseEndpoint}/lookup/$rollNo',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return {
            'success': true,
            'data': data['data'],
          };
        }
      }
      return {
        'success': false,
        'message': 'Roll number not found in student database',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error looking up roll number: $e',
      };
    }
  }
}
