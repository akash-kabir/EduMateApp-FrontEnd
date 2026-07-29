import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app/shared/config.dart';
import 'package:app/shared/services/holiday_service.dart';
import 'package:app/features/auth_and_profile/services/token_refresh_service.dart';
import 'package:app/shared/widgets/dialogs/toast_manager.dart';
import 'package:app/shared/widgets/dialogs/custom_glass_dialog.dart';

class AdminHolidayManagementScreen extends StatefulWidget {
  const AdminHolidayManagementScreen({super.key});

  @override
  State<AdminHolidayManagementScreen> createState() => _AdminHolidayManagementScreenState();
}

class _AdminHolidayManagementScreenState extends State<AdminHolidayManagementScreen> {
  bool _isExpanded = false;
  int _year = DateTime.now().year;
  List<dynamic> _holidays = [];

  @override
  void initState() {
    super.initState();
    _fetchHolidays();
  }

  Future<void> _fetchHolidays() async {
    try {
      final result = await HolidayService.fetchHolidays(_year);
      if (result['success'] == true && result['data'] != null) {
        final rawData = result['data'];
        List<dynamic> list = [];
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map) {
          if (rawData['holidays'] is List) {
            list = rawData['holidays'];
          }
          if (rawData['year'] != null && rawData['year'] is int) {
            _year = rawData['year'];
          }
        }
        setState(() {
          _holidays = List.from(list);
        });
      } else {
        setState(() {
          _holidays = [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching holidays: $e');
    }
  }

  String _formatHolidayDate(dynamic h) {
    final start = h['startDate'] ?? h['date'] ?? '';
    final end = h['endDate'] ?? '';
    if (end.isNotEmpty && end != start) {
      return '$start - $end';
    }
    return start.toString();
  }

  Future<void> _uploadHolidayJson() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

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
          message: 'Holiday calendar synced successfully!',
          isSuccess: true,
        );
        if (data['year'] != null) {
          _year = data['year'];
        }
        _isExpanded = true;
        _fetchHolidays();
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
    }
  }

