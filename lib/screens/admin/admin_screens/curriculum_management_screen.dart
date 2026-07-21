import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../config.dart';
import '../../../services/shared_preferences_service.dart';
import '../../../services/token_refresh_service.dart';
import '../../../widgets/toast_manager.dart';
import 'curriculum_editor_screen.dart';

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
        for (var c in curriculums) {
          final String branch = (c['branch'] ?? '').toString().toUpperCase();
          if (branch.isNotEmpty && !uniqueBranches.contains(branch)) {
            uniqueBranches.add(branch);
          }
        }

        if (mounted) {
          setState(() {
            _branches = uniqueBranches;
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

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Add Branch Curriculum'),
          content: Column(
            children: [
              const SizedBox(height: 8),
              const Text('Enter the branch name (e.g. CSE, ECE)'),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: branchController,
                placeholder: 'Branch Name',
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Add'),
              onPressed: () {
                final name = branchController.text.trim().toUpperCase();
                if (name.isNotEmpty) {
                  Navigator.pop(context);
                  _addBranchLocally(name);
                }
              },
            ),
          ],
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

        // Check if it's the 8-semester format: { "semesters": [ { "semesterNumber": 1, "subjects": [] }, ... ] }
        if (jsonData is Map && jsonData.containsKey('semesters')) {
          semestersData = jsonData['semesters'];
        } else if (jsonData is List) {
           // Also allow an array of semesters directly
           semestersData = jsonData;
        } else if (jsonData is Map && jsonData.containsKey('subjects')) {
            // A single semester was uploaded
             semestersData = [jsonData];
        }
        else {
          throw Exception('Invalid JSON format. Expected { semesters: [...] }');
        }

        int successCount = 0;

        for (var semData in semestersData) {
          int semesterNumber = semData['semesterNumber'] ?? semData['semester'] ?? 1;
          List<dynamic> subjectsToUpload = semData['subjects'] ?? [];

          // Map the subjects to match backend schema
          final mappedSubjects = subjectsToUpload.map((s) {
            String type = s['type'] ?? 'Core';
            if (type == 'Theory') type = 'Core';
            if (!['Core', 'Elective', 'Lab', 'Project', 'Practical', 'Open Elective', 'Viva'].contains(type)) {
              type = 'Core'; // Fallback
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

          if (postResponse.statusCode == 400 && postResponse.body.contains('already exists')) {
            final putResponse = await TokenRefreshService.authenticatedPut(
              '${Config.curriculumBaseEndpoint}/$branchName/$semesterNumber',
              body: payload,
            );
            if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
              successCount++;
            }
          } else if (postResponse.statusCode == 200 || postResponse.statusCode == 201) {
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
    final bool? confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Curriculum'),
        content: Text('Are you sure you want to delete ALL 8 semesters of the curriculum for $branchName?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
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

  void _editCurriculum(String branchName) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => CurriculumEditorScreen(
          branch: branchName,
        ),
      ),
    ).then((_) {
      _fetchAllBranches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? CupertinoColors.black : const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back,
              color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Curriculum Management',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_canManageCurriculum)
            IconButton(
              icon: Icon(CupertinoIcons.add,
                  color: isDark ? Colors.white : Colors.black),
              onPressed: _showAddBranchDialog,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white12 : Colors.black12,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : _branches.isEmpty
                  ? Center(
                      child: Text(
                        'No branch curriculums found.\nTap + to add a branch.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _branches.length,
                      itemBuilder: (context, index) {
                        return _buildBranchCard(_branches[index], isDark);
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildBranchCard(String branch, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepPurple.withValues(alpha: 0.8),
                            Colors.purpleAccent.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.book_solid,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      branch,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_canManageCurriculum)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(CupertinoIcons.cloud_upload),
                        color: Colors.deepPurple,
                        tooltip: 'Upload Bulk JSON',
                        onPressed: () => _uploadCurriculum(branch),
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.pencil),
                        color: Colors.orange,
                        tooltip: 'Edit Manually',
                        onPressed: () => _editCurriculum(branch),
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.delete),
                        color: Colors.red,
                        tooltip: 'Delete Branch Curriculum',
                        onPressed: () => _deleteCurriculum(branch),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}