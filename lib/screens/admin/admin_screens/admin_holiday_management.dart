import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../config.dart';
import '../../../services/token_refresh_service.dart';
import '../../../widgets/toast_manager.dart';

class AdminHolidayManagementScreen extends StatefulWidget {
  const AdminHolidayManagementScreen({super.key});

  @override
  State<AdminHolidayManagementScreen> createState() => _AdminHolidayManagementScreenState();
}

class _AdminHolidayManagementScreenState extends State<AdminHolidayManagementScreen> {
  bool _isLoading = false;

  Future<void> _uploadHolidayJson() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      setState(() => _isLoading = true);

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final data = json.decode(content);

      if (!data.containsKey('year') || !data.containsKey('holidays')) {
        if (!mounted) return;
        EduMateToast.showCompact(
          context,
          message: 'Invalid JSON format. Expected "year" and "holidays".',
          isSuccess: false,
        );
        setState(() => _isLoading = false);
        return;
      }

      final response = await TokenRefreshService.authenticatedPost(
        '${Config.holidayBaseEndpoint}/upload',
        body: data,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        EduMateToast.showCompact(context, message: 'Holidays uploaded successfully', isSuccess: true);
      } else {
        EduMateToast.showCompact(context, message: 'Failed to upload holidays', isSuccess: false);
      }
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(context, message: 'Error: ${e.toString()}', isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Holiday Management',
          style: TextStyle(fontFamily: 'Salena', fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark
            ? CupertinoColors.black.withOpacity(0.6)
            : CupertinoColors.white.withOpacity(0.6),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Icon(
                  CupertinoIcons.calendar_badge_plus,
                  size: 64,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                const SizedBox(height: 24),
                Text(
                  'Upload Holiday List JSON',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a JSON file containing the holidays for an academic year.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                if (_isLoading)
                  const Center(child: CupertinoActivityIndicator(radius: 16))
                else
                  CupertinoButton(
                    color: const Color(0xFFFF9B7A),
                    borderRadius: BorderRadius.circular(12),
                    onPressed: _uploadHolidayJson,
                    child: const Text(
                      'Upload JSON',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
