import 'package:flutter/foundation.dart';

class ScheduleProvider extends ChangeNotifier {
  final Map<String, dynamic> _scheduleCache = {};
  final Map<String, Map<String, List<String>>> _electivesCache = {};
  final Map<String, List<dynamic>> _rawElectivesCache = {};
  final Map<int, List<dynamic>> _holidaysCache = {};

  // Preferences Cache
  String? branch;
  int? semester;
  String? section;
  bool? savePreference;
  Map<String, String>? selectedElectives;

  // Schedule
  Map<String, dynamic>? getSchedule(String semester) => _scheduleCache[semester];
  
  void setSchedule(String semester, dynamic data) {
    _scheduleCache[semester] = data;
    notifyListeners();
  }

  // Electives
  Map<String, List<String>>? getElectives(String semester) => _electivesCache[semester];
  List<dynamic>? getRawElectives(String semester) => _rawElectivesCache[semester];
  
  void setElectives(String semester, Map<String, List<String>> grouped, List<dynamic> raw) {
    _electivesCache[semester] = grouped;
    _rawElectivesCache[semester] = raw;
    notifyListeners();
  }
  
  // Holidays
  List<dynamic>? getHolidays(int year) => _holidaysCache[year];
  
  void setHolidays(int year, List<dynamic> data) {
    _holidaysCache[year] = data;
    notifyListeners();
  }
}
