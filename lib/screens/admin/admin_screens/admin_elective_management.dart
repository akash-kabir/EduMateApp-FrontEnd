import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../../config.dart';
import '../../../widgets/toast_manager.dart';
import '../../../services/shared_preferences_service.dart';

class AdminElectiveManagementScreen extends StatefulWidget {
  const AdminElectiveManagementScreen({super.key});

  @override
  State<AdminElectiveManagementScreen> createState() => _AdminElectiveManagementScreenState();
}

class _AdminElectiveManagementScreenState extends State<AdminElectiveManagementScreen> {
  bool _isLoading = true;
  String _selectedBranch = 'CSE';
  final List<String> _branches = ['CSE', 'CSCE', 'IT', 'CSSE'];

  // Map of semester -> { 'groups': { groupName: [electives] }, 'raw': fullDoc }
  Map<int, Map<String, List<dynamic>>> _groupsBySemester = {};

  @override
  void initState() {
    super.initState();
    _fetchElectives();
  }

  Future<void> _fetchElectives() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${Config.electiveBaseEndpoint}/branch/$_selectedBranch?t=${DateTime.now().millisecondsSinceEpoch}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['data'] as List;

        final Map<int, Map<String, List<dynamic>>> parsed = {};
        for (var item in items) {
          final semester = item['semester'] as int;
          final electives = item['electives'] as List;
          final Map<String, List<dynamic>> groups = {};
          for (var e in electives) {
            final group = e['electiveGroup'] as String? ?? 'Unknown';
            groups.putIfAbsent(group, () => []).add(e);
          }
          parsed[semester] = groups;
        }

