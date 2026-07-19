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
      
      // Load electives
      final Map<String, String> selectedElectives = {};
      final cacheKeyElectives = 'cached_electives_v2_$semester';
      final cachedElectives = await SharedPreferencesService.getString(cacheKeyElectives);
      List<dynamic> rawElectiveData = [];
      Map<String, List<String>> availableElectives = {};
      
      if (cachedElectives != null) {
        final decoded = jsonDecode(cachedElectives);
        if (decoded is Map && decoded.containsKey('raw') && decoded.containsKey('grouped')) {
          rawElectiveData = decoded['raw'] as List;
          (decoded['grouped'] as Map).forEach((key, val) {
            availableElectives[key] = List<String>.from(val as List);
          });
        }
      }
      
      // Load selected electives
      for (var group in availableElectives.keys) {
        final newKey = 'selectedElective_${semester}_$group';
        final saved = await SharedPreferencesService.getString(newKey);
        if (saved != null) {
          selectedElectives[group] = saved;
        }
      }

      List<String> generateAliases(String normalizedGroup) {
        final aliases = <String>[];
        final peMatch = RegExp(r'^PE(\d+)$').firstMatch(normalizedGroup);
        if (peMatch != null) aliases.add('PROFESSIONALELECTIVE${peMatch.group(1)}');
        final oeMatch = RegExp(r'^OE(\d+)$').firstMatch(normalizedGroup);
        if (oeMatch != null) aliases.add('OPENELECTIVE${oeMatch.group(1)}');
        final kMatch = RegExp(r'^KEXPLORE$').firstMatch(normalizedGroup);
        if (kMatch != null) {
          aliases.add('K-EXPLORE');
          aliases.add('KEXPLORE');
        }
        return aliases;
      }

      String? matchElectiveGroup(String className) {
        final cleanName = className.toUpperCase().replaceAll(RegExp(r'[\s\-_]+'), '');
        final allGroups = {...availableElectives, ...{for (var k in selectedElectives.keys) k: <String>[]}};
        for (var group in allGroups.keys) {
          final cleanGroup = group.toUpperCase().replaceAll(RegExp(r'[\s\-_]+'), '');
          if (cleanName == cleanGroup) return group;
          final aliasMap = <String, List<String>>{cleanGroup: generateAliases(cleanGroup)};
          for (var alias in aliasMap[cleanGroup]!) {
            if (cleanName == alias || cleanName.contains(alias)) return group;
          }
        }
        return null;
      }

      String getElectiveRoom(String electiveName, int day, String startTime) {
        for (var elective in rawElectiveData) {
          if (elective['name'] == electiveName && elective['periods'] is List) {
            final periods = elective['periods'] as List;
            for (var p in periods) {
              if (p['day'] == day && p['startTime'] == startTime) {
                return p['room'] ?? '';
              }
            }
          }
        }
        return '';
      }

      // Process and replace periods
      final processedPeriods = todaysClasses.map((p) => Map<String, dynamic>.from(p)).toList();
      for (var period in processedPeriods) {
        final className = period['className']?.toString() ?? '';
        final matchedGroup = matchElectiveGroup(className);
        if (matchedGroup != null) {
          final chosenElective = selectedElectives[matchedGroup];
          if (chosenElective != null) {
            period['className'] = chosenElective;
            period['_replacedByElective'] = true; 
            period['isElective'] = true;
            final room = getElectiveRoom(chosenElective, todayWeekday, period['startTime']?.toString() ?? '');
            if (room.isNotEmpty) period['room'] = room;
          }
        }
      }
      todaysClasses = processedPeriods;

      // Add standalone electives
      final Set<String> occupiedSlots = {};
      for (var cls in todaysClasses) {
        if (cls['_replacedByElective'] == true) {
          occupiedSlots.add('${cls['startTime']}-${cls['endTime']}');
        }
      }

      for (var entry in selectedElectives.entries) {
        final electiveName = entry.value;
        final electiveItem = rawElectiveData.firstWhere(
          (e) => e['name'] == electiveName,
          orElse: () => null,
        );
        if (electiveItem != null && electiveItem['periods'] is List) {
          final periods = electiveItem['periods'] as List;
          for (var p in periods) {
            final pDay = p['day'] is int ? p['day'] as int : int.tryParse(p['day'].toString()) ?? -1;
            if (pDay == todayWeekday) {
              final slotKey = '${p['startTime']}-${p['endTime']}';
              if (!occupiedSlots.contains(slotKey)) {
                todaysClasses.add({
                  'startTime': p['startTime'] ?? '',
                  'endTime': p['endTime'] ?? '',
                  'className': electiveName,
                  'room': p['room'] ?? '',
                  'isElective': true,
                });
                occupiedSlots.add(slotKey); 
              }
            }
          }
        }
      }

      todaysClasses.sort((a, b) {
        final aTime = a['startTime'].toString();
        final bTime = b['startTime'].toString();
        return aTime.compareTo(bTime);
      });

    } catch (e) {
      debugPrint('Error loading cached schedule: $e');
    }

    return HomeScheduleData(
      isHoliday: false,
      classes: todaysClasses,
    );
  }
}
