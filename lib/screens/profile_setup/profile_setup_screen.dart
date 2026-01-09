import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../services/api_service.dart';

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
  final TextEditingController _rollNoController = TextEditingController();
  String? _selectedYear;
  String? _selectedBranch;
  String? _selectedSemester;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _prefilDataFromKiitEmail();
  }

  void _prefilDataFromKiitEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('userEmail');

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
    _rollNoController.dispose();
    super.dispose();
  }

  List<String> _getAvailableSemesters() {
    return ProfileSetupConstants.semestersByYear[_selectedYear] ?? [];
  }

  Future<void> _submitProfile() async {
    if (_rollNoController.text.isEmpty ||
        _selectedYear == null ||
        _selectedBranch == null ||
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
      // Call the API to save profile data
      final result = await ApiService.updateUserProfile(
        token: widget.token!,
        rollNo: _rollNoController.text,
        year: _selectedYear!,
        semester: _selectedSemester!,
        branch: _selectedBranch!,
      );

      if (mounted) {
        if (result['success'] ?? false) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Call callback if provided
          widget.onProfileSetupComplete?.call();

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
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Complete Your Profile'),
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
                    setState(() => _selectedBranch = value);
                  },
                  isDark: isDark,
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
                builder: (context) => Container(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CupertinoButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            CupertinoButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Done'),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 200,
                        child: CupertinoPicker(
                          itemExtent: 40,
                          onSelectedItemChanged: (index) {
                            onChanged(items[index]);
                          },
                          children: items
                              .map(
                                (item) => Center(
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
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
