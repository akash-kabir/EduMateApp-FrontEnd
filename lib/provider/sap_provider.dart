import 'package:flutter/foundation.dart';
import '../models/sap/attendance_record.dart';
import '../services/sap/sap_auth_service.dart';
import '../services/sap/sap_webview_scraper.dart';
import '../services/sap/sap_database_helper.dart';

class SapProvider with ChangeNotifier {
  final SapAuthService _authService = SapAuthService();
  final SapWebViewScraper _scraper = SapWebViewScraper.instance;
  
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isConnected = false;

  List<SemesterOption> _availableSemesters = [];
  SemesterOption? _currentSemester;
  List<AttendanceRecord> _attendanceRecords = [];
  
  String _termYear = '';
  String _sessionKey = '';
  double _attendanceThreshold = 75.0;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isConnected => _isConnected;
  List<SemesterOption> get availableSemesters => _availableSemesters;
  SemesterOption? get currentSemester => _currentSemester;
  List<AttendanceRecord> get attendanceRecords => _attendanceRecords;
  String get termYear => _termYear;
  String get sessionKey => _sessionKey;
  double get attendanceThreshold => _attendanceThreshold;

  int get totalPresentClasses => _attendanceRecords.fold(0, (sum, r) => sum + r.presentClasses);
  int get totalClassesCount => _attendanceRecords.fold(0, (sum, r) => sum + r.totalClasses);
  double get overallPercentage => totalClassesCount == 0 ? 0.0 : (totalPresentClasses / totalClassesCount) * 100;

  SapProvider() {
    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    _isConnected = await _authService.hasCredentials();
    _attendanceThreshold = await _authService.getThreshold();
    if (_isConnected) {
      final sessionInfo = await _authService.getSessionInfo();
      if (sessionInfo != null) {
        _termYear = sessionInfo['termYear'] ?? '';
        _sessionKey = sessionInfo['sessionKey'] ?? '';
        _currentSemester = SemesterOption(id: '$_termYear-$_sessionKey', title: '$_termYear Session $_sessionKey');
        _availableSemesters = [_currentSemester!];
        await _loadFromCache();
      }
    }
    notifyListeners();
  }

  Future<void> setAttendanceThreshold(double threshold) async {
    _attendanceThreshold = threshold;
    await _authService.saveThreshold(threshold);
    notifyListeners();
  }

  Future<bool> connect(String userId, String password, String termYear, String sessionKey) async {
    _isLoading = true;
    _errorMessage = '';
    _termYear = termYear;
    _sessionKey = sessionKey;
    _attendanceRecords = [];
    notifyListeners();

    try {
      // Purge any stale webview cookies and local database cache before a fresh login attempt
      await _scraper.dispose();
      await SapDatabaseHelper.instance.clearAllData();

      final success = await _scraper.login(userId, password);
      if (success) {
        await _authService.saveCredentials(userId, password);
        await _authService.saveSessionInfo(termYear, sessionKey);
        _isConnected = true;
        await fetchAttendance();
        return true;
      } else {
        _errorMessage = 'Invalid credentials or portal is unreachable.';
        _isConnected = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred during connection: $e';
      _isConnected = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAttendance() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final credentials = await _authService.getCredentials();
      if (credentials == null) {
        print('SAP_DEBUG [Provider]: No credentials found.');
        _errorMessage = 'No credentials found.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      print('SAP_DEBUG [Provider]: Logging in as ${credentials['userId']}...');
      final loginSuccess = await _scraper.login(credentials['userId']!, credentials['password']!);
      print('SAP_DEBUG [Provider]: Login result: $loginSuccess');

      if (!loginSuccess) {
         _errorMessage = 'Failed to login via WebView. Showing cached data.';
         await _loadFromCache();
         return;
      }

      print('SAP_DEBUG [Provider]: Navigating to attendance...');
      final navSuccess = await _scraper.navigateToAttendance();
      if (!navSuccess) {
         _errorMessage = 'Failed to load attendance portal. Showing cached data.';
         await _loadFromCache();
         return;
      }

      _currentSemester = SemesterOption(id: '$_termYear-$_sessionKey', title: '$_termYear Session $_sessionKey');
      _availableSemesters = [_currentSemester!];

      print('SAP_DEBUG [Provider]: Extracting attendance via JS...');
      final result = await _scraper.extractAttendance(_termYear, _sessionKey);
      
      if (result != null && result['success'] == true && result['data'] != null) {
        final List<AttendanceRecord> records = [];
        final dataList = result['data'] as List;
        
        for (var row in dataList) {
          records.add(AttendanceRecord(
            subject: row['subject'].toString(),
            totalClasses: (double.tryParse(row['totalDays'].toString()) ?? 0).toInt(),
            presentClasses: (double.tryParse(row['present'].toString()) ?? 0).toInt(),
            semesterId: _currentSemester!.id,
            lastSyncedAt: DateTime.now(),
            facultyName: row['facultyName']?.toString(),
          ));
        }

        print('SAP_DEBUG [Provider]: Extracted ${records.length} records.');
        await SapDatabaseHelper.instance.clearAttendanceForSemester(_currentSemester!.id);
        await SapDatabaseHelper.instance.insertBatch(records);
      } else {
        final err = result != null ? result['error'] : 'Unknown error';
        print('SAP_DEBUG [Provider]: Extraction failed: $err');
        _errorMessage = 'Could not extract attendance data. Showing cached data.';
      }
      
      await _loadFromCache();
    } catch (e) {
      print('SAP_DEBUG [Provider]: EXCEPTION in fetchAttendance: $e');
      _errorMessage = 'Failed to fetch attendance. Showing cached data.';
      await _loadFromCache();
    } finally {
      // Clean up the webview after sync
      await _scraper.dispose();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromCache() async {
    if (_currentSemester != null) {
      _attendanceRecords = await SapDatabaseHelper.instance.getAttendanceForSemester(_currentSemester!.id);
      print('SAP_DEBUG [Provider]: Loaded ${_attendanceRecords.length} records from DB');
    }
  }

  Future<void> changeSemester(SemesterOption newSemester) async {
    _isLoading = true;
    _currentSemester = newSemester;
    notifyListeners();
    
    _attendanceRecords = await SapDatabaseHelper.instance.getAttendanceForSemester(newSemester.id);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.clearCredentials();
    await SapDatabaseHelper.instance.clearAllData();
    await _scraper.dispose();
    _isConnected = false;
    _attendanceRecords = [];
    _currentSemester = null;
    _availableSemesters = [];
    _termYear = '';
    _sessionKey = '';
    notifyListeners();
  }
}
