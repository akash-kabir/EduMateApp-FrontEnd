import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../config.dart';
import '../../../services/shared_preferences_service.dart';
import '../../../services/token_refresh_service.dart';
import '../../../widgets/toast_manager.dart';

class AdminElectiveManagementScreen extends StatefulWidget {
  const AdminElectiveManagementScreen({super.key});

  @override
  State<AdminElectiveManagementScreen> createState() =>
      _AdminElectiveManagementScreenState();
}

class _AdminElectiveManagementScreenState
    extends State<AdminElectiveManagementScreen> {
  bool _isLoading = true;
  String? _currentUserRole;
  Map<int, Map<String, List<dynamic>>> _groupsBySemester = {};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  bool get _canManageElectives {
    final role = (_currentUserRole ?? '').toLowerCase();
    return role == 'admin' || role == 'contributor' || role == 'contributer';
  }

  Future<void> _bootstrap() async {
    await _loadCurrentRole();
    await _fetchAllElectives();
  }

  Future<void> _loadCurrentRole() async {
    final role = await SharedPreferencesService.getUserRole();
    if (mounted) {
      setState(() {
        _currentUserRole = role;
      });
    }
  }

  Future<void> _fetchAllElectives() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uri = Uri.parse('${Config.electiveBaseEndpoint}/?t=$timestamp');
      final response = await TokenRefreshService.authenticatedGet(uri.toString());

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == true && resData['data'] != null) {
          final List<dynamic> data = resData['data'];
          final Map<int, Map<String, List<dynamic>>> grouped = {};

          for (var doc in data) {
            final int semester = doc['semester'] ?? 1;
            final List<dynamic> electives = doc['electives'] ?? [];
            
            final Map<String, List<dynamic>> semGroups = {};
            for (var elective in electives) {
              final groupName = elective['electiveGroup'] as String? ?? 'Unknown';
              semGroups.putIfAbsent(groupName, () => []).add(elective);
            }
            grouped[semester] = semGroups;
          }

          if (mounted) {
            setState(() {
              _groupsBySemester = grouped;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching all electives: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: CupertinoPageScaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F11) : const Color(0xFFFAFAFA),
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Elective Management'),
          backgroundColor: isDark
              ? const Color(0xFF0F0F11).withOpacity(0.8)
              : Colors.white.withOpacity(0.8),
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.white12 : Colors.black12,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    final semester = index + 1;
                    final groups = _groupsBySemester[semester] ?? {};
                    return _buildSemesterCard(context, semester, groups, isDark);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildSemesterCard(
      BuildContext context, int semester, Map<String, List<dynamic>> groups, bool isDark) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => _SemesterElectiveDetailScreen(
              semester: semester,
              canManage: _canManageElectives,
            ),
          ),
        );
        // Refresh when coming back
        _fetchAllElectives();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$semester',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Semester $semester',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${groups.length} Elective Groups',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (!_canManageElectives)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'View Only',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _SemesterElectiveDetailScreen extends StatefulWidget {
  final int semester;
  final bool canManage;

  const _SemesterElectiveDetailScreen({
    required this.semester,
    required this.canManage,
  });

  @override
  State<_SemesterElectiveDetailScreen> createState() =>
      _SemesterElectiveDetailScreenState();
}

