import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'shared_preferences_service.dart';
import 'schedule_database_helper.dart';

const String syncScheduleTask = "sync_schedule_task";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == syncScheduleTask) {
        await _performBackgroundScheduleSync();
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

          await _showLocalNotification('Timetable Updated', 'Your semester $semester schedule was updated by the admin.');
        }
      }
    }
  }
}

Future<void> _showLocalNotification(String title, String body) async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);

  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'schedule_updates', 
    'Schedule Updates',
    channelDescription: 'Notifications for when your class timetable is updated',
    importance: Importance.max,
    priority: Priority.high,
  );
  
  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
  
  await flutterLocalNotificationsPlugin.show(
    id: 0,
    title: title,
    body: body,
    notificationDetails: platformChannelSpecifics,
  );
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
      frequency: const Duration(hours: 1), // Check every hour to strike a balance for immediate updates vs battery
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
