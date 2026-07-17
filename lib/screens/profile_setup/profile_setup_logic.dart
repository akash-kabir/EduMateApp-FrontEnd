import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../../constants/app_constants.dart';
import '../../services/api_service.dart';
import '../../services/shared_preferences_service.dart';

class ProfileSetupLogic extends ChangeNotifier {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController rollNoController = TextEditingController();
  
  String? selectedYear;
  String? selectedBranch;
  String? selectedSection;
  String? selectedSemester;
  
  bool isLoading = false;
  List<String> dynamicSections = [];
  bool loadingSections = false;
  
  final String? userId;
  final String? token;
  final VoidCallback? onKiitEmailPrefilled;

  ProfileSetupLogic({
    this.userId,
    this.token,
    this.onKiitEmailPrefilled,
  }) {
    _loadNameFromPrefs();
    _prefilDataFromKiitEmail();
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

  Future<void> _prefilDataFromKiitEmail() async {
    final email = await SharedPreferencesService.getUserEmail();

    if (email != null && email.endsWith(ProfileSetupConstants.kiitEmailDomain)) {
      final rollNo = email.split('@')[0];
      rollNoController.text = rollNo;

      if (rollNo.length >= 2) {
        final admissionYearStr = rollNo.substring(0, 2);
        final admissionYear = int.tryParse(admissionYearStr);

        if (admissionYear != null) {
          final currentYear = DateTime.now().year;
          final currentMonth = DateTime.now().month;

          final academicYear = currentMonth >= ProfileSetupConstants.academicYearStartMonth
              ? currentYear
              : currentYear - 1;

          final fullAdmissionYear = ProfileSetupConstants.yearBaseValue + admissionYear;
          int yearNumber = academicYear - fullAdmissionYear + 1;

          if (yearNumber >= ProfileSetupConstants.minAcademicYear &&
              yearNumber <= ProfileSetupConstants.maxAcademicYear) {
            selectedYear = ProfileSetupConstants.academicYears[yearNumber - 1];
          }
        }
      }
      notifyListeners();
      
      if (onKiitEmailPrefilled != null) {
        onKiitEmailPrefilled!();
      }
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
      final result = await ApiService.updateUserProfileWithFields(
        token: token!,
        profileData: {
          'rollNo': rollNoController.text.trim(),
          'year': selectedYear!,
          'semester': selectedSemester!,
          'branch': selectedBranch!,
          'section': selectedSection!,
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'isProfileCompleted': true,
        },
      );

      if (result['success'] ?? false) {
        final responseData = result['data'];
        if (responseData != null && responseData['data'] != null) {
          await SharedPreferencesService.saveFullUserProfile(
            responseData['data'] as Map<String, dynamic>,
          );
        } else {
          await SharedPreferencesService.saveFullUserProfile({
            'firstName': firstNameController.text.trim(),
            'lastName': lastNameController.text.trim(),
            'rollNo': rollNoController.text.trim(),
            'branch': selectedBranch!,
            'section': selectedSection!,
            'year': selectedYear!,
            'semester': selectedSemester!,
            'isProfileCompleted': true,
          });
        }
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    rollNoController.dispose();
    super.dispose();
  }
}