        setState(() {
          _groupsBySemester = parsed;
          _isLoading = false;
        });
      } else {
        setState(() {
          _groupsBySemester = {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(
          context,
          message: 'Failed to fetch electives: $e',
          isSuccess: false,
        );
      }
      setState(() => _isLoading = false);
    }
  }

  /// Picks a JSON file, asks which elective group it belongs to,
  /// transforms class-schedule format into elective format, then uploads.
  Future<void> _uploadElective(int semester) async {
    try {
      // 1. Pick JSON file
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null) return;

      final file = result.files.first;
      String jsonString;
      if (file.path != null) {
        jsonString = await File(file.path!).readAsString();
      } else {
        final bytes = await file.readAsBytes();
        jsonString = String.fromCharCodes(bytes);
      }

      final jsonData = jsonDecode(jsonString);

      // 2. Determine the format and build electives list
      List<Map<String, dynamic>> electivesList;

      if (jsonData.containsKey('electives') && jsonData['electives'] is List) {
        // ── Native elective format ──
        electivesList = List<Map<String, dynamic>>.from(jsonData['electives']);
      } else if (jsonData.containsKey('classes') && jsonData['classes'] is List) {
        // ── Class-schedule format → need to ask for group name and transform ──
        if (!mounted) return;

        final groupName = await _askGroupName();
        if (groupName == null || groupName.isEmpty) return;

        setState(() => _isLoading = true);

        final classes = jsonData['classes'] as List;
        electivesList = [];

        for (var cls in classes) {
          final name = cls['name'] as String? ?? 'Unknown';
          final schedule = cls['schedule'] as List? ?? [];

          // Flatten all periods from every day
          final List<Map<String, dynamic>> periods = [];
          for (var dayEntry in schedule) {
            final dayNum = dayEntry['day'];
            final dayPeriods = dayEntry['periods'] as List? ?? [];
            for (var p in dayPeriods) {
              periods.add({
                'day': dayNum,
                'startTime': p['startTime'] ?? '',
                'endTime': p['endTime'] ?? '',
                'room': p['room'] ?? '',
              });
            }
          }

          electivesList.add({
            'name': name,
            'electiveGroup': groupName,
            'periods': periods,
          });
        }
      } else {
        throw Exception('Invalid JSON: needs either "electives" or "classes" key');
      }

      if (electivesList.isEmpty) {
        throw Exception('No elective data found in file');
      }

      setState(() => _isLoading = true);

      final groupNames = electivesList.map((e) => e['electiveGroup'] ?? 'Unknown').toSet().toList();

      final token = await SharedPreferencesService.getToken();
      if (token == null) throw Exception('Authentication token not found');

      final url = Uri.parse('${Config.electiveBaseEndpoint}/$_selectedBranch/$semester');

      // Always POST — backend handles create-or-merge by group
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'electives': electivesList}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to upload: ${response.statusCode} - ${response.body}');
      }

      if (mounted) {
        EduMateToast.showSuccessCard(
          context,
          title: 'Uploaded',
          description: 'Semester $semester — ${groupNames.join(", ")}',
        );
      }
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(context, message: 'Upload error: $e', isSuccess: false);
      }
    } finally {
      _fetchElectives();
    }
  }

  /// Deletes a specific elective group for a semester using ?group= query param.
  Future<void> _deleteGroup(int semester, String groupName) async {
    // Confirm with the user
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Elective Group'),
        content: Text('Delete "$groupName" from Semester $semester?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);

      final token = await SharedPreferencesService.getToken();
      if (token == null) throw Exception('Authentication token not found');

      final url = Uri.parse(
        '${Config.electiveBaseEndpoint}/$_selectedBranch/$semester?group=${Uri.encodeComponent(groupName)}',
      );
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete: ${response.statusCode}');
      }

      if (mounted) {
        EduMateToast.showSuccessCard(
          context,
          title: 'Deleted',
          description: '"$groupName" removed from Semester $semester',
        );
      }
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(context, message: 'Delete error: $e', isSuccess: false);
      }
    } finally {
      _fetchElectives();
    }
  }

  /// Shows a dialog asking the admin to pick or type an elective group name.
  Future<String?> _askGroupName() async {
    String? selected;
    final controller = TextEditingController();
    final presets = ['PE-1', 'PE-2', 'K-Explore', 'OE-1', 'OE-2'];

    return showCupertinoDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return CupertinoAlertDialog(
              title: const Text('Elective Group Name'),
              content: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Select or type the elective group this file belongs to:',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presets.map((preset) {
                        final isSelected = selected == preset;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selected = preset;
                              controller.text = preset;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey5,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              preset,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? CupertinoColors.white : CupertinoColors.label,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    CupertinoTextField(
                      controller: controller,
                      placeholder: 'Or type custom name…',
                      onChanged: (val) {
                        setDialogState(() {
                          selected = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(ctx, null),
                ),
                CupertinoDialogAction(
                  child: const Text('Confirm'),
                  onPressed: () {
                    final name = controller.text.trim();
                    Navigator.pop(ctx, name.isNotEmpty ? name : null);
                  },
                ),
              ],
            );
          },
        );
      },
    );
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
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [const Color(0xFF0F0F12), Colors.black]
                      : [Colors.white, const Color(0xFFF2F2F7)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Icon(CupertinoIcons.back, color: isDark ? Colors.white : Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Elective Management',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Branch Selector ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Branch',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          _showItemPicker(
                            context: context,
                            title: 'Select Branch',
                            items: _branches,
                            selectedItem: _selectedBranch,
                            onSelected: (val) {
                              setState(() {
                                _selectedBranch = val;
                              });
                              _fetchElectives();
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedBranch,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16),
                              ),
                              Icon(CupertinoIcons.chevron_down, color: isDark ? Colors.white70 : Colors.black54, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Semester List ──
                Expanded(
                  child: _isLoading
                      ? const Center(child: CupertinoActivityIndicator())
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: 8,
                          itemBuilder: (context, index) {
                            final semester = index + 1;
                            return _buildSemesterCard(semester, isDark);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterCard(int semester, bool isDark) {
    final groups = _groupsBySemester[semester]; // Map<String, List>?
    final hasGroups = groups != null && groups.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Semester Header Row ──
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Semester $semester',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasGroups
                          ? '${groups.length} group${groups.length > 1 ? 's' : ''} uploaded'
                          : 'No electives uploaded',
                      style: TextStyle(
                        fontSize: 13,
                        color: hasGroups ? CupertinoColors.activeGreen : CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
              // Upload / Add Group button
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                color: CupertinoColors.activeBlue,
                borderRadius: BorderRadius.circular(12),
                onPressed: () => _uploadElective(semester),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.add, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      hasGroups ? 'Add Group' : 'Upload',
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // ── Group Chips ──
          if (hasGroups) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: groups.entries.map((entry) {
                final groupName = entry.key;
                final electiveCount = entry.value.length;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.book,
                        size: 14,
                        color: isDark ? CupertinoColors.activeOrange : CupertinoColors.activeBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$groupName ($electiveCount)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Re-upload / update this group
                      GestureDetector(
                        onTap: () => _uploadElective(semester),
                        child: Icon(
                          CupertinoIcons.arrow_up_doc,
                          size: 15,
                          color: isDark ? CupertinoColors.activeOrange : CupertinoColors.activeBlue,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Delete this group
                      GestureDetector(
                        onTap: () => _deleteGroup(semester, groupName),
                        child: const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          size: 16,
                          color: CupertinoColors.destructiveRed,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _showItemPicker({
    required BuildContext context,
    required String title,
    required List<String> items,
    required String selectedItem,
    required ValueChanged<String> onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int tempIndex = items.indexOf(selectedItem);
    if (tempIndex == -1) tempIndex = 0;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 280,
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                color: isDark ? Colors.black12 : Colors.grey[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16, decoration: TextDecoration.none)),
                    CupertinoButton(
                      child: const Text('Done', style: TextStyle(color: CupertinoColors.activeOrange, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        onSelected(items[tempIndex]);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 36.0,
                  scrollController: FixedExtentScrollController(initialItem: tempIndex),
                  onSelectedItemChanged: (index) {
                    tempIndex = index;
                  },
                  children: items.map((item) => Center(child: Text(item, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, decoration: TextDecoration.none)))).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
