import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui' as ui;
import '../../../constants/app_constants.dart';
import '../../../config.dart';
import '../../../services/shared_preferences_service.dart';
import '../../../widgets/toast_manager.dart';

class CGPACalculatorScreen extends StatefulWidget {
  const CGPACalculatorScreen({super.key});

  @override
  State<CGPACalculatorScreen> createState() => _CGPACalculatorScreenState();
}

class _CGPACalculatorScreenState extends State<CGPACalculatorScreen> {
  List<String> branches = [];
  List<Map<String, dynamic>> semesters = [];
  List<Map<String, dynamic>> subjects = [];

  String? selectedBranch;
  int? selectedSemesterNumber;
  Map<String, String> gradeMap = {};
  double? calculatedCGPA;
  double? pastCGPA;
  double? overallCGPA;
  bool isLoading = false;
  String? errorMessage;

  // Controllers for dropdowns
  final TextEditingController branchController = TextEditingController();
  final TextEditingController semesterController = TextEditingController();
  final TextEditingController pastCGPAController = TextEditingController();
  final Map<String, TextEditingController> gradeControllers = {};
  late ScrollController _scrollController;
  bool _showResultPill = false;

  // Grade mapping to 10-point scale
  static const Map<String, double> gradeValues = {
    'O': 10.0,
    'E': 9.0,
    'A': 8.0,
    'B': 7.0,
    'C': 6.0,
    'D': 5.0,
    'F': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _fetchBranchesAndAutoSelect();
  }

  void _onScroll() {
    if (calculatedCGPA == null) return;
    // Show pill when scrolled up enough that the results are off-screen
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // If the user is NOT near the bottom (more than 150px away), show the pill
    final shouldShow = currentScroll < maxScroll - 150;
    if (shouldShow != _showResultPill) {
      setState(() => _showResultPill = shouldShow);
    }
  }

  Future<void> _fetchBranchesAndAutoSelect() async {
    await _fetchBranches();

    // Auto-select branch from SharedPreferences if available
    final savedBranch = await SharedPreferencesService.getBranch();
    if (savedBranch != null &&
        savedBranch.isNotEmpty &&
        branches.contains(savedBranch)) {
      setState(() {
        selectedBranch = savedBranch;
      });
      await _fetchSemesters(savedBranch);

      // Auto-select semester from SharedPreferences if available
      final savedSemester = await SharedPreferencesService.getSemester();
      if (savedSemester != null && savedSemester.isNotEmpty) {
        // Parse semester number from "Semester 5" → 5
        final parts = savedSemester.split(' ');
        if (parts.length == 2) {
          final semNum = int.tryParse(parts[1]);
          if (semNum != null) {
            final matchingSemester = semesters.where(
              (s) => s['semesterNumber'] == semNum,
            );
            if (matchingSemester.isNotEmpty) {
              setState(() {
                selectedSemesterNumber = semNum;
                subjects = List<Map<String, dynamic>>.from(
                  matchingSemester.first['subjects'],
                );
                gradeMap = {};
                calculatedCGPA = null;
              });
            }
          }
        }
      }
    }
  }

