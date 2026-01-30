import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config.dart';

class AdminUploadScreen extends StatefulWidget {
  const AdminUploadScreen({super.key});

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Upload Management',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Manage curriculum and schedule uploads',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? CupertinoColors.systemGrey : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),
            _UploadCard(
              title: 'Curriculum',
              description: 'Upload course curriculum data via JSON',
              icon: Icons.school_rounded,
              isDark: isDark,
              onTap: () {
                _showCurriculumUploadBottomSheet(context, isDark);
              },
            ),
            const SizedBox(height: 16),
            _UploadCard(
              title: 'Schedule',
              description: 'Upload and manage class schedules',
              icon: Icons.schedule_rounded,
              isDark: isDark,
              onTap: () {
                _showScheduleUploadBottomSheet(context, isDark);
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _showCurriculumUploadBottomSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.black, width: 2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return _CurriculumUploadContent(
              isDark: isDark,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  void _showScheduleUploadBottomSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.black, width: 2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return _ScheduleUploadContent(
              isDark: isDark,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }
}

class _UploadCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _UploadCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isDark
              ? CupertinoColors.systemGrey6.withOpacity(0.3)
              : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFF1744).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF1744).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFFFF1744), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? CupertinoColors.systemGrey
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.forward, color: const Color(0xFFFF1744)),
          ],
        ),
      ),
    );
  }
}

class _CurriculumUploadContent extends StatefulWidget {
  final bool isDark;
  final ScrollController scrollController;

  const _CurriculumUploadContent({
    required this.isDark,
    required this.scrollController,
  });

  @override
  State<_CurriculumUploadContent> createState() =>
      _CurriculumUploadContentState();
}

class _CurriculumUploadContentState extends State<_CurriculumUploadContent> {
  bool _isLoading = false;
  String? _selectedFileName;
  Map<String, dynamic>? _selectedFileData;

