import 'dart:convert';
import 'dart:io';
import 'dart:ui';
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
  String? _selectedFileName;

  Future<void> _uploadHolidayJson() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final fileName = result.files.single.name;
      setState(() {
        _selectedFileName = fileName;
        _isLoading = true;
      });

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final data = json.decode(content);

      if (!data.containsKey('year') || !data.containsKey('holidays')) {
        if (!mounted) return;
        EduMateToast.showCompact(
          context,
          message: 'Invalid JSON format. Must contain "year" and "holidays".',
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
        EduMateToast.showCompact(
          context,
          message: 'Holidays calendar synced successfully!',
          isSuccess: true,
        );
      } else {
        EduMateToast.showCompact(
          context,
          message: 'Failed to upload holiday calendar',
          isSuccess: false,
        );
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF06B6D4), Color(0xFF0284C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              CupertinoIcons.calendar_badge_plus,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Academic Holidays',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Upload official KIIT holiday calendar JSON to sync across all student devices.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Upload Action Area
                    GestureDetector(
                      onTap: _isLoading ? null : _uploadHolidayJson,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? const [Color(0xFF303030), Color(0xFF1A1A1A)]
                                : const [Color(0xFFFFFFFF), Color(0xFFF3F4F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                : const Color(0xFF10B981).withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.arrow_up_doc_fill,
                                size: 36,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedFileName ?? 'Select Holiday List JSON File',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF111827),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap to browse files (.json format)',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_isLoading)
                              const CupertinoActivityIndicator(radius: 14)
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Choose JSON File',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Expected JSON Format Preview Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141414) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(CupertinoIcons.info_circle_fill, size: 18, color: Color(0xFF06B6D4)),
                              const SizedBox(width: 8),
                              Text(
                                'Expected JSON Schema',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '{\n'
                              '  "year": 2026,\n'
                              '  "holidays": [\n'
                              '    {\n'
                              '      "date": "2026-01-26",\n'
                              '      "name": "Republic Day"\n'
                              '    }\n'
                              '  ]\n'
                              '}',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12.5,
                                color: Color(0xFF38BDF8),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
                    child: SizedBox(
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
                              'Holidays',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Salena',
                                fontSize: 17,
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
          ),
        ],
      ),
    );
  }
}
