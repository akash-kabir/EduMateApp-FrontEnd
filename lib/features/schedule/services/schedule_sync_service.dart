import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:app/shared/config.dart';
import 'package:app/features/auth_and_profile/services/token_refresh_service.dart';
import 'package:app/features/schedule/services/schedule_database_helper.dart';

class ScheduleSyncService {
  /// Fetches both the normal timetable and electives in parallel and caches them in SQLite.
  /// Handles semesters with no electives gracefully.
  static Future<void> prefetchAllScheduleData(int semester) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Futures
    final scheduleFuture = _fetchAndCacheSchedule(semester, timestamp);
    final electiveFuture = _fetchAndCacheElectives(semester, timestamp);

    // Run both in parallel
    await Future.wait([scheduleFuture, electiveFuture]);
  }

  static Future<void> _fetchAndCacheSchedule(int semester, int timestamp) async {
    try {
      final url = '${Config.scheduleBaseEndpoint}/$semester?t=$timestamp';
      final response = await TokenRefreshService.authenticatedGet(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == true && resData['data'] != null) {
          final data = resData['data'];
          await ScheduleDatabaseHelper.instance.cacheScheduleData(semester.toString(), data);
        }
      }
    } catch (e) {
      debugPrint('Error prefetching normal schedule: $e');
    }
  }

  static Future<void> _fetchAndCacheElectives(int semester, int timestamp) async {
    try {
      final url = '${Config.electiveBaseEndpoint}/$semester?t=$timestamp';
      final response = await TokenRefreshService.authenticatedGet(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        // If success is true, but electives list is empty, that's fine, we just cache it.
        // If it's a 404 because no electives exist, it will throw an exception or return success: false, handled gracefully.
        if (resData['success'] == true && resData['data'] != null) {
          final electivesList = resData['data']['electives'] as List? ?? [];
          final serverUpdatedAtStr = resData['data']['updatedAt'] as String?;
          
          final Map<String, List<String>> grouped = {};
          for (var item in electivesList) {
            final group = item['electiveGroup'] as String;
            final name = item['name'] as String;
            grouped.putIfAbsent(group, () => []).add(name);
          }
          
          final cacheData = {
            'updatedAt': serverUpdatedAtStr,
            'raw': electivesList,
            'grouped': grouped,
          };
          
          await ScheduleDatabaseHelper.instance.cacheElectiveData(
            semester.toString(), 
            cacheData, 
            serverUpdatedAt: serverUpdatedAtStr
          );
        }
      }
    } catch (e) {
      debugPrint('Error prefetching electives: $e');
    }
  }
}