  Future<void> _fetchBranches() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse(Config.curriculumBaseEndpoint));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final curriculums = (data['data'] as List).cast<Map<String, dynamic>>();

        final branchList = curriculums
            .map((c) => c['branch'].toString())
            .toList();

        setState(() {
          branches = branchList.toSet().toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load branches';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchSemesters(String branch) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      semesters = [];
      subjects = [];
      selectedSemesterNumber = null;
      calculatedCGPA = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${Config.curriculumBaseEndpoint}/branch/$branch'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> semestersData = data['data'];
        final semesterList = List<Map<String, dynamic>>.from(
          semestersData.map(
            (s) => {
              'semesterNumber': s['semester'],
              'subjects': s['subjects'],
            },
          ),
        );

        setState(() {
          semesters = semesterList;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load semesters for $branch';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  void _selectSemester(int semesterNumber) {
    final semester = semesters.firstWhere(
      (s) => s['semesterNumber'] == semesterNumber,
      orElse: () => {},
    );

    setState(() {
      selectedSemesterNumber = semesterNumber;
      subjects = List<Map<String, dynamic>>.from(semester['subjects'] ?? []);
      gradeMap.clear();
      calculatedCGPA = null;
    });
  }

  void _calculateCGPA() {
    // Check if all grades are entered
    if (subjects.isEmpty) {
      EduMateToast.showCompact(
        context,
        message: 'No subjects available for this semester',
        isSuccess: false,
      );
      return;
    }

    for (final subject in subjects) {
      if (!gradeMap.containsKey(subject['name'])) {
        EduMateToast.showCompact(
          context,
          message: 'Please enter grade for ${subject['name']}',
          isSuccess: false,
        );
        return;
      }
    }

    // Calculate CGPA
    double totalWeightedGrade = 0;
    double totalCredits = 0;

    for (final subject in subjects) {
      final gradeStr = gradeMap[subject['name']];
      final credits = (subject['credits'] as num).toDouble();
      final gradeValue = gradeValues[gradeStr] ?? 0.0;

      totalWeightedGrade += gradeValue * credits;
      totalCredits += credits;
    }

    final cgpa = totalCredits > 0 ? totalWeightedGrade / totalCredits : 0.0;

    setState(() {
      calculatedCGPA = cgpa;
    });

    // Scroll down smoothly to show the result
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  /// Silently recalculates SGPA and overall CGPA without validation or scrolling.
  /// Called automatically when a grade slider changes after initial calculation.
  void _autoRecalculate() {
    double totalWeightedGrade = 0;
    double totalCredits = 0;

    for (final subject in subjects) {
      final gradeStr = gradeMap[subject['name']];
      if (gradeStr == null) continue;
      final credits = (subject['credits'] as num).toDouble();
      final gradeValue = gradeValues[gradeStr] ?? 0.0;

      totalWeightedGrade += gradeValue * credits;
      totalCredits += credits;
    }

    final cgpa = totalCredits > 0 ? totalWeightedGrade / totalCredits : 0.0;

    setState(() {
      calculatedCGPA = cgpa;
      // Also update overall CGPA if past CGPA was already applied
      if (overallCGPA != null && pastCGPA != null) {
        overallCGPA = (pastCGPA! + cgpa) / 2;
      }
    });
  }

  void _resetGrades() {
    setState(() {
      gradeMap.clear();
      calculatedCGPA = null;
      pastCGPA = null;
      overallCGPA = null;
      pastCGPAController.clear();
      gradeControllers.forEach((key, controller) => controller.clear());
    });

    // Scroll up smoothly
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  LinearGradient _getGradientForCGPA(double cgpa) {
    if (cgpa >= 9.5 && cgpa <= 10.0) {
      // Coral to dark purple
      return LinearGradient(
        colors: [AuthPalette.coral, Colors.deepPurple],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (cgpa >= 8.0 && cgpa < 9.5) {
      // Green to coral
      return LinearGradient(
        colors: [Colors.green, AuthPalette.coral],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (cgpa >= 7.0 && cgpa < 8.0) {
      // Yellow to green
      return LinearGradient(
        colors: [Colors.yellow, Colors.green],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (cgpa >= 6.0 && cgpa < 7.0) {
      // Red to yellow
      return LinearGradient(
        colors: [Colors.red, Colors.yellow],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      // Dark to red (5-6)
      return LinearGradient(
        colors: [Colors.grey[800]!, Colors.red],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  @override
  void dispose() {
    branchController.dispose();
    semesterController.dispose();
    pastCGPAController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    for (var controller in gradeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('CGPA Calculator',
                  style: TextStyle(
                  fontFamily: 'Salena')),
        backgroundColor: isDark
            ? CupertinoColors.black.withOpacity(0.6)
            : CupertinoColors.white.withOpacity(0.6),
        border: Border(
          bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: Icon(CupertinoIcons.back, color: AuthPalette.coral),
        ),
      ),
      child: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AuthPalette.coral,
                strokeWidth: 3,
              ),
            )
          : Material(
              color: isDark ? CupertinoColors.black : CupertinoColors.white,
              child: SafeArea(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Calculate your CGPA for the selected semester',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Branch Selector
                      Text(
                        'Select Branch',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPickerSelector(
                        context,
                        hint: 'Choose a branch',
                        value: selectedBranch,
                        items: branches,
                        isDark: isDark,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedBranch = value);
                            _fetchSemesters(value);
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Semester Selection
                      if (semesters.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Semester',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            _buildPickerSelector(
                              context,
                              hint: 'Select a semester',
                              value: selectedSemesterNumber != null
                                  ? 'Semester $selectedSemesterNumber'
                                  : null,
                              items: semesters
                                  .map((s) => 'Semester ${s['semesterNumber']}')
                                  .toList(),
                              isDark: isDark,
                              onChanged: (value) {
                                if (value != null) {
                                  final semNum = int.tryParse(
                                    value.replaceAll(RegExp(r'[^0-9]'), ''),
                                  );
                                  if (semNum != null) {
                                    setState(
                                      () => selectedSemesterNumber = semNum,
                                    );
                                    _selectSemester(semNum);
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),

                      // Past CGPA Card
                      if (selectedSemesterNumber != null &&
                          selectedSemesterNumber! > 1)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E1E23).withValues(alpha: 0.40)
                                    : Colors.grey[200]!.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8.0,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Past CGPA',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: pastCGPAController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    onChanged: (value) {
                                      setState(() {
                                        pastCGPA = double.tryParse(value);
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Your CGPA',
                                      hintStyle: TextStyle(
                                        color: isDark
                                            ? Colors.grey[500]
                                            : Colors.grey[400],
                                      ),
                                      filled: true,
                                      fillColor: isDark
                                          ? const Color(0xFF1C1C1E)
                                          : Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: AuthPalette.coral.withValues(alpha: 0.4),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: AuthPalette.coral.withValues(alpha: 0.4),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: AuthPalette.coral,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                    ),
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Enter your previous CGPA to include it in the calculation.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (selectedSemesterNumber != null &&
                          selectedSemesterNumber! > 1)
                        const SizedBox(height: 24),

                      // Subjects and Grades
                      if (subjects.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enter Grades',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: subjects.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final subject = subjects[index];
                                final subjectName = subject['name'];
                                final credits = subject['credits'];

                                // Initialize controller if not exists
                                gradeControllers.putIfAbsent(
                                  subjectName,
                                  () => TextEditingController(),
                                );

                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: BackdropFilter(
                                    filter: ui.ImageFilter.blur(
                                      sigmaX: 10.0,
                                      sigmaY: 10.0,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1E1E23).withValues(alpha: 0.40)
                                            : Colors.grey[200]!.withValues(alpha: 0.65),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.15),
                                            blurRadius: 8.0,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Subject name
                                      Text(
                                        subjectName,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Credit info
                                      Text(
                                        'Credit: $credits',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      // Grade Slider
                                      _buildGradeSlider(
                                        subjectName: subjectName,
                                        credits: (credits as num).toDouble(),
                                        isDark: isDark,
                                      ),
                                    ],
                                  ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),

                      // Action Buttons
                      if (subjects.isNotEmpty)
                        Column(
                          children: [
                            // Calculate SGPA and Reset Button Row
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _calculateCGPA,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AuthPalette.coral,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Calculate CGPA',
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
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _resetGrades,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.grey[800]
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.refresh,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (selectedSemesterNumber != null &&
                                selectedSemesterNumber! > 1)
                              GestureDetector(
                                onTap: () {
                                  if (pastCGPA != null &&
                                      calculatedCGPA != null) {
                                    setState(() {
                                      overallCGPA =
                                          (pastCGPA! + calculatedCGPA!) / 2;
                                    });

                                    // Scroll down smoothly to show the result
                                    Future.delayed(
                                      const Duration(milliseconds: 100),
                                      () {
                                        _scrollController.animateTo(
                                          _scrollController
                                              .position
                                              .maxScrollExtent,
                                          duration: const Duration(
                                            milliseconds: 500,
                                          ),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                    );
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Add CGPA to Calculation',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 12),

                      // Result Display
                      if (calculatedCGPA != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                              child: Container(
                                width: MediaQuery.of(context).size.width - 32,
                                padding: const EdgeInsets.all(20.0),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E1E23).withValues(alpha: 0.40)
                                      : Colors.grey[200]!.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 8.0,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Content Row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Left Column
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Current',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'SGPA',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Right Side - Number
                                        ShaderMask(
                                          shaderCallback: (bounds) {
                                            return _getGradientForCGPA(
                                              calculatedCGPA!,
                                            ).createShader(bounds);
                                          },
                                          child: Text(
                                            calculatedCGPA!.toStringAsFixed(2),
                                            style: TextStyle(
                                              fontSize: 56,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),

                      // Overall CGPA Display for Semester 1 (just show SGPA)
                      if (selectedSemesterNumber == 1 && calculatedCGPA != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                              child: Container(
                                width: MediaQuery.of(context).size.width - 32,
                                padding: const EdgeInsets.all(20.0),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E1E23).withValues(alpha: 0.40)
                                      : Colors.grey[200]!.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 8.0,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Content Row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Left Column
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Overall',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'CGPA',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Right Side - Number
                                        ShaderMask(
                                          shaderCallback: (bounds) {
                                            return _getGradientForCGPA(
                                              calculatedCGPA!,
                                            ).createShader(bounds);
                                          },
                                          child: Text(
                                            calculatedCGPA!.toStringAsFixed(2),
                                            style: TextStyle(
                                              fontSize: 56,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Overall CGPA Display for Semester > 1 (with past CGPA calculation)
                      if (selectedSemesterNumber != null &&
                          selectedSemesterNumber! > 1 &&
                          overallCGPA != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                              child: Container(
                                width: MediaQuery.of(context).size.width - 32,
                                padding: const EdgeInsets.all(20.0),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E1E23).withValues(alpha: 0.40)
                                      : Colors.grey[200]!.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 8.0,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Content Row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Left Column
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Overall',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'CGPA',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Right Side - Number
                                        ShaderMask(
                                          shaderCallback: (bounds) {
                                            return _getGradientForCGPA(
                                              overallCGPA!,
                                            ).createShader(bounds);
                                          },
                                          child: Text(
                                            overallCGPA!.toStringAsFixed(2),
                                            style: TextStyle(
                                              fontSize: 56,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),

                      // Error Message
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.red[900] : Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? Colors.red[800]!
                                    : Colors.red[300]!,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.exclamationmark_circle,
                                  color: isDark
                                      ? Colors.red[200]
                                      : Colors.red[700],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errorMessage!,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.red[200]
                                          : Colors.red[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                    // Floating result pill
                    if (calculatedCGPA != null)
                      Positioned(
                        bottom: 16,
                        left: 24,
                        right: 24,
                        child: AnimatedSlide(
                          offset: _showResultPill
                              ? Offset.zero
                              : const Offset(0, 2),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          child: AnimatedOpacity(
                            opacity: _showResultPill ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: IgnorePointer(
                              ignoring: !_showResultPill,
                              child: GestureDetector(
                                onTap: () {
                                  // Scroll to bottom to show full results
                                  _scrollController.animateTo(
                                    _scrollController.position.maxScrollExtent,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: BackdropFilter(
                                    filter: ui.ImageFilter.blur(
                                      sigmaX: 30,
                                      sigmaY: 30,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1E1E23)
                                                .withValues(alpha: 0.55)
                                            : Colors.white
                                                .withValues(alpha: 0.55),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.15),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildPillItem(
                                            'SGPA',
                                            calculatedCGPA!
                                                .toStringAsFixed(2),
                                            _getGradientForCGPA(
                                              calculatedCGPA!,
                                            ),
                                            isDark,
                                          ),
                                          Container(
                                            width: 1,
                                            height: 28,
                                            color: isDark
                                                ? Colors.white
                                                    .withValues(alpha: 0.1)
                                                : Colors.black
                                                    .withValues(alpha: 0.08),
                                          ),
                                          _buildPillItem(
                                            'CGPA',
                                            overallCGPA != null
                                                ? overallCGPA!
                                                    .toStringAsFixed(2)
                                                : (selectedSemesterNumber ==
                                                        1
                                                    ? calculatedCGPA!
                                                        .toStringAsFixed(2)
                                                    : '—'),
                                            overallCGPA != null
                                                ? _getGradientForCGPA(
                                                    overallCGPA!,
                                                  )
                                                : (selectedSemesterNumber ==
                                                        1
                                                    ? _getGradientForCGPA(
                                                        calculatedCGPA!,
                                                      )
                                                    : const LinearGradient(
                                                        colors: [
                                                          Colors.grey,
                                                          Colors.grey,
                                                        ],
                                                      )),
                                            isDark,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPillItem(
    String label,
    String value,
    LinearGradient gradient,
    bool isDark,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        ShaderMask(
          shaderCallback: (bounds) => gradient.createShader(bounds),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerSelector(
    BuildContext context, {
    required String hint,
    required String? value,
    required List<String> items,
    required bool isDark,
    required Function(String?) onChanged,
  }) {
    return GestureDetector(
      onTap: items.isEmpty
          ? null
          : () async {
              FocusManager.instance.primaryFocus?.unfocus();
              await Future.delayed(const Duration(milliseconds: 50));
              if (!context.mounted) return;
              showCupertinoModalPopup(
                context: context,
                builder: (ctx) => Material(
                  type: MaterialType.transparency,
                  child: Container(
                    height: 300,
                    padding: const EdgeInsets.only(top: 6),
                    margin: EdgeInsets.only(
                      bottom: MediaQuery.of(ctx).viewInsets.bottom,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1C1C1E)
                          : CupertinoColors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                CupertinoButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                                Text(
                                  hint,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                CupertinoButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(
                                    'Done',
                                    style: TextStyle(
                                      color: AuthPalette.coral,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey[300],
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                          Expanded(
                            child: CupertinoPicker(
                              magnification: 1.22,
                              squeeze: 1.2,
                              useMagnifier: true,
                              itemExtent: 36.0,
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
                                  .map(
                                    (item) => Center(
                                      child: Text(
                                        item,
                                        style: TextStyle(
                                          fontSize: 16,
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
                  ),
                ),
              );
            },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E23).withValues(alpha: 0.40)
                  : Colors.grey[200]!.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value ?? hint,
                  style: TextStyle(
                    fontSize: 15,
                    color: value == null
                        ? (isDark ? Colors.grey[500] : Colors.grey[400])
                        : (isDark ? Colors.white : Colors.black),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_down,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Grade labels ordered from lowest to highest for the slider
  static const List<String> _gradeLabels = ['F', 'D', 'C', 'B', 'A', 'E', 'O'];

  Widget _buildGradeSlider({
    required String subjectName,
    required double credits,
    required bool isDark,
  }) {
    final currentGrade = gradeMap[subjectName];
    final currentIndex = currentGrade != null
        ? _gradeLabels.indexOf(currentGrade).clamp(0, _gradeLabels.length - 1)
        : 0;
    final sliderValue = currentGrade != null ? currentIndex.toDouble() : 0.0;
    final points = currentGrade != null
        ? (gradeValues[currentGrade]! * credits)
        : 0.0;

    // Color for current grade position
    final gradeFraction = sliderValue / (_gradeLabels.length - 1);
    final gradeColor = Color.lerp(
      const Color(0xFFEF4444), // Red for F
      const Color(0xFF10B981), // Emerald for O
      gradeFraction,
    )!;

    return Column(
      children: [
        // Slider
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            activeTrackColor: gradeColor,
            inactiveTrackColor: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            thumbShape: _GradeThumbShape(
              gradeLabel: currentGrade ?? 'F',
              gradeColor: gradeColor,
              isDark: isDark,
            ),
            overlayColor: gradeColor.withValues(alpha: 0.15),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
          ),
          child: Slider(
            value: sliderValue,
            min: 0,
            max: (_gradeLabels.length - 1).toDouble(),
            divisions: _gradeLabels.length - 1,
            onChanged: (value) {
              final newIndex = value.round();
              final newGrade = _gradeLabels[newIndex];
              if (newGrade != gradeMap[subjectName]) {
                HapticFeedback.selectionClick();
              }
              setState(() {
                gradeMap[subjectName] = newGrade;
              });
              // Auto-recalculate if already calculated once
              if (calculatedCGPA != null) {
                _autoRecalculate();
              }
            },
          ),
        ),
        // Points display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              currentGrade != null
                  ? 'Grade: $currentGrade (${gradeValues[currentGrade]!.toStringAsFixed(0)} pts)'
                  : 'Slide to select grade',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: currentGrade != null
                    ? gradeColor
                    : (isDark ? Colors.grey[500] : Colors.grey[400]),
              ),
            ),
            Text(
              '${points.toStringAsFixed(1)} pts',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Custom thumb shape that displays the grade letter on a circular knob
class _GradeThumbShape extends SliderComponentShape {
  final String gradeLabel;
  final Color gradeColor;
  final bool isDark;

  const _GradeThumbShape({
    required this.gradeLabel,
    required this.gradeColor,
    required this.isDark,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(36, 36);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // Shadow
    final shadowPaint = Paint()
      ..color = gradeColor.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center + const Offset(0, 2), 17, shadowPaint);

    // Outer circle (accent color)
    final outerPaint = Paint()..color = gradeColor;
    canvas.drawCircle(center, 17, outerPaint);

    // Inner circle (white/dark)
    final innerPaint = Paint()
      ..color = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    canvas.drawCircle(center, 14, innerPaint);

    // Grade letter
    final textSpan = TextSpan(
      text: gradeLabel,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: gradeColor,
        height: 1,
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }
}
