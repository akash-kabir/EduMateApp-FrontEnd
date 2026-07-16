import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../../config.dart';
import '../../../widgets/toast_manager.dart';
import '../../../services/shared_preferences_service.dart';
import 'schedule_editor_screen.dart';
import '../../../constants/app_constants.dart';

class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  State<ScheduleManagementScreen> createState() => _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  bool _isLoading = true;
  // Map of semester -> schedule data
  Map<int, dynamic> _schedules = {};
  String _selectedSeason = 'Autumn';

  List<int> get _displayedSemesters => _selectedSeason == 'Autumn' ? [1, 3, 5, 7] : [2, 4, 6, 8];

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    setState(() => _isLoading = true);
    try {
        final response = await http.get(
          Uri.parse('${Config.scheduleBaseEndpoint}?t=${DateTime.now().millisecondsSinceEpoch}'),
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
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null) return;
      
      setState(() => _isLoading = true);

      final file = result.files.first;
      String jsonString;
      if (file.path != null) {
        jsonString = await File(file.path!).readAsString();
      } else {
        final bytes = await file.readAsBytes();
        jsonString = String.fromCharCodes(bytes);
      }

      final jsonData = jsonDecode(jsonString);
      
      if (!jsonData.containsKey('classes') || jsonData['classes'] is! List) {
        throw Exception('Invalid JSON format: missing classes array');
      }

      final token = await SharedPreferencesService.getToken();
      if (token == null) throw Exception('Authentication token not found');

      final url = Uri.parse('${Config.scheduleBaseEndpoint}/$semester');
      
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
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 130, bottom: 40, left: 16, right: 16),
                    itemCount: _displayedSemesters.length,
                    itemBuilder: (context, index) {
                      final semester = _displayedSemesters[index];
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
                        isConfigured: isConfigured,
                        periodCount: periodCount,
                        isDark: isDark,
                        onUpload: () => _uploadSchedule(semester),
                        onUpdate: () => _fetchSchedules(),
                      );
                    },
                  ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141414).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.7),
                    border: Border(
                      bottom: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 50,
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  child: Icon(CupertinoIcons.back, color: isDark ? Colors.white : Colors.black),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  'Schedule Management',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Salena',
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: CupertinoSlidingSegmentedControl<String>(
                              groupValue: _selectedSeason,
                              thumbColor: AuthPalette.coral.withValues(alpha: 0.8),
                              backgroundColor: Colors.white.withValues(alpha: 0.06),
                              children: {
                                'Autumn': Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text('Autumn', style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    color: _selectedSeason == 'Autumn' ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                    fontSize: 13,
                                  )),
                                ),
                                'Spring': Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text('Spring', style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    color: _selectedSeason == 'Spring' ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                    fontSize: 13,
                                  )),
                                ),
                              },
                              onValueChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedSeason = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SemesterCard extends StatelessWidget {
  final int semester;
  final bool isConfigured;
  final int periodCount;
  final bool isDark;
  final VoidCallback onUpload;
  final VoidCallback onUpdate;

  const _SemesterCard({
    required this.semester,
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
        borderRadius: BorderRadius.circular(16),
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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isConfigured ? Colors.greenAccent : Colors.redAccent,
                width: 1.5,
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
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onUpload,
                    icon: const Icon(Icons.upload_file, size: 16),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Upload JSON', style: TextStyle(fontSize: 12)),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      backgroundColor: const Color(0xFFFF1744),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScheduleEditorScreen(
                            semester: semester,
                          ),
                        ),
                      ).then((_) => onUpdate());
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(isConfigured ? 'Edit Schedule' : 'Add Schedule', style: const TextStyle(fontSize: 12)),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      backgroundColor: isDark ? const Color(0xFF1E1E1E) : CupertinoColors.systemGrey6,
                      foregroundColor: isDark ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ))));
  }
}