  Future<void> _pickJsonFile() async {
    try {
      // Use pickFiles for both mobile and web
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No file selected'),
              backgroundColor: Colors.grey,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final file = result.files.first;
      final fileName = file.name;

      String jsonString;
      try {
        // For web, use bytes; for mobile, use path
        if (file.bytes != null) {
          // Web platform
          jsonString = String.fromCharCodes(file.bytes!);
          print('Web: Loaded JSON from bytes');
        } else if (file.path != null) {
          // Mobile platform
          final fileObj = File(file.path!);
          jsonString = await fileObj.readAsString();
          print('Mobile: Loaded JSON from file path');
        } else {
          throw Exception('Unable to read file: no bytes or path available');
        }
      } catch (readError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error reading file: $readError'),
              backgroundColor: const Color(0xFFFF1744),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Debug: Print JSON for troubleshooting
      print('Selected JSON content: $jsonString');

      final jsonData = jsonDecode(jsonString);

      // Validate: must have 'branch' and 'semesters' array
      if (!jsonData.containsKey('branch')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid JSON: missing "branch" field'),
              backgroundColor: Color(0xFFFF1744),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      if (!jsonData.containsKey('semesters') ||
          jsonData['semesters'] is! List ||
          (jsonData['semesters'] as List).isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Invalid JSON: must contain non-empty "semesters" array',
              ),
              backgroundColor: Color(0xFFFF1744),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedFileName = fileName;
        _selectedFileData = jsonData;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selected: $fileName (${(jsonData['semesters'] as List).length} semesters)',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('File picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF1744),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _uploadCurriculum() async {
    if (_selectedFileData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final userRole = prefs.getString('userRole');

      print('DEBUG: Token = $token');
      print('DEBUG: User Role = $userRole');

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication token not found. Please login again as a Society Head.',
        );
      }

      if (userRole != 'society_head') {
        throw Exception(
          'Access denied: Only Society Heads can upload curriculum. Your role: $userRole',
        );
      }

      final response = await http.post(
        Uri.parse(Config.curriculumUploadEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(_selectedFileData),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Curriculum uploaded successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        print(
          'Upload error response: ${response.statusCode} - ${response.body}',
        );
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(
            errorData['message'] ?? 'Upload failed: ${response.statusCode}',
          );
        } catch (parseError) {
          throw Exception(
            'Upload failed: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Upload Error'),
            content: SingleChildScrollView(
              child: SelectableText(
                'Error: $e\n\nIf the error mentions "namespace", please check that:\n1. The JSON has "branch" field\n2. All semesters have "semesterNumber"\n3. All subjects have "name", "credits", "type", and "shortName"',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Upload Curriculum',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: widget.isDark
                  ? CupertinoColors.white
                  : CupertinoColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload course curriculum data via JSON file',
            style: TextStyle(
              fontSize: 14,
              color: widget.isDark
                  ? CupertinoColors.systemGrey
                  : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? CupertinoColors.systemGrey6.withOpacity(0.3)
                  : CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF1744).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_rounded,
                  size: 64,
                  color: const Color(0xFFFF1744),
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedFileName ?? 'Select JSON File',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedFileName != null
                      ? 'File ready to upload'
                      : 'Choose a JSON file containing curriculum data',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isDark
                        ? CupertinoColors.systemGrey
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickJsonFile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    backgroundColor: const Color(0xFFFF1744),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  icon: const Icon(Icons.file_upload_rounded),
                  label: const Text('Choose File'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_selectedFileName != null) ...[
            ElevatedButton(
              onPressed: _isLoading ? null : _uploadCurriculum,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: const Color(0xFFFF1744),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Upload Curriculum',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFF1744).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: const Color(0xFFFF1744)),
                    const SizedBox(width: 8),
                    Text(
                      'File Format',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• File must be in JSON format\n'
                  '• Should contain branch and semesters data\n'
                  '• Each semester must have subjects array\n'
                  '• Each subject needs: name, credits, type\n'
                  '• Validate before uploading',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isDark
                        ? CupertinoColors.systemGrey
                        : Colors.grey[600],
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ScheduleUploadContent extends StatefulWidget {
  final bool isDark;
  final ScrollController scrollController;

  const _ScheduleUploadContent({
    required this.isDark,
    required this.scrollController,
  });

  @override
  State<_ScheduleUploadContent> createState() => _ScheduleUploadContentState();
}

class _ScheduleUploadContentState extends State<_ScheduleUploadContent> {
  bool _isLoading = false;
  String? _selectedFileName;
  Map<String, dynamic>? _selectedFileData;

  Future<void> _pickJsonFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No file selected'),
              backgroundColor: Colors.grey,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final file = result.files.first;
      final fileName = file.name;

      String jsonString;
      try {
        if (file.bytes != null) {
          jsonString = String.fromCharCodes(file.bytes!);
          print('Web: Loaded JSON from bytes');
        } else if (file.path != null) {
          final fileObj = File(file.path!);
          jsonString = await fileObj.readAsString();
          print('Mobile: Loaded JSON from file path');
        } else {
          throw Exception('Unable to read file: no bytes or path available');
        }
      } catch (readError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error reading file: $readError'),
              backgroundColor: const Color(0xFFFF1744),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      print('Selected JSON content: $jsonString');

      final jsonData = jsonDecode(jsonString);

      // Validate: must have 'classes' array
      if (!jsonData.containsKey('classes') ||
          jsonData['classes'] is! List ||
          (jsonData['classes'] as List).isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Invalid JSON: must contain non-empty "classes" array',
              ),
              backgroundColor: Color(0xFFFF1744),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedFileName = fileName;
        _selectedFileData = jsonData;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selected: $fileName (${(jsonData['classes'] as List).length} classes)',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('File picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF1744),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _uploadSchedule() async {
    if (_selectedFileData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final userRole = prefs.getString('userRole');

      print('DEBUG: Token = $token');
      print('DEBUG: User Role = $userRole');

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication token not found. Please login again as a Society Head.',
        );
      }

      if (userRole != 'society_head') {
        throw Exception(
          'Access denied: Only Society Heads can upload schedule. Your role: $userRole',
        );
      }

      final response = await http.post(
        Uri.parse(Config.scheduleUploadEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(_selectedFileData),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Schedule uploaded successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        print(
          'Upload error response: ${response.statusCode} - ${response.body}',
        );
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(
            errorData['message'] ?? 'Upload failed: ${response.statusCode}',
          );
        } catch (parseError) {
          throw Exception(
            'Upload failed: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Upload Error'),
            content: SingleChildScrollView(
              child: SelectableText(
                'Error: $e\n\nIf the error mentions "namespace", please check that:\n1. The JSON has "classes" array\n2. Each class has "name" and "schedule"\n3. Schedule contains class periods with startTime, endTime, className, room',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Upload Schedule',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: widget.isDark
                  ? CupertinoColors.white
                  : CupertinoColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload class schedules via JSON file',
            style: TextStyle(
              fontSize: 14,
              color: widget.isDark
                  ? CupertinoColors.systemGrey
                  : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? CupertinoColors.systemGrey6.withOpacity(0.3)
                  : CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF1744).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 64,
                  color: const Color(0xFFFF1744),
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedFileName ?? 'Select JSON File',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedFileName != null
                      ? 'File ready to upload'
                      : 'Choose a JSON file containing class schedule data',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isDark
                        ? CupertinoColors.systemGrey
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickJsonFile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    backgroundColor: const Color(0xFFFF1744),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  icon: const Icon(Icons.file_upload_rounded),
                  label: const Text('Choose File'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_selectedFileName != null) ...[
            ElevatedButton(
              onPressed: _isLoading ? null : _uploadSchedule,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: const Color(0xFFFF1744),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Upload Schedule',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFF1744).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: const Color(0xFFFF1744)),
                    const SizedBox(width: 8),
                    Text(
                      'File Format',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• File must be in JSON format\n'
                  '• Should contain classes array\n'
                  '• Each class must have "name" and "schedule"\n'
                  '• Schedule contains periods with startTime, endTime, className, room\n'
                  '• Validate before uploading',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isDark
                        ? CupertinoColors.systemGrey
                        : Colors.grey[600],
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
