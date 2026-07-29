import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:app/shared/config.dart';
import 'package:app/shared/services/shared_preferences_service.dart';
import 'package:app/features/auth_and_profile/services/token_refresh_service.dart';
import 'package:app/shared/widgets/dialogs/toast_manager.dart';
import 'package:app/features/admin/curriculum/curriculum_editor_screen.dart';

class BranchCurriculumInfo {
  final String branch;
  final Map<int, SemesterInfo> semesters;
  final DateTime? lastUpdated;

  BranchCurriculumInfo({
    required this.branch,
    required this.semesters,
    this.lastUpdated,
  });

  int get uploadedSemestersCount =>
      semesters.values.where((s) => s.hasData).length;
}

class SemesterInfo {
  final int semesterNumber;
  final bool hasData;
  final int subjectCount;
  final DateTime? updatedAt;

  SemesterInfo({
    required this.semesterNumber,
    required this.hasData,
    required this.subjectCount,
    this.updatedAt,
  });
}

class CurriculumManagementScreen extends StatefulWidget {
  const CurriculumManagementScreen({super.key});

  @override
  State<CurriculumManagementScreen> createState() =>
      _CurriculumManagementScreenState();
}

class _CurriculumManagementScreenState
    extends State<CurriculumManagementScreen> {
  bool _isLoading = true;
  String? _currentUserRole;
  List<String> _branches = [];
  Map<String, BranchCurriculumInfo> _branchDataMap = {};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  bool get _canManageCurriculum {
    final role = (_currentUserRole ?? '').toLowerCase();
    return role == 'admin' || role == 'contributor' || role == 'contributer';
  }

  Future<void> _bootstrap() async {
    await _loadCurrentRole();
    await _fetchAllBranches();
  }

  Future<void> _loadCurrentRole() async {
    final role = await SharedPreferencesService.getUserRole();
    if (mounted) {
      setState(() {
        _currentUserRole = role;
      });
    }
  }

  Future<void> _fetchAllBranches() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uri = Uri.parse('${Config.curriculumBaseEndpoint}/?t=$timestamp');

      final response = await TokenRefreshService.authenticatedGet(
        uri.toString(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> curriculums = data['data'] ?? [];

        List<String> uniqueBranches = [];
        Map<String, Map<int, SemesterInfo>> branchSemMap = {};
        Map<String, DateTime?> branchLastUpdateMap = {};

        for (var c in curriculums) {
          final String branch = (c['branch'] ?? '').toString().toUpperCase();
          if (branch.isEmpty) continue;
          if (!uniqueBranches.contains(branch)) {
            uniqueBranches.add(branch);
          }

          final int sem = c['semester'] is int
              ? c['semester']
              : int.tryParse(c['semester']?.toString() ?? '') ?? 0;
          final List<dynamic> subjects =
              c['subjects'] is List ? c['subjects'] : [];

          DateTime? updatedAt;
          if (c['updatedAt'] != null) {
            updatedAt = DateTime.tryParse(c['updatedAt'].toString());
          } else if (c['uploadedAt'] != null) {
            updatedAt = DateTime.tryParse(c['uploadedAt'].toString());
          } else if (c['createdAt'] != null) {
            updatedAt = DateTime.tryParse(c['createdAt'].toString());
          }

          branchSemMap.putIfAbsent(branch, () => {});
          if (sem >= 1 && sem <= 8) {
            branchSemMap[branch]![sem] = SemesterInfo(
              semesterNumber: sem,
              hasData: subjects.isNotEmpty,
              subjectCount: subjects.length,
              updatedAt: updatedAt,
            );
          }

          if (updatedAt != null) {
            final currentLast = branchLastUpdateMap[branch];
            if (currentLast == null || updatedAt.isAfter(currentLast)) {
              branchLastUpdateMap[branch] = updatedAt;
            }
          }
        }

        Map<String, BranchCurriculumInfo> newBranchDataMap = {};
        for (var b in uniqueBranches) {
          final semMap = branchSemMap[b] ?? {};
          Map<int, SemesterInfo> fullSemMap = {};
          for (int i = 1; i <= 8; i++) {
            fullSemMap[i] = semMap[i] ??
                SemesterInfo(
                  semesterNumber: i,
                  hasData: false,
                  subjectCount: 0,
                );
          }
          newBranchDataMap[b] = BranchCurriculumInfo(
            branch: b,
            semesters: fullSemMap,
            lastUpdated: branchLastUpdateMap[b],
          );
        }

        if (mounted) {
          setState(() {
            _branches = uniqueBranches;
            _branchDataMap = newBranchDataMap;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          EduMateToast.showCompact(
            context,
            message: 'Failed to load branches',
            isSuccess: false,
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(
          context,
          message: 'Error connecting to server',
          isSuccess: false,
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAddBranchDialog() {
    final TextEditingController branchController = TextEditingController();


    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF141416).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Add New Branch',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Salena',
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter branch code (e.g. CSE, ECE, MECH) to setup curriculum.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: branchController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. CSE',
                        hintStyle: TextStyle(
                          color: Colors.white30,
                          fontSize: 15,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF000000),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: Color(0xFF10B981), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              final name =
                                  branchController.text.trim().toUpperCase();
                              if (name.isNotEmpty) {
                                Navigator.pop(context);
                                _addBranchLocally(name);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'Add Branch',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _addBranchLocally(String branchName) {
    if (_branches.contains(branchName)) {
      EduMateToast.showCompact(
        context,
        message: 'Branch $branchName already exists',
        isSuccess: false,
      );
      return;
    }
    setState(() {
      _branches.add(branchName);
      Map<int, SemesterInfo> fullSemMap = {};
      for (int i = 1; i <= 8; i++) {
        fullSemMap[i] = SemesterInfo(
          semesterNumber: i,
          hasData: false,
          subjectCount: 0,
        );
      }
      _branchDataMap[branchName] = BranchCurriculumInfo(
        branch: branchName,
        semesters: fullSemMap,
      );
    });
  }

  Future<void> _uploadCurriculum(String branchName) async {
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

        List<dynamic> semestersData = [];

        if (jsonData is Map && jsonData.containsKey('semesters')) {
          semestersData = jsonData['semesters'];
        } else if (jsonData is List) {
          semestersData = jsonData;
        } else if (jsonData is Map && jsonData.containsKey('subjects')) {
          semestersData = [jsonData];
        } else {
          throw Exception('Invalid JSON format. Expected { semesters: [...] }');
        }

        int successCount = 0;

        for (var semData in semestersData) {
          int semesterNumber =
              semData['semesterNumber'] ?? semData['semester'] ?? 1;
          List<dynamic> subjectsToUpload = semData['subjects'] ?? [];

          final mappedSubjects = subjectsToUpload.map((s) {
            String type = s['type'] ?? 'Core';
            if (type == 'Theory') type = 'Core';
            if (![
              'Core',
              'Elective',
              'Lab',
              'Project',
              'Practical',
              'Open Elective',
              'Viva'
            ].contains(type)) {
              type = 'Core';
            }

            return {
              'name': s['name'] ?? 'Unknown',
              'code': s['shortName'] ?? s['code'] ?? 'SUB',
              'credits': s['credits'] ?? 3,
              'type': type,
            };
          }).toList();

          final payload = {
            'subjects': mappedSubjects,
          };

          final postResponse = await TokenRefreshService.authenticatedPost(
            '${Config.curriculumBaseEndpoint}/$branchName/$semesterNumber',
            body: payload,
          );

          if (postResponse.statusCode == 400 &&
              postResponse.body.contains('already exists')) {
            final putResponse = await TokenRefreshService.authenticatedPut(
              '${Config.curriculumBaseEndpoint}/$branchName/$semesterNumber',
              body: payload,
            );
            if (putResponse.statusCode == 200 ||
                putResponse.statusCode == 201) {
              successCount++;
            }
          } else if (postResponse.statusCode == 200 ||
              postResponse.statusCode == 201) {
            successCount++;
          }
        }

        if (mounted) {
          EduMateToast.showCompact(
            context,
            message: 'Successfully updated $successCount semester(s)!',
            isSuccess: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
          isSuccess: false,
        );
      }
    } finally {
      _fetchAllBranches();
    }
  }

  Future<void> _deleteCurriculum(String branchName) async {


    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF141416).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.trash_circle_fill,
                          color: Color(0xFFDC2626), size: 36),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Delete $branchName',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Salena',
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Are you sure you want to permanently delete all 8 semesters of curriculum for $branchName? This action cannot be undone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFDC2626)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'Delete All',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        for (int i = 1; i <= 8; i++) {
          await TokenRefreshService.authenticatedDelete(
            '${Config.curriculumBaseEndpoint}/$branchName/$i',
          );
        }

        if (mounted) {
          EduMateToast.showCompact(
            context,
            message: 'Branch curriculum deleted successfully',
            isSuccess: true,
          );
        }
      } catch (e) {
        if (mounted) {
          EduMateToast.showCompact(
            context,
            message: 'Error deleting some semesters',
            isSuccess: false,
          );
        }
      } finally {
        _fetchAllBranches();
      }
    }
  }

  void _editCurriculum(String branchName, {int semester = 1}) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => CurriculumEditorScreen(
          branch: branchName,
          semester: semester,
        ),
      ),
    ).then((_) {
      _fetchAllBranches();
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;
    return '$day $month $year';
  }

  void _showBranchDetailsDialog(String branch) {
    final info = _branchDataMap[branch];


    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        return Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Text(
                          '$branch Curriculum Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.calendar,
                              size: 14,
                              color: Colors.white54,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              info?.lastUpdated != null
                                  ? 'Uploaded on ${_formatDate(info!.lastUpdated)}'
                                  : 'No upload date recorded',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: Colors.white12,
                  ),

                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      itemCount: 8,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                      itemBuilder: (context, index) {
                        final semNum = index + 1;
                        final semInfo = info?.semesters[semNum];
                        final bool hasData = semInfo?.hasData ?? false;
                        final int subjectCount = semInfo?.subjectCount ?? 0;

                        return InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            _editCurriculum(branch, semester: semNum);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Sem $semNum',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      hasData
                                          ? '$subjectCount subjects'
                                          : 'No subjects',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white38,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      hasData
                                          ? CupertinoIcons.checkmark_circle_fill
                                          : CupertinoIcons.xmark_circle_fill,
                                      size: 20,
                                      color: hasData
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFDC2626),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      CupertinoIcons.chevron_right,
                                      size: 14,
                                      color: Colors.white24,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: const Color(0xFF2C2C2E),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        borderRadius: BorderRadius.circular(12),
                        child: Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
              child: _isLoading
                  ? _buildSkeletonList()
                  : _branches.isEmpty
                      ? Center(
                          child: Text(
                            'No branch curriculums found.\nTap + to add a branch.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                              top: 70, bottom: 30, left: 16, right: 16),
                          itemCount: _branches.length,
                          itemBuilder: (context, index) {
                            return _buildBranchCard(_branches[index]);
                          },
                        ),
            ),
          ),
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
                          color: Colors.white.withValues(alpha: 0.1)),
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
                              child: Icon(CupertinoIcons.back,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              'Curriculum',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Salena',
                                fontSize: 17,
                              ),
                            ),
                          ),
                          if (_canManageCurriculum)
                            Align(
                              alignment: Alignment.centerRight,
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: _showAddBranchDialog,
                                child: Icon(CupertinoIcons.add,
                                        color: Colors.white),
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

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 70, bottom: 30, left: 16, right: 16),
      itemCount: 4,
      itemBuilder: (context, index) => const _BranchSkeletonCard(),
    );
  }

  Widget _buildBranchCard(String branch) {
    final info = _branchDataMap[branch];
    final uploadedCount = info?.uploadedSemestersCount ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: const [Color(0xFF303030), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showBranchDetailsDialog(branch),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            branch,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            uploadedCount > 0
                                ? '$uploadedCount of 8 Semesters Available'
                                : 'No semesters uploaded',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 16,
                      color: Colors.white30,
                    ),
                  ],
                ),

                if (_canManageCurriculum) ...[
                  const SizedBox(height: 16),
                  // Action Row 1: Upload JSON (Full Width)
                  SizedBox(
                    width: double.infinity,
                    child: _buildActionButton(
                      context: context,
                      icon: CupertinoIcons.arrow_up_doc_fill,
                      label: 'Upload JSON',
                      color: const Color(0xFF10B981), // Emerald Green
                      onTap: () => _uploadCurriculum(branch),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Action Row 2: Edit and Delete (Side by side equal width)
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          context: context,
                          icon: CupertinoIcons.pencil_circle_fill,
                          label: 'Edit',
                          color: const Color(0xFFF59E0B), // Amber
                          onTap: () => _editCurriculum(branch),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          context: context,
                          icon: CupertinoIcons.trash_fill,
                          label: 'Delete',
                          color: const Color(0xFFDC2626), // Admin Red
                          onTap: () => _deleteCurriculum(branch),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
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

class _BranchSkeletonCard extends StatefulWidget {
  const _BranchSkeletonCard();

  @override
  State<_BranchSkeletonCard> createState() => _BranchSkeletonCardState();
}

class _BranchSkeletonCardState extends State<_BranchSkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = const Color(0xFF000000);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141416),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 18,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 150,
                          height: 12,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: baseColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 36,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: baseColor,
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
      },
    );
  }
}