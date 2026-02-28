import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';
import '../../services/shared_preferences_service.dart';

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
    _fetchBranchesAndAutoSelect();
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
      final response = await http.get(Uri.parse(Config.allCurriculumsEndpoint));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final curriculums = (data['data'] as List).cast<Map<String, dynamic>>();

        final branchList = curriculums
            .map((c) => c['branch'].toString())
            .toList();

        setState(() {
          branches = branchList;
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
        Uri.parse('${Config.curriculumByBranchEndpoint}/$branch'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final curriculum = data['data'];
        final semesterList = List<Map<String, dynamic>>.from(
          curriculum['semesters'].map(
            (s) => {
              'semesterNumber': s['semesterNumber'],
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No subjects available for this semester'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    for (final subject in subjects) {
      if (!gradeMap.containsKey(subject['name'])) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter grade for ${subject['name']}'),
            backgroundColor: Colors.orange,
          ),
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
      // Blue to dark purple
      return LinearGradient(
        colors: [Colors.blue, Colors.deepPurple],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (cgpa >= 8.0 && cgpa < 9.5) {
      // Green to blue
      return LinearGradient(
        colors: [Colors.green, Colors.blue],
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
        middle: const Text('CGPA Calculator'),
        backgroundColor: isDark
            ? CupertinoColors.black.withOpacity(0.6)
            : CupertinoColors.white.withOpacity(0.6),
        border: Border(
          bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: Icon(
            CupertinoIcons.back,
            color: isDark
                ? CupertinoColors.systemBlue
                : const Color(0xFFFF1744),
          ),
        ),
      ),
      child: isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : Material(
              color: isDark ? CupertinoColors.black : CupertinoColors.white,
              child: SafeArea(
                child: SingleChildScrollView(
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

                      // Branch Dropdown
                      Text(
                        'Select Branch',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: DropdownMenu<String>(
                          controller: branchController,
                          initialSelection: selectedBranch,
                          dropdownMenuEntries: branches
                              .map(
                                (b) => DropdownMenuEntry(
                                  value: b,
                                  label: b,
                                  style: ButtonStyle(
                                    foregroundColor:
                                        MaterialStateProperty.resolveWith((
                                          states,
                                        ) {
                                          if (b == selectedBranch) {
                                            return Colors.blue;
                                          }
                                          return isDark
                                              ? Colors.white
                                              : Colors.black;
                                        }),
                                  ),
                                ),
                              )
                              .toList(),
                          onSelected: (value) {
                            if (value != null) {
                              setState(() => selectedBranch = value);
                              _fetchSemesters(value);
                            }
                          },
                          width: MediaQuery.of(context).size.width - 32,
                          hintText: 'Choose a branch',
                          menuStyle: MenuStyle(
                            backgroundColor: MaterialStateProperty.all(
                              isDark ? Colors.grey[900] : Colors.white,
                            ),
                            elevation: MaterialStateProperty.all(8),
                            shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            shadowColor: MaterialStateProperty.all(
                              Colors.black.withOpacity(0.2),
                            ),
                          ),
                          inputDecorationTheme: InputDecorationTheme(
                            fillColor: isDark
                                ? Colors.grey[900]
                                : Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? CupertinoColors.systemBlue
                                    : const Color(0xFFFF1744),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[400],
                            ),
                          ),
                        ),
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
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0,
                              ),
                              child: DropdownMenu<int>(
                                controller: semesterController,
                                initialSelection: selectedSemesterNumber,
                                dropdownMenuEntries: semesters
                                    .map(
                                      (sem) => DropdownMenuEntry(
                                        value: sem['semesterNumber'] as int,
                                        label:
                                            'Semester ${sem['semesterNumber']}',
                                        style: ButtonStyle(
                                          foregroundColor:
                                              MaterialStateProperty.resolveWith(
                                                (states) {
                                                  if (sem['semesterNumber'] ==
                                                      selectedSemesterNumber) {
                                                    return Colors.blue;
                                                  }
                                                  return isDark
                                                      ? Colors.white
                                                      : Colors.black;
                                                },
                                              ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onSelected: (value) {
                                  if (value != null) {
                                    setState(
                                      () => selectedSemesterNumber = value,
                                    );
                                    _selectSemester(value);
                                  }
                                },
                                width: MediaQuery.of(context).size.width - 32,
                                hintText: 'Select a semester',
                                menuStyle: MenuStyle(
                                  backgroundColor: MaterialStateProperty.all(
                                    isDark ? Colors.grey[900] : Colors.white,
                                  ),
                                  elevation: MaterialStateProperty.all(8),
                                  shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  shadowColor: MaterialStateProperty.all(
                                    Colors.black.withOpacity(0.2),
                                  ),
                                ),
                                inputDecorationTheme: InputDecorationTheme(
                                  fillColor: isDark
                                      ? Colors.grey[900]
                                      : Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? Colors.grey[700]!
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? Colors.grey[700]!
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? CupertinoColors.systemBlue
                                          : const Color(0xFFFF1744),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[400],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),

                      // Past CGPA Card
                      if (selectedSemesterNumber != null &&
                          selectedSemesterNumber! > 1)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[900] : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey[800]!
                                  : Colors.grey[300]!,
                            ),
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
                                      ? Colors.grey[850]
                                      : Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? Colors.grey[700]!
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? Colors.grey[700]!
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? CupertinoColors.systemBlue
                                          : const Color(0xFFFF1744),
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

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.grey[900]
                                        : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.grey[800]!
                                          : Colors.grey[300]!,
                                    ),
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
                                      // Grade and Points Row
                                      Row(
                                        children: [
                                          // Grade dropdown
                                          SizedBox(
                                            width: 120,
                                            child: DropdownMenu<String>(
                                              controller:
                                                  gradeControllers[subjectName]!,
                                              initialSelection:
                                                  gradeMap[subjectName],
                                              dropdownMenuEntries: gradeValues
                                                  .keys
                                                  .map(
                                                    (g) => DropdownMenuEntry(
                                                      value: g,
                                                      label: g,
                                                      style: ButtonStyle(
                                                        foregroundColor:
                                                            MaterialStateProperty.resolveWith((
                                                              states,
                                                            ) {
                                                              if (g ==
                                                                  gradeMap[subjectName]) {
                                                                return Colors
                                                                    .blue;
                                                              }
                                                              return isDark
                                                                  ? Colors.white
                                                                  : Colors
                                                                        .black;
                                                            }),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                              onSelected: (value) {
                                                if (value != null) {
                                                  setState(() {
                                                    gradeMap[subjectName] =
                                                        value;
                                                  });
                                                }
                                              },
                                              hintText: 'Grade',
                                              menuStyle: MenuStyle(
                                                backgroundColor:
                                                    MaterialStateProperty.all(
                                                      isDark
                                                          ? Colors.grey[900]
                                                          : Colors.white,
                                                    ),
                                                elevation:
                                                    MaterialStateProperty.all(
                                                      8,
                                                    ),
                                                shape: MaterialStateProperty.all(
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                                shadowColor:
                                                    MaterialStateProperty.all(
                                                      Colors.black.withOpacity(
                                                        0.2,
                                                      ),
                                                    ),
                                              ),
                                              inputDecorationTheme: InputDecorationTheme(
                                                fillColor: isDark
                                                    ? Colors.grey[850]
                                                    : Colors.grey[50],
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  borderSide: BorderSide(
                                                    color: isDark
                                                        ? Colors.grey[700]!
                                                        : Colors.grey[300]!,
                                                  ),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: isDark
                                                            ? Colors.grey[700]!
                                                            : Colors.grey[300]!,
                                                      ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: isDark
                                                            ? CupertinoColors
                                                                  .systemBlue
                                                            : const Color(
                                                                0xFFFF1744,
                                                              ),
                                                        width: 2,
                                                      ),
                                                    ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 10,
                                                    ),
                                                hintStyle: TextStyle(
                                                  color: isDark
                                                      ? Colors.grey[500]
                                                      : Colors.grey[400],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Points display
                                          Text(
                                            gradeMap[subjectName] != null
                                                ? '${((gradeValues[gradeMap[subjectName]]!) * credits).toStringAsFixed(1)} pts'
                                                : '0.0 pts',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? Colors.grey[300]
                                                  : Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
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
                                        color: isDark
                                            ? CupertinoColors.systemBlue
                                            : const Color(0xFFFF1744),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Calculate SGPA',
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
                          child: Container(
                            width: MediaQuery.of(context).size.width - 32,
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[900]
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.grey[800]!
                                    : Colors.grey[300]!,
                              ),
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
                      const SizedBox(height: 10),

                      // Overall CGPA Display for Semester 1 (just show SGPA)
                      if (selectedSemesterNumber == 1 && calculatedCGPA != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          child: Container(
                            width: MediaQuery.of(context).size.width - 32,
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[900]
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.grey[800]!
                                    : Colors.grey[300]!,
                              ),
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
                      // Overall CGPA Display for Semester > 1 (with past CGPA calculation)
                      if (selectedSemesterNumber != null &&
                          selectedSemesterNumber! > 1 &&
                          overallCGPA != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          child: Container(
                            width: MediaQuery.of(context).size.width - 32,
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[900]
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.grey[800]!
                                    : Colors.grey[300]!,
                              ),
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
              ),
            ),
    );
  }
}
