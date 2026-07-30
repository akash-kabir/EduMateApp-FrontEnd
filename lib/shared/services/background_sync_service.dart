import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'package:app/shared/config.dart';
import 'package:app/shared/services/shared_preferences_service.dart';
import 'package:app/features/schedule/services/schedule_database_helper.dart';
import 'package:app/shared/services/holiday_service.dart';

const String syncScheduleTask = "sync_schedule_task";
const String syncHolidayTask = "sync_holiday_task";
const String syncSapTask = "sync_sap_task";
const String syncEventsTask = "sync_events_task";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == syncScheduleTask) {
        await _performBackgroundScheduleSync();
      } else if (task == syncHolidayTask) {
        await _performHolidaySync();
      } else if (task == syncEventsTask) {
        await _performEventSync();
      }
    } catch (err) {
      debugPrint("Background task failed: $err");
      return Future.value(false);
    }
    return Future.value(true);
  });
}

Future<void> _performBackgroundScheduleSync() async {
  final token = await SharedPreferencesService.getToken();
  if (token == null) return;

  final savedClass = await SharedPreferencesService.getString('timesheet_semester');
  if (savedClass == null) return;

  final semester = int.tryParse(savedClass.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;

  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final metaUrl = Uri.parse('${Config.scheduleBaseEndpoint}/$semester/metadata?t=$timestamp');

  final metaResponse = await http.get(metaUrl, headers: {
    'Authorization': 'Bearer $token',
  });

  if (metaResponse.statusCode == 200) {
    final metaData = jsonDecode(metaResponse.body);
    final serverUpdatedAt = metaData['updatedAt'];

    if (serverUpdatedAt != null) {
      final localUpdatedAt = await ScheduleDatabaseHelper.instance.getServerUpdatedAt(semester.toString());

      if (localUpdatedAt != serverUpdatedAt) {
        // Fetch new schedule
        final url = Uri.parse('${Config.scheduleBaseEndpoint}/$semester?t=$timestamp');
        final response = await http.get(url, headers: {
          'Authorization': 'Bearer $token',
        });

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final classData = (responseData is Map && responseData.containsKey('data')) 
              ? responseData['data'] 
              : responseData;

          await ScheduleDatabaseHelper.instance.cacheScheduleData(
            semester.toString(), 
            classData, 
            serverUpdatedAt: serverUpdatedAt,
          );
        }
      }
    }
  }
}

Future<void> _performHolidaySync() async {
  final year = DateTime.now().year;
  final result = await HolidayService.fetchHolidays(year);
  
  if (result['success'] == true && result['data'] != null) {
    final List<dynamic> holidays = result['data'];
    
    // Save to SharedPreferences so app can load instantly
    await SharedPreferencesService.setString('cached_holidays_$year', jsonEncode(holidays));
  }
}

Future<void> _performEventSync() async {
  final url = Config.postsEndpoint;
  try {
    // WorkManager background task does not easily support the TokenRefreshService logic 
    // due to context requirements, so we use SharedPreferences token directly.
    final token = await SharedPreferencesService.getToken();
    if (token == null) return;
    
    final response = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer $token',
    });
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> newPosts = data['posts'] ?? [];
      
      if (newPosts.isEmpty) return;
      await SharedPreferencesService.setString('cached_events_list', jsonEncode(newPosts));
    }
  } catch (e) {
    debugPrint("Background event sync failed: $e");
  }
}

class BackgroundSyncService {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );
  }

  static Future<void> registerPeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      "1",
      syncScheduleTask,
      frequency: const Duration(hours: 1), 
      constraints: Constraints(networkType: NetworkType.connected),
    );
    
    await Workmanager().registerPeriodicTask(
      "2",
      syncHolidayTask,
      frequency: const Duration(hours: 24), // Once a day is enough for holidays
      constraints: Constraints(networkType: NetworkType.connected),
    );

    await Workmanager().registerPeriodicTask(
      "3",
      syncEventsTask,
      frequency: const Duration(hours: 3), // Every 3 hours for events
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
}
