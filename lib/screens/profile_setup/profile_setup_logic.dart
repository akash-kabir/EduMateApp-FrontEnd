import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../../constants/app_constants.dart';
import '../../services/api_service.dart';
import '../../services/shared_preferences_service.dart';
import '../../services/student_data_service.dart';

class ProfileSetupLogic extends ChangeNotifier {
  bool _isDisposed = false;
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController rollNoController = TextEditingController();
  
  String? selectedYear;
  String? selectedBranch;
  String? selectedSection;
  String? selectedSemester;
  List<String> detectedElectives = [];
  
  bool isLoading = false;
  List<String> dynamicSections = [];
  bool loadingSections = false;
  
  // Auto-setup state
  bool isKiitEmail = false;
  String? detectedRollNo;
  bool isSearching = false;
  bool autoSetupSuccess = false;
  String? autoSetupError;
  
  final String? userId;
  final String? token;
  final VoidCallback? onKiitEmailPrefilled;

  ProfileSetupLogic({
    this.userId,
    this.token,
    this.onKiitEmailPrefilled,
  }) {
    _loadNameFromPrefs();
    _detectRollNoFromEmail();
  }

  Future<void> _loadNameFromPrefs() async {
    final firstName = await SharedPreferencesService.getString('userFirstName');
    final lastName = await SharedPreferencesService.getString('userLastName');
    
    if (firstName != null && firstName.isNotEmpty) {
      firstNameController.text = firstName;
    }
    if (lastName != null && lastName.isNotEmpty) {
      lastNameController.text = lastName;
    }
    notifyListeners();
  }

  /// Detect roll number from KIIT email. Does NOT auto-search — just prepares the roll number.
  Future<void> _detectRollNoFromEmail() async {
    final email = await SharedPreferencesService.getUserEmail();

    if (email != null && email.endsWith(ProfileSetupConstants.kiitEmailDomain)) {
      final rollNo = email.split('@')[0];
      isKiitEmail = true;
      detectedRollNo = rollNo;
      rollNoController.text = rollNo;
      notifyListeners();
    }
  }

  /// Auto-setup from roll number: calls the lookup API and populates fields.
  /// Returns true if data was found and populated, false otherwise.
  Future<bool> autoSetupFromRollNo(String rollNo) async {
    isSearching = true;
    autoSetupSuccess = false;
    autoSetupError = null;
    notifyListeners();

    try {
      final result = await StudentDataService.lookupRollNo(rollNo.trim());
      
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        
        selectedYear = data['year'];
        selectedSemester = data['semester'];
        selectedBranch = data['branch'];
        selectedSection = data['section'];
        rollNoController.text = data['rollNo'] ?? rollNo;
        
        if (data['electives'] != null && data['electives'] is List) {
          detectedElectives = List<String>.from(data['electives']);
        }
        
        // Auto-save quietly in the background
        final saveRes = await saveProfile();
        
        if (saveRes['success'] == true) {
          autoSetupSuccess = true;
          isSearching = false;
          notifyListeners();
          return true;
        } else {
          autoSetupError = saveRes['message'] ?? 'Data found but failed to save';
          autoSetupSuccess = false;
          isSearching = false;
          notifyListeners();
          return false;
        }
      } else {
        autoSetupError = result['message'] ?? 'Roll number not found';
        autoSetupSuccess = false;
        isSearching = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      autoSetupError = 'Error searching: $e';
      autoSetupSuccess = false;
      isSearching = false;
      notifyListeners();
      return false;
    }
  }

  void updateSemester(String? semester) {
    selectedSemester = semester;
    notifyListeners();
    fetchClassesForSemester();
  }

  Future<void> fetchClassesForSemester() async {
    if (selectedSemester == null) return;

    loadingSections = true;
    dynamicSections = [];
    selectedBranch = null;
    selectedSection = null;
    notifyListeners();

    final semNum = _getSemesterNumber(selectedSemester!);
    try {
      final url = Uri.parse(
        '${Config.scheduleBaseEndpoint}/$semNum?t=${DateTime.now().millisecondsSinceEpoch}',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['data'] != null && resData['data']['classes'] != null) {
          final classesList = resData['data']['classes'] as List;
          dynamicSections = classesList.map((c) => c['name'].toString()).toList()..sort();
        }
      }
    } catch (e) {
      debugPrint('Error fetching classes: $e');
    }

    loadingSections = false;
    notifyListeners();
  }

  int _getSemesterNumber(String semesterStr) {
    final RegExp regExp = RegExp(r'\d+');
    final match = regExp.firstMatch(semesterStr);
    if (match != null) {
      return int.parse(match.group(0)!);
    }
    return 1;
  }

  Future<Map<String, dynamic>> saveProfile() async {
    if (selectedYear == null ||
        selectedSemester == null ||
        selectedBranch == null ||
        selectedSection == null ||
        token == null) {
      return {'success': false, 'message': 'Please select all fields'};
    }

    isLoading = true;
    notifyListeners();

    try {
      final profileData = {
        'rollNo': rollNoController.text.trim(),
        'year': selectedYear!,
        'semester': selectedSemester!,
        'branch': selectedBranch!,
        'section': selectedSection!,
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'isProfileCompleted': true,
      };

      // Include electives if detected
      if (detectedElectives.isNotEmpty) {
        profileData['electives'] = detectedElectives;
      }

      final result = await ApiService.updateUserProfileWithFields(
        token: token!,
        profileData: profileData,
      );

      if (result['success'] ?? false) {
        final responseData = result['data'];
        if (responseData != null && responseData['data'] != null) {
          await SharedPreferencesService.saveFullUserProfile(
            responseData['data'] as Map<String, dynamic>,
          );
        } else {
          final localProfile = Map<String, dynamic>.from(profileData);
          if (detectedElectives.isNotEmpty) {
            localProfile['electives'] = detectedElectives;
          }
          await SharedPreferencesService.saveFullUserProfile(localProfile);
        }

        // Also save timesheet preferences so schedule loads correctly
        await SharedPreferencesService.setString('timesheet_branch', selectedBranch!);
        await SharedPreferencesService.setString('timesheet_semester', selectedSemester!);
        await SharedPreferencesService.setString('timesheet_section', selectedSection!);
        await SharedPreferencesService.setString('timesheet_year', selectedYear!);
        await SharedPreferencesService.setBool('timesheet_save_preference', true);
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    } finally {
      if (!_isDisposed) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    firstNameController.dispose();
    lastNameController.dispose();
    rollNoController.dispose();
    super.dispose();
  }
}
