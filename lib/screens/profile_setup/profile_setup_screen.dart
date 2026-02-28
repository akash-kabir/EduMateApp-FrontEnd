import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../services/api_service.dart';
import '../../services/shared_preferences_service.dart';

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

  void _showKiitPreFillDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Details Pre-filled'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              'We\'ve automatically filled in your details based on your KIIT email address.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[300]
                    : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Please select your Branch and Semester to complete.',
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (widget.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication token missing')),
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
            'selectedClass',
            _selectedSection!,
          );
          await SharedPreferencesService.setBool('savePreference', true);

          // Mark profile setup as complete
          await SharedPreferencesService.setProfileSetupComplete(true);

          // Call callback if provided
          widget.onProfileSetupComplete?.call();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Delay to show the success message
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to save profile'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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

    return CupertinoPageScaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Complete Your Profile'),
        backgroundColor: isDark
            ? CupertinoColors.black.withOpacity(0.6)
            : CupertinoColors.white.withOpacity(0.6),
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black,
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
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: isDark
                                  ? Colors.grey[900]
                                  : Colors.grey[100],
                            ),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
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
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black,
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
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: isDark
                                  ? Colors.grey[900]
                                  : Colors.grey[100],
                            ),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isDark ? Colors.grey[900] : Colors.grey[100],
                  ),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
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
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black,
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
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                          ),
                          const SizedBox(height: 8),
                          _buildDropdown(
                            context,
                            hint: 'Select',
                            value: _selectedSemester,
                            items: _getAvailableSemesters(),
                            onChanged: (value) {
                              setState(() => _selectedSemester = value);
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
                // Branch Dropdown
                Text(
                  'Branch',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDropdown(
                  context,
                  hint: 'Select your branch',
                  value: _selectedBranch,
                  items: ProfileSetupConstants.branches,
                  onChanged: (value) {
                    setState(() {
                      _selectedBranch = value;
                      _selectedSection = null;
                    });
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 24),
                // Section Dropdown
                Text(
                  'Section',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDropdown(
                  context,
                  hint: 'Select your section',
                  value: _selectedSection,
                  items:
                      ProfileSetupConstants
                          .sectionsPerBranch[_selectedBranch] ??
                      [],
                  onChanged: (value) {
                    setState(() => _selectedSection = value);
                  },
                  isDark: isDark,
                  enabled: _selectedBranch != null,
                ),
                const SizedBox(height: 48),
                // Submit Button
                CupertinoButton(
                  onPressed: _isLoading ? null : _submitProfile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _isLoading
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CupertinoActivityIndicator(
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Complete Setup',
                              style: Theme.of(context).textTheme.bodyLarge
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
          ? () {
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled
                ? (isDark ? Colors.grey[700]! : Colors.grey[300]!)
                : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
          ),
          borderRadius: BorderRadius.circular(12),
          color: enabled
              ? (isDark ? Colors.grey[900] : Colors.grey[100])
              : (isDark ? Colors.grey[950] : Colors.grey[50]),
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
    );
  }
}