  Future<void> _deleteIndividualHoliday(int index) async {
    final holiday = _holidays[index];
    final String name = (holiday['event'] ??
            holiday['name'] ??
            holiday['title'] ??
            holiday['holidayName'] ??
            holiday['description'] ??
            'Holiday')
        .toString();

    final bool? confirm = await showDeleteConfirmationDialog(
      context: context,
      title: 'Delete Holiday',
      description: 'Are you sure you want to delete "$name"?',
    );

    if (confirm != true) return;

    try {
      final updatedList = List.from(_holidays)..removeAt(index);
      final payload = {
        'year': _year,
        'holidays': updatedList,
      };

      final response = await TokenRefreshService.authenticatedPost(
        '${Config.holidayBaseEndpoint}/upload',
        body: payload,
      );

      if (response.statusCode == 200) {
        if (mounted) {
          EduMateToast.showCompact(context, message: '$name deleted!', isSuccess: true);
        }
        _fetchHolidays();
      } else {
        if (mounted) {
          EduMateToast.showCompact(context, message: 'Failed to delete holiday', isSuccess: false);
        }
      }
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(context, message: 'Error: $e', isSuccess: false);
      }
    }
  }

  void _showQuickAddDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _QuickAddHolidayDialog(
        year: _year,
        onAdd: (newHoliday) async {
          Navigator.pop(context);
          try {
            final updatedList = List.from(_holidays)..add(newHoliday);
            final payload = {
              'year': _year,
              'holidays': updatedList,
            };
            final response = await TokenRefreshService.authenticatedPost(
              '${Config.holidayBaseEndpoint}/upload',
              body: payload,
            );
            if (response.statusCode == 200) {
              if (mounted) {
                EduMateToast.showCompact(context, message: 'Holiday added!', isSuccess: true);
              }
              _isExpanded = true;
              _fetchHolidays();
            } else {
              if (mounted) {
                EduMateToast.showCompact(context, message: 'Failed to add holiday', isSuccess: false);
              }
            }
          } catch (e) {
            if (mounted) {
              EduMateToast.showCompact(context, message: 'Error: $e', isSuccess: false);
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 65, bottom: 24, left: 20, right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),

                    // Big Expandable Card: Holiday
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: const Color(0xFF141110),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Holiday',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                Icon(
                                  _isExpanded
                                      ? CupertinoIcons.chevron_up_circle_fill
                                      : CupertinoIcons.chevron_down_circle_fill,
                                  color: Colors.white38,
                                  size: 24,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Year : $_year',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'No of holidays : ${_holidays.length}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Action Row: Upload/Replace JSON and View/Hide side-by-side equal width
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionButton(
                                    context: context,
                                    icon: CupertinoIcons.arrow_up_doc_fill,
                                    label: _holidays.isNotEmpty ? 'Replace JSON' : 'Upload JSON',
                                    color: const Color(0xFF10B981), // Emerald Green

                                    onTap: _uploadHolidayJson,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildActionButton(
                                    context: context,
                                    icon: _isExpanded ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill,
                                    label: _isExpanded ? 'Hide' : 'View',
                                    color: const Color(0xFF06B6D4), // Deep Teal

                                    onTap: () {
                                      setState(() {
                                        _isExpanded = !_isExpanded;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),

                            // Inline Expanded List of Holidays
                            if (_isExpanded) ...[
                              const SizedBox(height: 16),
                              Divider(
                                color: Colors.white12,
                                height: 1,
                              ),
                              const SizedBox(height: 12),
                              _holidays.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: Center(
                                        child: Text(
                                          'No holidays configured for $_year',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _holidays.length,
                                      separatorBuilder: (_, __) => Divider(
                                        height: 1,
                                        color: Colors.white10,
                                      ),
                                      itemBuilder: (context, index) {
                                        final h = _holidays[index];
                                        final String name = (h['event'] ??
                                                h['name'] ??
                                                h['title'] ??
                                                h['holidayName'] ??
                                                h['description'] ??
                                                'Holiday')
                                            .toString();
                                        final dateStr = _formatHolidayDate(h);

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      name,
                                                      style: TextStyle(
                                                        fontSize: 14.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          CupertinoIcons.calendar,
                                                          size: 13,
                                                          color: Color(0xFF10B981),
                                                        ),
                                                        const SizedBox(width: 5),
                                                        Text(
                                                          dateStr,
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            fontFamily: 'monospace',
                                                            fontWeight: FontWeight.w600,
                                                            color: Color(0xFF10B981),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  CupertinoIcons.trash_fill,
                                                  size: 18,
                                                  color: Color(0xFFDC2626), // Admin Red
                                                ),
                                                onPressed: () => _deleteIndividualHoliday(index),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick Add Holiday Button (Admin Red)
                    GestureDetector(
                      onTap: _showQuickAddDialog,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.add_circled_solid, size: 18, color: Color(0xFFDC2626)),
                            SizedBox(width: 8),
                            Text(
                              'Quick Add Holiday',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
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

          // Top Header Bar
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
                              child: Icon(
                                CupertinoIcons.back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              'Holidays',
                              style: TextStyle(
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

class _QuickAddHolidayDialog extends StatefulWidget {
  final int year;
  final Function(Map<String, dynamic>) onAdd;

  const _QuickAddHolidayDialog({required this.year, required this.onAdd});

  @override
  State<_QuickAddHolidayDialog> createState() => _QuickAddHolidayDialogState();
}

class _QuickAddHolidayDialogState extends State<_QuickAddHolidayDialog> {
  final _nameController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startDateController.text = '${widget.year}-01-01';
  }

  @override
  Widget build(BuildContext context) {


    return Material(
      color: Colors.transparent,
      child: Container(
        height: 360,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Add Holiday',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    final name = _nameController.text.trim();
                    final startDate = _startDateController.text.trim();
                    final endDate = _endDateController.text.trim();
                    if (name.isEmpty || startDate.isEmpty) {
                      EduMateToast.showCompact(context, message: 'Please enter Name and Start Date', isSuccess: false);
                      return;
                    }
                    widget.onAdd({
                      'event': name,
                      'name': name,
                      'startDate': startDate,
                      'endDate': endDate.isNotEmpty ? endDate : startDate,
                    });
                  },
                  child: const Text(
                    'Add',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626), // Admin Red
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _nameController,
              placeholder: 'Holiday Name (e.g. Durga Puja)',
              padding: const EdgeInsets.all(14),
              style: const TextStyle(color: Colors.white),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: CupertinoTextField(
                    controller: _startDateController,
                    placeholder: 'Start Date (YYYY-MM-DD)',
                    padding: const EdgeInsets.all(14),
                    style: const TextStyle(color: Colors.white),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CupertinoTextField(
                    controller: _endDateController,
                    placeholder: 'End Date (Optional)',
                    padding: const EdgeInsets.all(14),
                    style: const TextStyle(color: Colors.white),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
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
