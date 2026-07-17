import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../../widgets/custom_glass_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../services/api_service.dart';
import '../../services/shared_preferences_service.dart';

import '../../widgets/toast_manager.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String? userId;
  final String? token;
  final VoidCallback? onProfileSetupComplete;

  const ProfileSetupScreen({
    super.key,
    this.userId,
    this.token,
    this.onProfileSetupComplete,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _rollNoController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  String? _selectedYear;
  String? _selectedBranch;
  String? _selectedSection;
  String? _selectedSemester;
  bool _isLoading = false;
  List<String> _dynamicSections = [];
  bool _loadingSections = false;

  @override
  void initState() {
    super.initState();
    _loadNameFromPrefs();
    _prefilDataFromKiitEmail();
  }

  Future<void> _loadNameFromPrefs() async {
    final firstName = await SharedPreferencesService.getString('userFirstName');
    final lastName = await SharedPreferencesService.getString('userLastName');
    setState(() {
      if (firstName != null && firstName.isNotEmpty) {
        _firstNameController.text = firstName;
      }
      if (lastName != null && lastName.isNotEmpty) {
        _lastNameController.text = lastName;
      }
    });
  }

  void _prefilDataFromKiitEmail() async {
    final email = await SharedPreferencesService.getUserEmail();

    if (email != null &&
        email.endsWith(ProfileSetupConstants.kiitEmailDomain)) {
      // Extract roll number (everything before @)
      final rollNo = email.split('@')[0];
      _rollNoController.text = rollNo;

      // Extract admission year from first 2 digits
      if (rollNo.length >= 2) {
        final admissionYearStr = rollNo.substring(0, 2);
        final admissionYear = int.tryParse(admissionYearStr);

        if (admissionYear != null) {
          // Calculate current year
          final currentYear = DateTime.now().year;
          final currentMonth = DateTime.now().month;

          // Academic year starts from June
          // If before June, we're still in the previous academic year
          final academicYear =
              currentMonth >= ProfileSetupConstants.academicYearStartMonth
              ? currentYear
              : currentYear - 1;

          // Full admission year (e.g., 24 -> 2024)
          final fullAdmissionYear =
              ProfileSetupConstants.yearBaseValue + admissionYear;

          // Calculate year number
          int yearNumber = academicYear - fullAdmissionYear + 1;

          // Ensure it's within valid range
          if (yearNumber >= ProfileSetupConstants.minAcademicYear &&
              yearNumber <= ProfileSetupConstants.maxAcademicYear) {
            setState(() {
              _selectedYear =
                  ProfileSetupConstants.academicYears[yearNumber - 1];
            });
          }
        }
      }

      // Show dialog after frame is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showKiitPreFillDialog();
        }
      });
    }
  }

  Future<void> _fetchClassesForSemester() async {
    if (_selectedSemester == null) return;

    setState(() {
      _loadingSections = true;
      _dynamicSections = [];
      _selectedBranch = null;
      _selectedSection = null;
    });

    final semNum = _getSemesterNumber(_selectedSemester!);
    try {
      final url = Uri.parse(
        '${Config.scheduleBaseEndpoint}/$semNum?t=${DateTime.now().millisecondsSinceEpoch}',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['data'] != null && resData['data']['classes'] != null) {
          final classesList = resData['data']['classes'] as List;
          setState(() {
            _dynamicSections =
                classesList.map((c) => c['name'].toString()).toList()..sort();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching classes: $e');
    }

    setState(() {
      _loadingSections = false;
    });
  }

  int _getSemesterNumber(String semesterStr) {
    final RegExp regExp = RegExp(r'\d+');
    final match = regExp.firstMatch(semesterStr);
    if (match != null) {
      return int.parse(match.group(0)!);
    }
    return 1;
  }

  void _showKiitPreFillDialog() {
    showGlassmorphicDialog(
      context: context,
      barrierDismissible: false,
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64.0,
                height: 64.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AuthPalette.coral.withOpacity(0.15),
                  border: Border.all(
                    color: AuthPalette.coral.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  color: AuthPalette.coral,
                  size: 32.0,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Details Pre-filled',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We\'ve automatically filled in your details based on your KIIT email address.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14.0,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AuthPalette.coral.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Please select your Branch and Semester to complete.',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AuthPalette.coral,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuthPalette.coral,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _rollNoController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  List<String> _getAvailableSemesters() {
    return ProfileSetupConstants.semestersByYear[_selectedYear] ?? [];
  }

  Future<void> _submitProfile() async {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _rollNoController.text.isEmpty ||
        _selectedYear == null ||
        _selectedBranch == null ||
        _selectedSection == null ||
        _selectedSemester == null) {
      EduMateToast.showCompact(
        context,
        message: 'Please fill all fields',
        isSuccess: false,
      );
      return;
    }

    if (widget.token == null) {
      EduMateToast.showCompact(
        context,
        message: 'Authentication token missing',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call the API to save profile data (includes firstName, lastName, section)
      final result = await ApiService.updateUserProfileWithFields(
        token: widget.token!,
        profileData: {
          'rollNo': _rollNoController.text.trim(),
          'year': _selectedYear!,
          'semester': _selectedSemester!,
          'branch': _selectedBranch!,
          'section': _selectedSection!,
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'isProfileCompleted': true,
        },
      );

      if (mounted) {
        if (result['success'] ?? false) {
          // Save full profile to SharedPreferences using the response data
          final responseData = result['data'];
          if (responseData != null && responseData['data'] != null) {
            await SharedPreferencesService.saveFullUserProfile(
              responseData['data'] as Map<String, dynamic>,
            );
          } else {
            // Fallback: save manually if response doesn't have full data
            await SharedPreferencesService.saveFullUserProfile({
              'firstName': _firstNameController.text.trim(),
              'lastName': _lastNameController.text.trim(),
              'rollNo': _rollNoController.text.trim(),
              'branch': _selectedBranch!,
              'section': _selectedSection!,
              'year': _selectedYear!,
              'semester': _selectedSemester!,
              'isProfileCompleted': true,
            });
          }

          // Save branch/section for timesheet auto-selection
          await SharedPreferencesService.setString(
            'selectedBranch',
            _selectedBranch!,
          );
          await SharedPreferencesService.setString(
            'selectedSemester.toString()',
            _selectedSemester!,
          );
          await SharedPreferencesService.setString(
            'selectedSection',
            _selectedSection!,
          );
          await SharedPreferencesService.setString(
            'selectedYear',
            _selectedYear!,
          );
          await SharedPreferencesService.setBool('savePreference', true);

          // Mark profile setup as complete
          await SharedPreferencesService.setProfileSetupComplete(true);

          // Call callback if provided
          widget.onProfileSetupComplete?.call();

          // Show success message
          EduMateToast.showCompact(
            context,
            message: 'Profile saved successfully!',
            isSuccess: true,
          );

          // Delay to show the success message
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          // Show error message
          EduMateToast.showCompact(
            context,
            message: result['message'] ?? 'Failed to save profile',
            isSuccess: false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(
          context,
          message: 'Error: ${e.toString()}',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F0F11) : const Color(0xFFFAFAFA),
        ),
        child: Stack(
          children: [
            // Ambient glowing orbs
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AuthPalette.coral.withOpacity(isDark ? 0.15 : 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AuthPalette.coral.withOpacity(isDark ? 0.1 : 0.05),
                ),
              ),
            ),
            // Blur layer
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
            ),
            CupertinoPageScaffold(
              backgroundColor: Colors.transparent,
              navigationBar: CupertinoNavigationBar(
                middle: const Text('Complete Your Profile'),
                backgroundColor: isDark
                    ? const Color(0xFF0F0F11).withOpacity(0.65)
                    : Colors.white.withOpacity(0.65),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12,
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Provide your academic details to get started',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 32),
                        // First Name & Last Name
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'First Name',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  CupertinoTextField(
                                    controller: _firstNameController,
                                    placeholder: 'First name',
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.1)
                                            : Colors.black.withOpacity(0.1),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.black.withOpacity(0.03),
                                    ),
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    placeholderStyle: TextStyle(
                                      color: isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Last Name',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  CupertinoTextField(
                                    controller: _lastNameController,
                                    placeholder: 'Last name',
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.1)
                                            : Colors.black.withOpacity(0.1),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.black.withOpacity(0.03),
                                    ),
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    placeholderStyle: TextStyle(
                                      color: isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Roll Number Input
                        Text(
                          'Roll Number',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                        ),
                        const SizedBox(height: 8),
                        CupertinoTextField(
                          controller: _rollNoController,
                          placeholder: 'Enter your roll number',
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.1),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.03),
                          ),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          placeholderStyle: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Year and Semester side by side
                        Row(
                          children: [
                            // Year Dropdown
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Year',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildDropdown(
                                    context,
                                    hint: 'Select',
                                    value: _selectedYear,
                                    items: ProfileSetupConstants.academicYears,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedYear = value;
                                        _selectedSemester =
                                            null; // Reset semester when year changes
                                      });
                                    },
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Semester Dropdown
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Semester',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildDropdown(
                                    context,
                                    hint: 'Select',
                                    value: _selectedSemester,
                                    items: _getAvailableSemesters(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedSemester = value;
                                        _selectedBranch = null;
                                        _selectedSection = null;
                                      });
                                      _fetchClassesForSemester();
                                    },
                                    isDark: isDark,
                                    enabled: _selectedYear != null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // (CGPA moved to CGPA calculator)
                        const SizedBox(height: 24),
                        // Class & Section Picker
                        Row(
                          children: [
                            Text(
                              'Branch & Section',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                            ),
                            if (_loadingSections) ...[
                              const SizedBox(width: 8),
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Material(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.03),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.1),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap:
                                (_selectedSemester != null && !_loadingSections)
                                ? () => _showTwoColumnPicker(context, isDark)
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedBranch != null &&
                                              _selectedSection != null
                                          ? '$_selectedBranch - $_selectedSection'
                                          : (_loadingSections
                                                ? 'Loading...'
                                                : 'Select your class'),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color:
                                            _selectedBranch != null &&
                                                _selectedSection != null
                                            ? (isDark
                                                  ? Colors.white
                                                  : Colors.black)
                                            : (isDark
                                                  ? Colors.grey[500]
                                                  : Colors.grey[400]),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    CupertinoIcons.chevron_down,
                                    color: isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[400],
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Submit Button
                        CupertinoButton(
                          onPressed: _isLoading ? null : _submitProfile,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _isLoading
                                  ? (isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[300])
                                  : AuthPalette.coral,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _isLoading
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: AuthPalette.coral.withOpacity(
                                          0.3,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 15,
                                      width: 20,
                                      child: CupertinoActivityIndicator(
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Complete Setup',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isDark,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled
          ? () async {
              FocusManager.instance.primaryFocus?.unfocus();
              await Future.delayed(const Duration(milliseconds: 50));
              if (!context.mounted) return;

              int initialIndex = value != null
                  ? items.indexOf(value).clamp(0, items.length - 1)
                  : 0;
              if (items.isNotEmpty && value == null) {
                onChanged(items[initialIndex]);
              }

              showCupertinoModalPopup(
                context: context,
                builder: (context) => Material(
                  child: Container(
                    height: 280,
                    padding: const EdgeInsets.only(top: 6),
                    margin: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    color: CupertinoColors.systemBackground.resolveFrom(
                      context,
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CupertinoButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                Text(
                                  hint,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                CupertinoButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Done'),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            color: Colors.grey[400],
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                          Expanded(
                            child: CupertinoPicker(
                              magnification: 1.22,
                              squeeze: 1.2,
                              useMagnifier: true,
                              itemExtent: 32.0,
                              scrollController: FixedExtentScrollController(
                                initialItem: value != null
                                    ? items
                                          .indexOf(value)
                                          .clamp(0, items.length - 1)
                                    : 0,
                              ),
                              onSelectedItemChanged: (index) {
                                onChanged(items[index]);
                              },
                              children: items
                                  .map((item) => Center(child: Text(item)))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: enabled
                    ? (isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1))
                    : (isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05)),
              ),
              borderRadius: BorderRadius.circular(12),
              color: enabled
                  ? (isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03))
                  : (isDark
                        ? Colors.white.withOpacity(0.02)
                        : Colors.black.withOpacity(0.01)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value ?? hint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: value == null
                        ? (enabled
                              ? (isDark ? Colors.grey[500] : Colors.grey[400])
                              : (isDark ? Colors.grey[700] : Colors.grey[300]))
                        : (isDark ? Colors.white : Colors.black),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_down,
                  color: enabled
                      ? (isDark ? Colors.grey[500] : Colors.grey[400])
                      : (isDark ? Colors.grey[700] : Colors.grey[300]),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTwoColumnPicker(BuildContext context, bool isDark) {
    if (_dynamicSections.isEmpty) {
      EduMateToast.showCompact(
        context,
        message: 'No classes found for this semester',
        isSuccess: false,
      );
      return;
    }

    final Map<String, Map<String, String>> grouped = {};
    for (final item in _dynamicSections) {
      final match = RegExp(
        r'^([a-zA-Z\s\-]+?)\s*(\d+)$',
      ).firstMatch(item.trim());
      if (match != null) {
        final subject = match.group(1)!.trim();
        final section = match.group(2)!.trim();
        grouped.putIfAbsent(subject, () => {})[section] = item;
      } else {
        final match2 = RegExp(r'^([a-zA-Z]+)-?(\w+)$').firstMatch(item.trim());
        if (match2 != null) {
          final subject = match2.group(1)!.trim();
          final section = match2.group(2)!.trim();
          grouped.putIfAbsent(subject, () => {})[section] = item;
        } else {
          grouped.putIfAbsent(item, () => {})[''] = item;
        }
      }
    }

    final subjects = grouped.keys.toList();
    if (subjects.isEmpty) return;

    int initialSubjectIdx = 0;
    int initialSectionIdx = 0;
    if (_selectedBranch != null && _selectedSection != null) {
      initialSubjectIdx = subjects.indexOf(_selectedBranch!);
      if (initialSubjectIdx != -1) {
        final sections = grouped[_selectedBranch!]!.keys.toList()
          ..sort(
            (a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0),
          );
        initialSectionIdx = sections.indexOf(_selectedSection!);
        if (initialSectionIdx == -1) initialSectionIdx = 0;
      } else {
        initialSubjectIdx = 0;
      }
    }

    String tempSubject = subjects[initialSubjectIdx];
    List<String> tempSections = grouped[tempSubject]!.keys.toList()
      ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
    String tempSection = tempSections.isNotEmpty
        ? tempSections[initialSectionIdx]
        : '';

    showCupertinoModalPopup(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Material(
            child: Container(
              height: 280,
              padding: const EdgeInsets.only(top: 6),
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const Text(
                            'Select Class',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          CupertinoButton(
                            onPressed: () {
                              setState(() {
                                _selectedBranch = tempSubject;
                                _selectedSection = tempSection;
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: Colors.grey[400],
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoPicker(
                              magnification: 1.22,
                              squeeze: 1.2,
                              useMagnifier: true,
                              itemExtent: 32.0,
                              scrollController: FixedExtentScrollController(
                                initialItem: initialSubjectIdx,
                              ),
                              onSelectedItemChanged: (index) {
                                setModalState(() {
                                  tempSubject = subjects[index];
                                  tempSections =
                                      grouped[tempSubject]!.keys.toList()..sort(
                                        (a, b) => (int.tryParse(a) ?? 0)
                                            .compareTo(int.tryParse(b) ?? 0),
                                      );
                                  tempSection = tempSections.isNotEmpty
                                      ? tempSections[0]
                                      : '';
                                });
                              },
                              children: subjects
                                  .map((s) => Center(child: Text(s)))
                                  .toList(),
                            ),
                          ),
                          Expanded(
                            key: ValueKey(
                              tempSubject,
                            ), // Forces rebuild of second picker when subject changes
                            child: CupertinoPicker(
                              magnification: 1.22,
                              squeeze: 1.2,
                              useMagnifier: true,
                              itemExtent: 32.0,
                              scrollController: FixedExtentScrollController(
                                initialItem: tempSections
                                    .indexOf(tempSection)
                                    .clamp(0, tempSections.length - 1),
                              ),
                              onSelectedItemChanged: (index) {
                                tempSection = tempSections[index];
                              },
                              children: tempSections
                                  .map((s) => Center(child: Text(s)))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
