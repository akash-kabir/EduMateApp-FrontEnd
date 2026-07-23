import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../config.dart';
import '../../../services/shared_preferences_service.dart';
import '../../../services/token_refresh_service.dart';
import '../../../widgets/toast_manager.dart';
import '../../../widgets/custom_glass_dialog.dart';

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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 70, bottom: 30, left: 16, right: 16),
                      itemCount: 8,
                      itemBuilder: (context, index) {
                        final semester = index + 1;
                        final groups = _groupsBySemester[semester] ?? {};
                        return _buildSemesterCard(context, semester, groups, isDark);
                      },
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
                              'Electives',
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

  Widget _buildSemesterCard(
      BuildContext context, int semester, Map<String, List<dynamic>> groups, bool isDark) {
    final groupNames = groups.keys.toList();

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
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF303030), Color(0xFF1A1A1A)]
                : const [Color(0xFFFFFFFF), Color(0xFFF3F4F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Semester $semester',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${groups.length} ${groups.length == 1 ? 'Elective Group' : 'Elective Groups'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_canManageElectives)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'View Only',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: isDark ? Colors.white38 : Colors.black38,
                  size: 18,
                ),
              ],
            ),
            if (groupNames.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: groupNames.map((name) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.3 : 0.2),
                      ),
                    ),
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: isDark ? const Color(0xFF22D3EE) : const Color(0xFF0891B2),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
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
    final bool? confirm = await showDeleteConfirmationDialog(
      context: context,
      title: 'Delete Group?',
      description: 'Are you sure you want to delete the $groupName elective group?',
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

  void _showGroupDetailsDialog(String groupName, List<dynamic> electives, bool isDark) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF18181B).withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            groupName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Semester ${widget.semester} Elective Subjects',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: isDark ? Colors.white38 : Colors.black38,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SUBJECT / COURSE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: isDark ? Colors.white38 : Colors.black45,
                        ),
                      ),
                      Text(
                        'SECTIONS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: isDark ? Colors.white38 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (electives.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'No subjects available for $groupName',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: electives.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final elective = electives[index];
                          final subjectName = elective['name'] ?? 'Unknown Subject';

                          int sectionCount = 0;
                          if (elective['sections'] is List) {
                            sectionCount = (elective['sections'] as List).length;
                          } else if (elective['periods'] is List) {
                            sectionCount = (elective['periods'] as List).length;
                          } else if (elective['sectionCount'] != null) {
                            sectionCount = elective['sectionCount'];
                          } else {
                            sectionCount = 1;
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.04),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    subjectName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    '$sectionCount ${sectionCount == 1 ? 'Section' : 'Sections'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupCard(
      BuildContext context, String groupName, List<dynamic> electives, bool isDark) {
    final bool hasSubjects = electives.isNotEmpty;

    return GestureDetector(
      onTap: () => _showGroupDetailsDialog(groupName, electives, isDark),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF303030), Color(0xFF1A1A1A)]
                : const [Color(0xFFFFFFFF), Color(0xFFF3F4F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasSubjects
                      ? '${electives.length} ${electives.length == 1 ? 'subject' : 'subjects'}'
                      : 'No subjects',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: hasSubjects
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context: context,
                    icon: CupertinoIcons.arrow_up_doc_fill,
                    label: 'Upload JSON',
                    color: const Color(0xFF10B981), // Emerald Green
                    isDark: isDark,
                    onTap: () => _uploadToGroup(groupName),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    context: context,
                    icon: CupertinoIcons.trash_fill,
                    label: 'Delete Group',
                    color: const Color(0xFFDC2626), // Admin Red
                    isDark: isDark,
                    onTap: () => _deleteGroup(groupName),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.25 : 0.15),
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
