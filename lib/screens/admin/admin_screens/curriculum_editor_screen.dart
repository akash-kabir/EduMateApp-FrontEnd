import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../widgets/custom_glass_dialog.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config.dart';
import '../../../widgets/toast_manager.dart';
import '../../../widgets/bottom_sheet_selector.dart';
import '../../../services/shared_preferences_service.dart';

class CurriculumEditorScreen extends StatefulWidget {
  final String branch;
  final int semester;

  const CurriculumEditorScreen({
    super.key,
    required this.branch,
    required this.semester,
  });

  @override
  State<CurriculumEditorScreen> createState() => _CurriculumEditorScreenState();
}

class _CurriculumEditorScreenState extends State<CurriculumEditorScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _subjects = [];
  bool _isExisting = false;
  String? _originalSubjectsData;

  final List<String> _subjectTypes = ['Core', 'Elective', 'Lab', 'Project', 'Practical', 'Open Elective', 'Viva'];

  @override
  void initState() {
    super.initState();
    _fetchCurriculum();
  }

  Future<void> _fetchCurriculum() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${Config.curriculumBaseEndpoint}/${widget.branch}/${widget.semester}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          _isExisting = true;
          _subjects = List<Map<String, dynamic>>.from(data['subjects'].map((s) => {
            'code': s['code'],
            'name': s['name'],
            'credits': s['credits'],
            'type': s['type'],
          }));
          _originalSubjectsData = jsonEncode(_subjects);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isExisting = false;
          _subjects = [];
          _originalSubjectsData = jsonEncode([]);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(
          context,
          message: 'Failed to fetch curriculum: $e',
          isSuccess: false,
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCurriculum() async {
    // Validation
    for (var subject in _subjects) {
      if (subject['code'] == null || subject['code'].toString().trim().isEmpty) {
        EduMateToast.showCompact(context, message: 'Subject code cannot be empty.', isSuccess: false);
        return;
      }
      if (subject['name'] == null || subject['name'].toString().trim().isEmpty) {
        EduMateToast.showCompact(context, message: 'Subject name cannot be empty.', isSuccess: false);
        return;
      }
      if (subject['credits'] == null) {
        EduMateToast.showCompact(context, message: 'Credits must be assigned.', isSuccess: false);
        return;
      }
    }

    if (jsonEncode(_subjects) == _originalSubjectsData) {
      EduMateToast.showCompact(context, message: 'No changes made.', isSuccess: true);
      return;
    }

    _showSaveConfirmDialog();
  }

  void _showSaveConfirmDialog() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Save Changes',
      description: 'Are you sure you want to save the curriculum changes for ${widget.branch} Semester ${widget.semester}?',
      confirmButtonText: 'Save',
      iconData: CupertinoIcons.checkmark_seal_fill,
    );
    if (confirmed == true) {
      _performSave();
    }
  }

  Future<void> _performSave() async {
    setState(() => _isSaving = true);
    try {
      final token = await SharedPreferencesService.getToken();
      final url = Uri.parse('${Config.curriculumBaseEndpoint}/${widget.branch}/${widget.semester}');
      
      final payload = jsonEncode({
        'subjects': _subjects
      });

      http.Response response;
      if (_isExisting) {
        response = await http.put(
          url,
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: payload,
        );
      } else {
        response = await http.post(
          url,
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: payload,
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          EduMateToast.showCompact(context, message: 'Curriculum saved successfully.', isSuccess: true);
          Navigator.pop(context);
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to save');
      }
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(
          context,
          message: 'Failed to save: $e',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _addSubject() {
    setState(() {
      _subjects.add({
        'code': '',
        'name': '',
        'credits': 3,
        'type': 'Theory',
      });
    });
    EduMateToast.showCompact(context, message: 'New subject added.', isSuccess: true);
  }

  void _removeSubject(int index) {
    setState(() {
      _subjects.removeAt(index);
    });
    EduMateToast.showCompact(context, message: 'Subject deleted.', isSuccess: true);
  }

  Widget _buildSummaryItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : Stack(
              children: [
                Positioned.fill(
                  child: _subjects.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 150),
                          child: Center(
                            child: Text(
                              'No subjects added yet.',
                              style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600]),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 160, bottom: 120, left: 16, right: 16),
                          itemCount: _subjects.length,
                          itemBuilder: (context, index) {
                            final subject = _subjects[index];
                            return _SubjectEditCard(
                              key: ObjectKey(subject),
                              subject: subject,
                              subjectTypes: _subjectTypes,
                              isDark: isDark,
                              onChanged: () => setState(() {}),
                              onRemove: () => _removeSubject(index),
                            );
                          },
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
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
                                        'Edit Curriculum',
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Salena',
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    if (!_isLoading)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: TextButton(
                                            onPressed: _isSaving ? null : _saveCurriculum,
                                            child: _isSaving
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF1744)),
                                                  )
                                                : const Text(
                                                    'Save',
                                                    style: TextStyle(
                                                      color: Color(0xFFFF1744),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildSummaryItem('Branch', widget.branch, isDark),
                                    _buildSummaryItem('Semester', '${widget.semester}', isDark),
                                    _buildSummaryItem('Subjects', '${_subjects.length}', isDark),
                                    _buildSummaryItem('Credits', '${_subjects.fold(0, (sum, sub) => sum + ((sub['credits'] as int?) ?? 0))}', isDark),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(21),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF141414).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(21),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _addSubject,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Subject'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: isDark ? Colors.white : Colors.black,
                                minimumSize: const Size(double.infinity, 55),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
                              ),
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

class _SubjectEditCard extends StatefulWidget {
  final Map<String, dynamic> subject;
  final List<String> subjectTypes;
  final bool isDark;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _SubjectEditCard({
    super.key,
    required this.subject,
    required this.subjectTypes,
    required this.isDark,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_SubjectEditCard> createState() => _SubjectEditCardState();
}

class _SubjectEditCardState extends State<_SubjectEditCard> {

  void _confirmDelete(BuildContext context) async {
    final confirmed = await showDeleteConfirmationDialog(
      context: context,
      title: 'Delete Subject',
      description: 'Are you sure you want to delete ${widget.subject['name']?.toString().isNotEmpty == true ? "'${widget.subject['name']}'" : 'this subject'}? This action cannot be undone.',
    );
    if (confirmed == true) {
      widget.onRemove();
    }
  }

  void _showEditDialog(BuildContext context) {
    String tempName = widget.subject['name'] ?? '';
    String tempCode = widget.subject['code'] ?? '';
    int tempCredits = widget.subject['credits'] ?? 0;
    String tempType = widget.subject['type'] ?? 'Theory';

    showGlassmorphicDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Edit Subject',
      widthFactor: 0.9,
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Edit Subject',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              initialValue: tempName,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
                              decoration: _buildInputDecoration('Subject Name'),
                              onChanged: (val) => tempName = val,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    initialValue: tempCode,
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
                                    decoration: _buildInputDecoration('Code'),
                                    onChanged: (val) => tempCode = val,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    initialValue: tempCredits.toString(),
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
                                    decoration: _buildInputDecoration('Credits'),
                                    onChanged: (val) => tempCredits = int.tryParse(val) ?? 0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: BottomSheetSelector<String>(
                                value: tempType,
                                items: const ['Theory', 'Practical', 'Sessional'],
                                hint: 'Select Type',
                                isAdmin: true,
                                labelBuilder: (String val) => val,
                                onChanged: (val) {
                                  setDialogState(() {
                                    tempType = val;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isDark ? Colors.white : Colors.black,
                                      side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      widget.subject['name'] = tempName;
                                      widget.subject['code'] = tempCode;
                                      widget.subject['credits'] = tempCredits;
                                      widget.subject['type'] = tempType;
                                      widget.onChanged();
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF1744),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Save',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
          );
        }
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: widget.isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 13),
      filled: true,
      fillColor: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: const Color(0xFFFF1744).withValues(alpha: 0.5), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.subject['name']?.toString().trim().isNotEmpty == true 
        ? widget.subject['name'] 
        : 'New Subject';
    final String subtitle = '${widget.subject['code'] ?? 'No Code'} • ${widget.subject['credits'] ?? 0} Credits • ${widget.subject['type'] ?? 'Theory'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF141414).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: widget.isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: widget.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _showEditDialog(context),
                        icon: Icon(CupertinoIcons.pencil, size: 18, color: widget.isDark ? Colors.white70 : Colors.black87),
                        label: Text('Edit', style: TextStyle(color: widget.isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16))),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 48,
                      color: widget.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _confirmDelete(context),
                        icon: const Icon(CupertinoIcons.trash, size: 18, color: Colors.redAccent),
                        label: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomRight: Radius.circular(16))),
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
  }
}
