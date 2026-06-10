import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../../config.dart';
import '../../../widgets/toast_manager.dart';
import '../../../services/shared_preferences_service.dart';
import 'schedule_editor_screen.dart';


class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  State<ScheduleManagementScreen> createState() => _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  bool _isLoading = true;
  String _selectedBranch = 'CSE';
  final List<String> _branches = ['CSE', 'CSCE', 'IT', 'CSSE'];
  
  // Map of semester -> schedule data
  Map<int, dynamic> _schedules = {};

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    setState(() => _isLoading = true);
    try {
        final response = await http.get(
          Uri.parse('${Config.scheduleBaseEndpoint}/branch/$_selectedBranch?t=${DateTime.now().millisecondsSinceEpoch}'),
        );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['data'] as List;
        
        final Map<int, dynamic> parsed = {};
        for (var item in items) {
          parsed[item['semester']] = item;
        }
        
        setState(() {
          _schedules = parsed;
          _isLoading = false;
        });
      } else {
        setState(() {
          _schedules = {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(
          context,
          message: 'Failed to fetch schedules: $e',
          isSuccess: false,
        );
      }
      setState(() => _isLoading = false);
    }
  }


  Future<void> _uploadSchedule(int semester) async {
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
      
      if (!jsonData.containsKey('classes') || jsonData['classes'] is! List) {
        throw Exception('Invalid JSON format: missing classes array');
      }

      final token = await SharedPreferencesService.getToken();
      if (token == null) throw Exception('Authentication token not found');

      final url = Uri.parse('${Config.scheduleBaseEndpoint}/$_selectedBranch/$semester');
      
      http.Response response;
      if (_schedules[semester] != null) {
        response = await http.put(
          url,
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode({'classes': jsonData['classes']}),
        );
      } else {
        response = await http.post(
          url,
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode({'classes': jsonData['classes']}),
        );
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
         throw Exception('Failed to upload: ${response.statusCode} - ${response.body}');
      }
      
      if (mounted) {
        EduMateToast.showSuccessCard(context, title: 'Success', description: 'Schedule uploaded successfully for Semester $semester');
      }
      
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(context, message: 'Upload error: $e', isSuccess: false);
      }
    } finally {
      _fetchSchedules();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Schedule Management',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
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
                Text(
                  'Select Branch',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? CupertinoColors.systemGrey6.withValues(alpha: 0.3) : CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedBranch,
                      isExpanded: true,
                      dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedBranch = newValue;
                          });
                          _fetchSchedules();
                        }
                      },
                      items: _branches.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
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
                      final data = _schedules[semester];
                      final isConfigured = data != null;
                      
                      // Count total periods across all days
                      int periodCount = 0;
                      if (isConfigured && data['classes'] != null) {
                        for (var section in data['classes']) {
                          if (section['schedule'] != null) {
                            for (var day in section['schedule']) {
                              periodCount += (day['periods'] as List).length;
                            }
                          }
                        }
                      }

                      return _SemesterCard(
                        semester: semester,
                        branch: _selectedBranch,
                        isConfigured: isConfigured,
                        periodCount: periodCount,
                        isDark: isDark,
                        onUpload: () => _uploadSchedule(semester),
                        onUpdate: () => _fetchSchedules(),
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
  final int periodCount;
  final bool isDark;
  final VoidCallback onUpload;
  final VoidCallback onUpdate;

  const _SemesterCard({
    required this.semester,
    required this.branch,
    required this.isConfigured,
    required this.periodCount,
    required this.isDark,
    required this.onUpload,
    required this.onUpdate,
  });


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? CupertinoColors.systemGrey6.withValues(alpha: 0.3) : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConfigured 
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
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
              isConfigured ? '$periodCount total periods scheduled' : 'No schedule added yet',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? CupertinoColors.systemGrey : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Upload JSON'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF1744),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScheduleEditorScreen(
                          branch: branch,
                          semester: semester,
                        ),
                      ),
                    ).then((_) => onUpdate());
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text(isConfigured ? 'Edit Schedule' : 'Add Schedule'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1E1E1E) : CupertinoColors.systemGrey6,
                    foregroundColor: isDark ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: const Color(0xFFFF1744).withValues(alpha: 0.3)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
