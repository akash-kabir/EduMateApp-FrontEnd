import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:app/shared/config.dart';
import 'package:app/features/friends/models/friend_model.dart';
import 'package:app/shared/services/shared_preferences_service.dart';
import 'package:app/features/schedule/services/schedule_database_helper.dart';
import 'package:app/features/auth_and_profile/services/token_refresh_service.dart';

class FriendsScheduleService {
  /// Check if a period class name is an elective placeholder (e.g. PE-1, OE-1, Professional Elective, etc.)
  static bool isElectivePeriod(String className) {
    if (className.isEmpty) return false;
    final upper = className.toUpperCase().replaceAll(RegExp(r'[\s\-_]+'), '');
    return upper.contains('ELECTIVE') ||
        upper.startsWith('PE') ||
        upper.startsWith('OE') ||
        upper.contains('KEXPLORE');
  }

  /// Format an elective slot label cleanly
  static String formatElectiveSlotName(String className) {
    final clean = className.trim();
    if (clean.isEmpty) return 'Elective';
    if (clean.toUpperCase().contains('ELECTIVE')) return clean;
    return 'Elective ($clean)';
  }

  /// Process schedule periods for a day, substituting chosen electives if provided,
  /// or matching friend electives directly from their specific opt-in data.
  static Future<List<dynamic>> processPeriodsWithElectives(
    List<dynamic> periodsData, {
    int dayOfWeek = 1,
    int semesterNum = 1,
    Map<String, String>? userElectivesMap,
    List<String>? friendElectivesList,
    bool isFriend = false,
  }) async {
    List<dynamic> processed = [];
    final Map<String, String> electivesMap = userElectivesMap ?? {};
    final List<String> fElectives = friendElectivesList ?? [];

    debugPrint('🔍 processPeriodsWithElectives [Day: $dayOfWeek, Sem: $semesterNum, isFriend: $isFriend]');
    debugPrint('   User/Friend electivesMap: $electivesMap');
    debugPrint('   friendElectivesList: $fElectives');

    // Fetch raw elective data for semester
    List<dynamic> rawElectiveData = [];
    Map<String, List<String>> availableElectives = {};
    try {
      Map<String, dynamic>? decoded = await ScheduleDatabaseHelper.instance.getCachedElectiveData(semesterNum.toString());
      if (decoded == null) {
        final cacheKey = 'cached_electives_v2_$semesterNum';
        final cachedElectivesStr = await SharedPreferencesService.getString(cacheKey);
        if (cachedElectivesStr != null) {
          decoded = jsonDecode(cachedElectivesStr);
        }
      }
      
      if (decoded != null) {
        if (decoded.containsKey('raw') && decoded.containsKey('grouped')) {
          rawElectiveData = decoded['raw'] as List;
          (decoded['grouped'] as Map).forEach((key, val) {
            availableElectives[key] = List<String>.from(val as List);
          });
        }
      }

      if (rawElectiveData.isEmpty) {
        final url = '${Config.electiveBaseEndpoint}/$semesterNum';
        final response = await TokenRefreshService.authenticatedGet(url).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final resData = jsonDecode(response.body);
          if (resData['success'] == true && resData['data'] != null) {
            rawElectiveData = resData['data']['electives'] as List? ?? [];
            
            // 💡 NEW: Cache the fetched electives into SQLite for offline use later!
            try {
              await ScheduleDatabaseHelper.instance.cacheElectiveData(semesterNum.toString(), resData['data']);
            } catch (e) {
              debugPrint('Error caching fetched friend electives to SQLite: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching raw elective data for sem $semesterNum: $e');
    }

    final Set<String> occupiedSlots = {};

    for (var period in periodsData) {
      if (period is Map<String, dynamic>) {
        final pMap = Map<String, dynamic>.from(period);
        final className = (pMap['className'] ?? pMap['subject'] ?? pMap['name'] ?? pMap['title'] ?? '').toString();

        final bool isElectiveSlot = isElectivePeriod(className);

        if (isElectiveSlot) {
          pMap['isElective'] = true;
          pMap['type'] = 'elective';

          String? substitutedName;

          if (electivesMap.isNotEmpty) {
            final upperClass = className.toUpperCase().replaceAll(RegExp(r'[\s\-_]+'), '');
            for (var entry in electivesMap.entries) {
              final upperGroup = entry.key.toUpperCase().replaceAll(RegExp(r'[\s\-_]+'), '');
              if (upperClass.contains(upperGroup) || upperGroup.contains(upperClass)) {
                substitutedName = entry.value;
                break;
              }
            }
          } else if (fElectives.isNotEmpty) {
            final upperClass = className.toUpperCase().replaceAll(RegExp(r'[\s\-_]+'), '');
            for (var friendElec in fElectives) {
              for (var entry in availableElectives.entries) {
                final groupName = entry.key;
                final upperGroup = groupName.toUpperCase().replaceAll(RegExp(r'[\s\-_]+'), '');
                if (upperClass.contains(upperGroup) || upperGroup.contains(upperClass)) {
                  if (entry.value.contains(friendElec)) {
                    substitutedName = friendElec;
                    break;
                  }
                }
              }
              if (substitutedName != null) break;
            }
          }

          if (substitutedName != null && substitutedName.isNotEmpty) {
            pMap['subject'] = substitutedName;
            pMap['className'] = substitutedName;

            debugPrint('✅ Substituted Elective for $className -> $substitutedName');

            // Room lookup
            final elItem = rawElectiveData.firstWhere(
              (e) => e['name'].toString().trim().toUpperCase() == substitutedName!.trim().toUpperCase(),
              orElse: () => null,
            );
            if (elItem != null && elItem['periods'] is List) {
              for (var ep in elItem['periods']) {
                final epDay = ep['day'] is int ? ep['day'] as int : int.tryParse(ep['day'].toString()) ?? -1;
                if (epDay == dayOfWeek && ep['room'] != null) {
                  pMap['room'] = ep['room'];
                  break;
                }
              }
            }
          } else {
            final cleanLabel = formatElectiveSlotName(className);
            pMap['subject'] = cleanLabel;
            pMap['className'] = cleanLabel;
          }
        }

        final timeStr = pMap['time']?.toString() ?? '${pMap['startTime']} - ${pMap['endTime']}';
        occupiedSlots.add(timeStr);

        if (timeStr.contains('-') || (pMap['startTime'] != null && pMap['endTime'] != null)) {
          if (!pMap.containsKey('time') && pMap['startTime'] != null && pMap['endTime'] != null) {
            pMap['time'] = '${pMap['startTime']} - ${pMap['endTime']}';
          }
          processed.add(pMap);
        }
      }
    }

    // Append any explicitly chosen electives if not present in section periods
    final List<String> electivesToAppend = fElectives.isNotEmpty
        ? fElectives
        : electivesMap.values.toList();

    if (electivesToAppend.isNotEmpty) {
      for (var chosenElective in electivesToAppend) {
        final elItem = rawElectiveData.firstWhere(
          (e) => e['name'].toString().trim().toUpperCase() == chosenElective.trim().toUpperCase(),
          orElse: () => null,
        );
        if (elItem != null && elItem['periods'] is List) {
          final elPeriods = elItem['periods'] as List;
          for (var ep in elPeriods) {
            final epDay = ep['day'] is int ? ep['day'] as int : int.tryParse(ep['day'].toString()) ?? -1;
            if (epDay == dayOfWeek) {
              final timeStr = '${ep['startTime']} - ${ep['endTime']}';
              if (!occupiedSlots.contains(timeStr)) {
                processed.add({
                  'subject': chosenElective,
                  'className': chosenElective,
                  'startTime': ep['startTime'] ?? '',
                  'endTime': ep['endTime'] ?? '',
                  'time': timeStr,
                  'room': ep['room'] ?? '',
                  'isElective': true,
                  'type': 'elective',
                });
                occupiedSlots.add(timeStr);
              }
            }
          }
        }
      }
    }

    processed.sort((a, b) {
      final aStart = (a['time'] ?? a['startTime'] ?? '').toString().split('-')[0].trim();
      final bStart = (b['time'] ?? b['startTime'] ?? '').toString().split('-')[0].trim();
      return _timeToMinutes(aStart).compareTo(_timeToMinutes(bStart));
    });

    return processed;
  }

  /// Fetches schedule data for a list of friends.
  static Future<Map<String, List<dynamic>>> getSchedulesForFriends(List<FriendModel> friends) async {
    final Map<String, List<dynamic>> results = {};
    
    final Map<String, List<FriendModel>> semesterGroups = {};
    for (var friend in friends) {
      final sem = friend.semester;
      if (sem.isNotEmpty) {
        semesterGroups.putIfAbsent(sem, () => []).add(friend);
      }
    }

    for (var entry in semesterGroups.entries) {
      final semStr = entry.key;
      final semFriends = entry.value;
      final semNumInt = _extractNumber(semStr);
      final semNum = semNumInt.toString();

      debugPrint('🗓️ Fetching schedule for semester $semNum for friends: ${semFriends.map((f) => "${f.nameTag} (${f.rollNo}) [Electives: ${f.electives}]").toList()}');

      // 1. Check local SQLite DB cache first
      Map<String, dynamic>? semData = await ScheduleDatabaseHelper.instance.getCachedScheduleData(semNum);

      // 2. If not found in SQLite cache, fetch from API and cache into SQLite
      if (semData == null || semData['classes'] == null) {
        try {
          final url = Uri.parse('${Config.scheduleBaseEndpoint}/$semNum?t=${DateTime.now().millisecondsSinceEpoch}');
          final response = await http.get(url);
          if (response.statusCode == 200) {
            final resData = jsonDecode(response.body);
            if (resData['data'] != null) {
              semData = resData['data'];
              await ScheduleDatabaseHelper.instance.cacheScheduleData(semNum, semData);
            }
          }
        } catch (e) {
          debugPrint(' Error fetching semester $semNum schedule from API: $e');
        }
      }

      // 3. Match friend section and parse schedule
      if (semData != null && semData['classes'] != null) {
        List<dynamic> classes = semData['classes'];
        for (var friend in semFriends) {
          final friendSectionNormalized = friend.section.toUpperCase().replaceAll(RegExp(r'\s+|-'), '');

          // Robust section matching
          var section = classes.firstWhere(
            (s) => s['name'].toString().toUpperCase().replaceAll(RegExp(r'\s+|-'), '') == friendSectionNormalized,
            orElse: () => null,
          );

          if (section == null && friendSectionNormalized.startsWith('CSE')) {
            final altSearch = 'CS${friendSectionNormalized.substring(3)}';
            section = classes.firstWhere(
              (s) => s['name'].toString().toUpperCase().replaceAll(RegExp(r'\s+|-'), '') == altSearch,
              orElse: () => null,
            );
          }

          if (section != null && section['schedule'] is List) {
            final friendRawDays = section['schedule'] as List<dynamic>;
            final List<dynamic> processedDays = [];

            // Build friend electives map from their stored electives list
            final Map<String, String> friendElectivesMap = {};
            for (int i = 0; i < friend.electives.length; i++) {
              friendElectivesMap['Elective_${i + 1}'] = friend.electives[i];
            }

            debugPrint('📌 Friend ${friend.nameTag} (${friend.rollNo}) section matched: ${section['name']}, electives map: $friendElectivesMap, raw list: ${friend.electives}');

            for (var dayObj in friendRawDays) {
              if (dayObj is Map<String, dynamic> && dayObj['periods'] is List) {
                final dayNum = dayObj['day'] is int ? dayObj['day'] as int : int.tryParse(dayObj['day'].toString()) ?? 1;
                final periodsWithElectives = await processPeriodsWithElectives(
                  dayObj['periods'],
                  dayOfWeek: dayNum,
                  semesterNum: semNumInt,
                  userElectivesMap: friendElectivesMap,
                  friendElectivesList: friend.electives,
                  isFriend: true,
                );
                processedDays.add({
                  'day': dayObj['day'],
                  'periods': periodsWithElectives,
                });
              } else {
                processedDays.add(dayObj);
              }
            }

            results[friend.rollNo] = processedDays;
          } else {
            debugPrint('❌ Section NOT found for friend ${friend.nameTag} (${friend.section}) in sem $semNum');
            results[friend.rollNo] = [];
          }
        }
      } else {
        for (var f in semFriends) {
          results[f.rollNo] = [];
        }
      }
    }

    return results;
  }

  static int _extractNumber(String str) {
    final RegExp regExp = RegExp(r'\d+');
    final match = regExp.firstMatch(str);
    if (match != null) {
      return int.parse(match.group(0)!);
    }
    return 1;
  }

  static int _timeToMinutes(String timeStr) {
    timeStr = timeStr.trim().toUpperCase();
    int hour = 0;
    int minute = 0;
    
    if (timeStr.contains(':')) {
      List<String> parts = timeStr.split(':');
      hour = int.tryParse(parts[0]) ?? 0;
      
      String minPart = parts[1];
      if (minPart.contains('PM')) {
        if (hour != 12) hour += 12;
      } else if (minPart.contains('AM')) {
        if (hour == 12) hour = 0;
      }
      
      minPart = minPart.replaceAll(RegExp(r'[^0-9]'), '');
      minute = int.tryParse(minPart) ?? 0;
    }
    
    return hour * 60 + minute;
  }
}