class _SemesterElectiveDetailScreenState
    extends State<_SemesterElectiveDetailScreen> {
  bool _isLoading = true;
  Map<String, List<dynamic>> _groups = {};

  @override
  void initState() {
    super.initState();
    _fetchSemesterElectives();
  }

  Future<void> _fetchSemesterElectives() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uri = Uri.parse(
          '${Config.electiveBaseEndpoint}/${widget.semester}?t=$timestamp');
      final response = await TokenRefreshService.authenticatedGet(uri.toString());

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == true && resData['data'] != null) {
          final electivesList = resData['data']['electives'] as List? ?? [];
          final Map<String, List<dynamic>> grouped = {};

          for (var item in electivesList) {
            final groupName = item['electiveGroup'] as String? ?? 'Unknown';
            grouped.putIfAbsent(groupName, () => []).add(item);
          }

          if (mounted) {
            setState(() {
              _groups = grouped;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _groups = {};
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching semester electives: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAddGroupBottomSheet(BuildContext context, bool isDark) {
    final TextEditingController customGroupController = TextEditingController();
    final presets = ['PE-1', 'PE-2', 'K-Explore', 'OE-1', 'OE-2'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E20) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Elective Group',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Select a preset:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: presets.map((preset) {
                    return ActionChip(
                      label: Text(preset),
                      onPressed: () {
                        Navigator.pop(context);
                        _addGroupLocally(preset);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text('Or enter custom group name:'),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: customGroupController,
                  placeholder: 'e.g., DE-1',
                  padding: const EdgeInsets.all(12),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    child: const Text('Add Group'),
                    onPressed: () {
                      final name = customGroupController.text.trim();
                      if (name.isNotEmpty) {
                        Navigator.pop(context);
                        _addGroupLocally(name);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addGroupLocally(String groupName) {
    if (_groups.containsKey(groupName)) {
      EduMateToast.showCompact(
        context,
        message: 'Group $groupName already exists',
        isSuccess: false,
      );
      return;
    }
    setState(() {
      _groups[groupName] = [];
    });
  }

  Future<void> _uploadToGroup(String groupName) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        setState(() {
          _isLoading = true;
        });

        final file = File(result.files.single.path!);
        final contents = await file.readAsString();
        final jsonData = jsonDecode(contents);

        List<dynamic> electivesToUpload = [];

        if (jsonData is List) {
          // Format 3: Direct array of electives
          for (var e in jsonData) {
            if (e is Map) {
              e['electiveGroup'] = groupName;
              electivesToUpload.add(e);
            }
          }
        } else if (jsonData is Map) {
          // Parse format 1: direct electives array
          if (jsonData.containsKey('electives') && jsonData['electives'] is List) {
            for (var e in jsonData['electives']) {
              if (e is Map) {
                e['electiveGroup'] = groupName;
                electivesToUpload.add(e);
              }
            }
          }
          // Parse format 2: classes with schedule array
          else if (jsonData.containsKey('classes') && jsonData['classes'] is List) {
            for (var c in jsonData['classes']) {
              if (c is Map) {
                electivesToUpload.add({
                  'name': c['name'] ?? 'Unknown',
                  'electiveGroup': groupName,
                  'periods': c['schedule'] is List ? (c['schedule'] as List).expand((dayData) {
                    if (dayData is Map && dayData['periods'] is List) {
                      return (dayData['periods'] as List).map((p) => {
                        'day': dayData['day'],
                        'startTime': p['startTime'],
                        'endTime': p['endTime'],
                        'room': p['room'] ?? '',
                      });
                    }
                    return [];
                  }).toList() : [],
                });
              }
            }
          } else {
             throw Exception('Invalid JSON format. Expected array, or object with "electives" or "classes" key.');
          }
        } else {
           throw Exception('Invalid JSON format.');
        }

        if (electivesToUpload.isEmpty) {
          throw Exception('No electives found in file.');
        }

        // Post to backend
        final uri = Uri.parse('${Config.electiveBaseEndpoint}/${widget.semester}');
        final response = await TokenRefreshService.authenticatedPost(
          uri.toString(),
          body: {'electives': electivesToUpload},
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (!mounted) return;
          EduMateToast.showCompact(
            context,
            message: 'Uploaded ${electivesToUpload.length} electives to $groupName',
            isSuccess: true,
          );
          await _fetchSemesterElectives(); // Refresh data
        } else {
          throw Exception('Backend returned ${response.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        EduMateToast.showCompact(
          context,
          message: 'Upload failed: $e',
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _deleteGroup(String groupName) async {
    final bool? confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Group?'),
        content: Text('Are you sure you want to delete the $groupName elective group?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final uri = Uri.parse(
          '${Config.electiveBaseEndpoint}/${widget.semester}?group=${Uri.encodeComponent(groupName)}');
      final response = await TokenRefreshService.authenticatedDelete(uri.toString());

      if (response.statusCode == 200) {
        if (!mounted) return;
        EduMateToast.showCompact(
          context,
          message: 'Group $groupName deleted',
          isSuccess: true,
        );
        setState(() {
          _groups.remove(groupName);
        });
      } else {
        throw Exception('Backend returned ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      EduMateToast.showCompact(
        context,
        message: 'Delete failed: $e',
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: CupertinoPageScaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F11) : const Color(0xFFFAFAFA),
        navigationBar: CupertinoNavigationBar(
          middle: Text('Semester ${widget.semester} Electives'),
          backgroundColor: isDark
              ? const Color(0xFF0F0F11).withOpacity(0.8)
              : Colors.white.withOpacity(0.8),
          trailing: widget.canManage
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.add),
                  onPressed: () => _showAddGroupBottomSheet(context, isDark),
                )
              : null,
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : _groups.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.doc_text_search, size: 64, color: Colors.grey.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'No elective groups yet',
                            style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          if (widget.canManage)
                            CupertinoButton.filled(
                              child: const Text('Add Group'),
                              onPressed: () => _showAddGroupBottomSheet(context, isDark),
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _groups.length,
                      itemBuilder: (context, index) {
                        final groupName = _groups.keys.elementAt(index);
                        final electives = _groups[groupName]!;
                        return _buildGroupCard(context, groupName, electives, isDark);
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(
      BuildContext context, String groupName, List<dynamic> electives, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(CupertinoIcons.square_stack_3d_up, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${electives.length} subjects',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.canManage) ...[
                  IconButton(
                    icon: const Icon(CupertinoIcons.cloud_upload),
                    onPressed: () => _uploadToGroup(groupName),
                    tooltip: 'Upload JSON',
                    color: CupertinoColors.activeBlue,
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.delete),
                    onPressed: () => _deleteGroup(groupName),
                    tooltip: 'Delete Group',
                    color: CupertinoColors.destructiveRed,
                  ),
                ],
              ],
            ),
          ),
          if (electives.isNotEmpty) ...[
            Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: electives.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 16,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              itemBuilder: (context, index) {
                final elective = electives[index];
                final periods = elective['periods'] as List? ?? [];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          elective['name'] ?? 'Unknown Subject',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${periods.length} periods',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
