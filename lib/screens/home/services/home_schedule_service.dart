import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../services/shared_preferences_service.dart';
import '../../../services/holiday_service.dart';

class HomeScheduleData {
  final bool isHoliday;
  final String? holidayName;
  final List<dynamic> classes;

  HomeScheduleData({
    required this.isHoliday,
    this.holidayName,
    required this.classes,
  });
}

class HomeScheduleService {
  static Future<HomeScheduleData> getTodaysSchedule() async {
    final now = DateTime.now();
    
    // 1. Check for Holidays
    try {
      final holidayRes = await HolidayService.fetchHolidays(now.year);
      if (holidayRes['success'] == true) {
        final List<dynamic> holidays = holidayRes['data'] ?? [];
        for (var holiday in holidays) {
          if (holiday['startDate'] != null && holiday['endDate'] != null) {
            final start = DateTime.parse(holiday['startDate']);
            final end = DateTime.parse(holiday['endDate']);
            final startDate = DateTime(start.year, start.month, start.day);
            final endDate = DateTime(end.year, end.month, end.day);
            final today = DateTime(now.year, now.month, now.day);
            
            if (today.isAtSameMomentAs(startDate) || 
                today.isAtSameMomentAs(endDate) || 
                (today.isAfter(startDate) && today.isBefore(endDate))) {
              return HomeScheduleData(
                isHoliday: true,
                holidayName: holiday['name'] ?? 'Holiday',
                classes: [],
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking holidays: $e');
    }

    // 2. Fetch today's classes
    final int todayWeekday = now.weekday;
    if (todayWeekday > 5) { // Weekend
      return HomeScheduleData(isHoliday: false, classes: []);
    }

    List<dynamic> todaysClasses = [];
    try {
      final savedSemesterStr = await SharedPreferencesService.getString('timesheet_semester');
      final savedSection = await SharedPreferencesService.getString('timesheet_section');
      
      final int semester = int.tryParse(savedSemesterStr?.replaceAll(RegExp(r'[^0-9]'), '') ?? '1') ?? 1;
      
      final cacheKey = 'schedule_$semester';
      final cachedData = await SharedPreferencesService.getString(cacheKey);
      
      if (cachedData != null) {
        final Map<String, dynamic> scheduleData = jsonDecode(cachedData);
        final List<dynamic>? classesList = scheduleData['classes'] as List<dynamic>?;
        
        if (classesList != null && classesList.isNotEmpty && savedSection != null) {
          // Normalize names for comparison
          final normalizedSaved = savedSection.toUpperCase().replaceAll(RegExp(r'\s+|-'), '');
          
          var section = classesList.firstWhere((s) {
            final normName = s['name'].toString().toUpperCase().replaceAll(RegExp(r'\s+|-'), '');
            return normalizedSaved == normName;
          }, orElse: () => null);
          
          section ??= classesList.first;
          
          if (section != null && section['schedule'] is List) {
            final schedule = section['schedule'] as List;
            for (var dayData in schedule) {
              final dayNum = dayData['day'] is int 
                  ? dayData['day'] as int 
                  : int.tryParse(dayData['day'].toString()) ?? -1;
                  
              if (dayNum == todayWeekday && dayData['periods'] is List) {
                todaysClasses = List<dynamic>.from(dayData['periods']);
                break;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading cached schedule: $e');
    }

    return HomeScheduleData(
      isHoliday: false,
      classes: todaysClasses,
    );
  }
}
