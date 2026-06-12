import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config.dart';
import '../../../widgets/toast_manager.dart';
import '../../../services/shared_preferences_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'curriculum_editor_screen.dart';
import '../../../widgets/bottom_sheet_selector.dart';

class CurriculumManagementScreen extends StatefulWidget {
  const CurriculumManagementScreen({super.key});

  @override
  State<CurriculumManagementScreen> createState() => _CurriculumManagementScreenState();
}

class _CurriculumManagementScreenState extends State<CurriculumManagementScreen> {
  bool _isLoading = true;
  String _selectedBranch = 'CSE';
  final List<String> _branches = ['CSE', 'CSCE', 'IT', 'CSSE'];
  
  // Map of semester -> curriculum data
  Map<int, dynamic> _curriculums = {};

  @override
  void initState() {
    super.initState();
    _fetchCurriculums();
  }

  Future<void> _fetchCurriculums() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${Config.curriculumBaseEndpoint}/branch/$_selectedBranch'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['data'];
        
        final Map<int, dynamic> parsed = {};
        if (items is List) {
          for (var item in items) {
            if (item['semester'] != null) {
              parsed[item['semester']] = item;
            }
          }
        }
        
        setState(() {
          _curriculums = parsed;
          _isLoading = false;
        });
      } else {
        setState(() {
          _curriculums = {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(
          context,
          message: 'Failed to fetch curriculums: $e',
          isSuccess: false,
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBulkUpload() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null) return;
      
      setState(() => _isLoading = true);

      final file = result.files.first;
      String jsonString;
      if (file.bytes != null) {
        jsonString = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        jsonString = await File(file.path!).readAsString();
      } else {
        throw Exception('Unable to read file');
      }

      final jsonData = jsonDecode(jsonString);
      
      if (!jsonData.containsKey('semesters') || jsonData['semesters'] is! List) {
        throw Exception('Invalid JSON format: missing semesters array');
      }

      final token = await SharedPreferencesService.getToken();
      if (token == null) throw Exception('Authentication token not found');

      final semesters = jsonData['semesters'] as List;
      
      for (var sem in semesters) {
        final int semesterNum = sem['semesterNumber'];
        final subjects = sem['subjects'] as List;
        
        final mappedSubjects = subjects.map((s) {
          String type = s['type'] == 'Theory' ? 'Core' : s['type'];
          if (!['Core', 'Elective', 'Lab', 'Project', 'Practical', 'Open Elective', 'Viva'].contains(type)) {
            type = 'Core';
          }
          return {
            'name': s['name'],
            'code': s['shortName'] ?? 'SUB',
            'credits': s['credits'],
            'type': type,
          };
        }).toList();

        final url = Uri.parse('${Config.curriculumBaseEndpoint}/$_selectedBranch/$semesterNum');
        
        http.Response response;
        if (_curriculums[semesterNum] != null) {
          response = await http.put(
            url,
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
            body: jsonEncode({'subjects': mappedSubjects}),
          );
        } else {
          response = await http.post(
            url,
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
            body: jsonEncode({'subjects': mappedSubjects}),
          );
        }

        if (response.statusCode != 200 && response.statusCode != 201) {
           throw Exception('Failed for sem $semesterNum: ${response.statusCode} - ${response.body}');
        }
      }
      
      if (mounted) {
        EduMateToast.showSuccessCard(context, title: 'Success', description: 'Bulk upload completed successfully');
      }
      
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(context, message: 'Bulk upload error: $e', isSuccess: false);
      }
    } finally {
      _fetchCurriculums();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
      appBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        middle: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Curriculum Management',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontFamily: 'Salena',
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BottomSheetSelector<String>(
                  value: _selectedBranch,
                  items: _branches,
                  hint: 'Select Branch',
                  isAdmin: true,
                  labelBuilder: (String value) => value,
                  onChanged: (String newValue) {
                    setState(() {
                      _selectedBranch = newValue;
                    });
                    _fetchCurriculums();
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleBulkUpload,
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Bulk Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: 8,
                    itemBuilder: (context, index) {
                      final semester = index + 1;
                      final data = _curriculums[semester];
                      final isConfigured = data != null;
                      final subjectCount = isConfigured ? (data['subjects'] as List).length : 0;

                      return _SemesterCard(
                        semester: semester,
                        branch: _selectedBranch,
                        isConfigured: isConfigured,
                        subjectCount: subjectCount,
                        isDark: isDark,
                        onUpdate: _fetchCurriculums,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SemesterCard extends StatelessWidget {
  final int semester;
  final String branch;
  final bool isConfigured;
  final int subjectCount;
  final bool isDark;
  final VoidCallback onUpdate;

  const _SemesterCard({
    required this.semester,
    required this.branch,
    required this.isConfigured,
    required this.subjectCount,
    required this.isDark,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: isConfigured 
            ? Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.8), width: 1.5)
            : Border.all(color: Colors.transparent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: isConfigured ? 18.0 : 10.0, 
            sigmaY: isConfigured ? 18.0 : 10.0
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isConfigured 
                  ? const Color.fromARGB(255, 2, 56, 38).withValues(alpha: 0.14)
                  : (isDark ? Colors.black.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.65)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Semester $semester',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isConfigured 
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isConfigured ? 'Configured' : 'Not Configured',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isConfigured ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isConfigured ? '$subjectCount Subjects' : 'No subjects added yet',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? CupertinoColors.systemGrey : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CurriculumEditorScreen(
                          branch: branch,
                          semester: semester,
                        ),
                      ),
                    ).then((_) => onUpdate());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF1744),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(isConfigured ? 'Edit Curriculum' : 'Add Curriculum'),
                ),
              ],
            ),
          ],
        ),
      ),
    ))));
  }
}
