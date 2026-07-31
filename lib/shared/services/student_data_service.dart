import 'dart:convert';
import 'package:app/shared/config.dart';
import 'package:app/features/auth_and_profile/services/token_refresh_service.dart';

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
      final errorStr = e.toString();
      if (errorStr.contains('SocketException') || 
          errorStr.contains('ClientException') || 
          errorStr.contains('TimeoutException')) {
        return {
          'success': false,
          'message': 'No internet connection. Please try again.',
        };
      }
      
      return {
        'success': false,
        'message': 'Error looking up roll number: $e',
      };
    }
  }
}
