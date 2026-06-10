import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config.dart';
import '../../../widgets/toast_manager.dart';
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
          _isLoading = false;
        });
      } else {
        setState(() {
          _isExisting = false;
          _subjects = [];
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
          EduMateToast.showSuccessCard(
            context,
            title: 'Success',
            description: 'Curriculum saved successfully.',
          );
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
        'type': 'Core',
      });
    });
  }

  void _removeSubject(int index) {
    setState(() {
      _subjects.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Semester ${widget.semester} Curriculum (${widget.branch})',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
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
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : Column(
              children: [
                Expanded(
                  child: _subjects.isEmpty
                      ? Center(
                          child: Text(
                            'No subjects added yet.',
                            style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _subjects.length,
                          itemBuilder: (context, index) {
                            return _SubjectEditCard(
                              subject: _subjects[index],
                              subjectTypes: _subjectTypes,
                              isDark: isDark,
                              onChanged: () => setState(() {}),
                              onRemove: () => _removeSubject(index),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: _addSubject,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Subject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF1E1E1E) : CupertinoColors.systemGrey6,
                      foregroundColor: isDark ? Colors.white : Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SubjectEditCard extends StatelessWidget {
  final Map<String, dynamic> subject;
  final List<String> subjectTypes;
  final bool isDark;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _SubjectEditCard({
    required this.subject,
    required this.subjectTypes,
    required this.isDark,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextFormField(
                  initialValue: subject['code'],
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Code',
                    labelStyle: TextStyle(color: Colors.grey[500]),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (val) {
                    subject['code'] = val;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: subject['name'],
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Subject Name',
                    labelStyle: TextStyle(color: Colors.grey[500]),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (val) {
                    subject['name'] = val;
                    onChanged();
                  },
                ),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.delete, color: Colors.red),
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: subject['credits'].toString(),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Credits',
                    labelStyle: TextStyle(color: Colors.grey[500]),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (val) {
                    subject['credits'] = int.tryParse(val) ?? 0;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: subject['type'],
                  decoration: InputDecoration(
                    labelText: 'Type',
                    labelStyle: TextStyle(color: Colors.grey[500]),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  items: subjectTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      subject['type'] = val;
                      onChanged();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
