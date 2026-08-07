import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app/shared/config.dart';
import 'package:app/features/auth_and_profile/services/token_refresh_service.dart';
import 'package:app/shared/widgets/dialogs/toast_manager.dart';
import 'package:app/shared/widgets/dialogs/custom_glass_dialog.dart';

class AdminStudentDataManagementScreen extends StatefulWidget {
  const AdminStudentDataManagementScreen({super.key});

  @override
  State<AdminStudentDataManagementScreen> createState() =>
      _AdminStudentDataManagementScreenState();
}

class _AdminStudentDataManagementScreenState
    extends State<AdminStudentDataManagementScreen> {
  bool _isLoading = true;
  List<dynamic> _datasets = [];

  final List<String> _years = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
  ];

  @override
  void initState() {
    super.initState();
    _fetchDatasets();
  }

  Future<void> _fetchDatasets() async {
    setState(() => _isLoading = true);
    try {
      final response = await TokenRefreshService.authenticatedGet(
          Config.studentDataBaseEndpoint);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _datasets = data['data'] ?? data ?? [];
        });
      } else {
        setState(() {
          _datasets = [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching student data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadJson({String? targetYear}) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final data = json.decode(content);

      if (data['year'] != targetYear) {
        if (!mounted) return;
        EduMateToast.showCompact(
          context,
          message: 'Error: JSON year (${data['year']}) does not match $targetYear',
          isSuccess: false,
        );
        return;
      }

      setState(() => _isLoading = true);

      final response = await TokenRefreshService.authenticatedPost(
        '${Config.studentDataBaseEndpoint}/upload',
        body: data,
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        EduMateToast.showCompact(
          context,
          message: '$targetYear data uploaded successfully!',
          isSuccess: true,
        );
        _fetchDatasets();
      } else {
        EduMateToast.showCompact(
          context,
          message: 'Failed to upload student data',
          isSuccess: false,
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(
          context,
          message: 'Error: ${e.toString()}',
          isSuccess: false,
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteDataset(String year, String semester) async {
    final bool? confirm = await showDeleteConfirmationDialog(
      context: context,
      title: 'Delete $year Data',
      description: 'Are you sure you want to delete the data for $year ($semester)?',
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final response = await TokenRefreshService.authenticatedDelete(
        '${Config.studentDataBaseEndpoint}/$year/$semester',
      );

      if (response.statusCode == 200) {
        if (mounted) {
          EduMateToast.showCompact(context,
              message: '$year deleted!', isSuccess: true);
        }
        _fetchDatasets();
      } else {
        if (mounted) {
          EduMateToast.showCompact(context,
              message: 'Failed to delete student data', isSuccess: false);
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(context,
            message: 'Error: $e', isSuccess: false);
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.only(
                              top: 65, bottom: 24, left: 20, right: 20),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              const SizedBox(height: 10),
                              if (_isLoading)
                                const Center(
                                    child: CupertinoActivityIndicator(radius: 14)),
                            ]),
                          ),
                        ),
                        if (!_isLoading)
                          SliverPadding(
                            padding: const EdgeInsets.only(
                                bottom: 24, left: 20, right: 20),
                            sliver: SliverList.separated(
                              itemCount: _years.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final targetYear = _years[index];
                                
                                // Find dataset for this year
                                final d = _datasets.cast<Map<String, dynamic>?>().firstWhere(
                                    (element) => element?['year'] == targetYear,
                                    orElse: () => null);

                                final isConfigured = d != null;
                                final semester = d?['semester']?.toString() ?? 'Not Set';
                                final count = d?['studentCount']?.toString() ?? '0';
                                final date = d != null && d['uploadedAt'] != null 
                                    ? DateTime.parse(d['uploadedAt']).toLocal().toString().split(' ')[0] 
                                    : 'N/A';

                                return Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141110),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.1),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.3),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            targetYear,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Poppins',
                                              color: Colors.white,
                                              letterSpacing: -0.4,
                                            ),
                                          ),
                                          if (isConfigured)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: const Text(
                                                'Configured',
                                                style: TextStyle(
                                                  color: Color(0xFF10B981),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      _buildInfoRow('Semester:', semester),
                                      const SizedBox(height: 8),
                                      _buildInfoRow('Students:', count),
                                      if (isConfigured) ...[
                                        const SizedBox(height: 8),
                                        _buildInfoRow('Uploaded:', date),
                                      ],
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildActionButton(
                                              context: context,
                                              icon: isConfigured 
                                                  ? CupertinoIcons.arrow_2_squarepath 
                                                  : CupertinoIcons.cloud_upload_fill,
                                              label: isConfigured ? 'Replace JSON' : 'Upload JSON',
                                              color: const Color(0xFF10B981), // Emerald Green
                                              onTap: () => _uploadJson(targetYear: targetYear),
                                            ),
                                          ),
                                          if (isConfigured) ...[
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _buildActionButton(
                                                context: context,
                                                icon: CupertinoIcons.trash_fill,
                                                label: 'Delete',
                                                color: const Color(0xFFDC2626), // Admin Red
                                                onTap: () => _deleteDataset(targetYear, d['semester'] ?? ''),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Top Header Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414).withValues(alpha: 0.6),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
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
                              child: const Icon(
                                CupertinoIcons.back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              'Student Data',
                              style: const TextStyle(
                                color: Colors.white,
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white54,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
