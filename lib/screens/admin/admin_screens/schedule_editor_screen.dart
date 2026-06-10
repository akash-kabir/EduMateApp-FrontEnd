import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config.dart';
import '../../../widgets/toast_manager.dart';
import '../../../services/shared_preferences_service.dart';

class ScheduleEditorScreen extends StatefulWidget {
  final String branch;
  final int semester;

  const ScheduleEditorScreen({
    super.key,
    required this.branch,
    required this.semester,
  });

  @override
  State<ScheduleEditorScreen> createState() => _ScheduleEditorScreenState();
}

class _ScheduleEditorScreenState extends State<ScheduleEditorScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isExisting = false;

  List<dynamic> _classesData = [];
  String? _selectedSection;

  Map<int, List<Map<String, dynamic>>> _scheduleData = {
    1: [], 2: [], 3: [], 4: [], 5: [],
  };

  int _selectedDay = 1;

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  @override
  void initState() {
    super.initState();
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${Config.scheduleBaseEndpoint}/${widget.branch}/${widget.semester}?t=${DateTime.now().millisecondsSinceEpoch}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        
        if (data['classes'] != null && (data['classes'] as List).isNotEmpty) {
          _classesData = data['classes'];
          _selectedSection = null;
          _isExisting = true;
          // Prompt user to select section and day after data is loaded
          WidgetsBinding.instance.addPostFrameCallback((_) => _promptSectionAndDay());
        } else {
          _classesData = [];
          _selectedSection = null;
          _isExisting = false;
        }
        
        setState(() => _isLoading = false);
      } else {
        setState(() {
          _isExisting = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        EduMateToast.showCompact(
          context,
          message: 'Failed to fetch schedule: $e',
          isSuccess: false,
        );
      }
      setState(() => _isLoading = false);
    }
  }



  Future<void> _saveSchedule() async {
    // Validation
    for (var day in [1, 2, 3, 4, 5]) {
      for (var period in _scheduleData[day]!) {
        if (period['className'].toString().trim().isEmpty) {
          EduMateToast.showCompact(context, message: 'Class Name cannot be empty on Day $day.', isSuccess: false);
          return;
        }
        if (period['startTime'].toString().trim().isEmpty || period['endTime'].toString().trim().isEmpty) {
          EduMateToast.showCompact(context, message: 'Time cannot be empty on Day $day.', isSuccess: false);
          return;
        }
      }
    }

    setState(() => _isSaving = true);
    try {
      final token = await SharedPreferencesService.getToken();
      final url = Uri.parse('${Config.scheduleBaseEndpoint}/${widget.branch}/${widget.semester}');
      
      // Update local _classesData for selected section
      if (_selectedSection != null) {
        List<Map<String, dynamic>> finalScheduleData = [];
        for (var day in [1, 2, 3, 4, 5]) {
          if (_scheduleData[day]!.isNotEmpty) {
            finalScheduleData.add({
              'day': day,
              'periods': _scheduleData[day],
            });
          }
        }
        
        final sectionIndex = _classesData.indexWhere((s) => s['name'] == _selectedSection);
        if (sectionIndex >= 0) {
          _classesData[sectionIndex]['schedule'] = finalScheduleData;
        } else {
          _classesData.add({
            'name': _selectedSection,
            'schedule': finalScheduleData,
          });
        }
      }

      final payload = jsonEncode({
        'classes': _classesData
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
            description: 'Schedule saved successfully.',
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

  // Prompt user to select a section and then a day before loading schedule
  void _promptSectionAndDay() async {
    if (_classesData.isEmpty) return;
    String? chosenSection;
    int? chosenDay;

    // Section selection dialog
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        String? tempSection = _classesData.first['name'];
        return AlertDialog(
          title: const Text('Select Section'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButton<String>(
                isExpanded: true,
                value: tempSection,
                items: _classesData.map<DropdownMenuItem<String>>((s) {
                  return DropdownMenuItem<String>(
                    value: s['name'],
                    child: Text(s['name'] ?? ''),
                  );
                }).toList(),
                onChanged: (val) => setState(() => tempSection = val),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                chosenSection = tempSection;
                Navigator.of(ctx).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (chosenSection == null) return;

    // Day selection dialog
    await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        int tempDay = 1;
        return AlertDialog(
          title: const Text('Select Day'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButton<String>(
                isExpanded: true,
                value: _days[tempDay - 1],
                items: _days.map<DropdownMenuItem<String>>((d) {
                  return DropdownMenuItem<String>(
                    value: d,
                    child: Text(d),
                  );
                }).toList(),
                onChanged: (val) => setState(() => tempDay = _days.indexOf(val!) + 1),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                chosenDay = tempDay;
                Navigator.of(ctx).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (chosenDay == null) return;

    setState(() {
      _selectedSection = chosenSection;
      _selectedDay = chosenDay!;
    });
    _loadScheduleForSection(_selectedSection!);
  }

  void _loadScheduleForSection(String sectionName) {
    Map<int, List<Map<String, dynamic>>> parsedSchedule = {
      1: [], 2: [], 3: [], 4: [], 5: []
    };
    
    final sectionData = _classesData.firstWhere(
      (s) => s['name'] == sectionName,
      orElse: () => <String, dynamic>{}
    );

    if (sectionData.isNotEmpty && sectionData['schedule'] != null) {
      for (var dayObj in sectionData['schedule']) {
        int day = dayObj['day'];
        List<Map<String, dynamic>> periods = List<Map<String, dynamic>>.from(
          dayObj['periods'].map((p) => {
            'startTime': p['startTime'],
            'endTime': p['endTime'],
            'className': p['className'],
            'room': p['room'],
          })
        );
        parsedSchedule[day] = periods;
      }
    }
    
    setState(() {
      _scheduleData = parsedSchedule;
    });
  }

  void _addPeriod() {
    setState(() {
      _scheduleData[_selectedDay]!.add({
        'startTime': '09:00',
        'endTime': '10:00',
        'className': '',
        'room': '',
      });
    });
  }

  void _removePeriod(int index) {
    setState(() {
      _scheduleData[_selectedDay]!.removeAt(index);
    });
  }

  void _showAddSectionDialog() {
    TextEditingController controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Add Section'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'e.g. CSE-10',
          ),
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
              if (controller.text.trim().isNotEmpty) {
                final name = controller.text.trim();
                setState(() {
                  _classesData.add({
                    'name': name,
                    'schedule': []
                  });
                  _selectedSection = name;
                  _loadScheduleForSection(name);
                });
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
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
          'Semester ${widget.semester} Schedule (${widget.branch})',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveSchedule,
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
                // Section Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Text(
                        'Section: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedSection,
                              hint: Text(
                                _classesData.isEmpty ? 'No sections added' : 'Select a section',
                                style: TextStyle(color: isDark ? Colors.grey : Colors.black54),
                              ),
                              dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 16,
                              ),
                              items: _classesData.map<DropdownMenuItem<String>>((s) {
                                return DropdownMenuItem<String>(
                                  value: s['name'],
                                  child: Text(s['name']),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  // Save current schedule back to _classesData before switching
                                  if (_selectedSection != null) {
                                    List<Map<String, dynamic>> finalScheduleData = [];
                                    for (var day in [1, 2, 3, 4, 5]) {
                                      if (_scheduleData[day]!.isNotEmpty) {
                                        finalScheduleData.add({
                                          'day': day,
                                          'periods': _scheduleData[day],
                                        });
                                      }
                                    }
                                    final sectionIndex = _classesData.indexWhere((s) => s['name'] == _selectedSection);
                                    if (sectionIndex >= 0) {
                                      _classesData[sectionIndex]['schedule'] = finalScheduleData;
                                    }
                                  }

                                  setState(() {
                                    _selectedSection = val;
                                  });
                                  _loadScheduleForSection(val);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _showAddSectionDialog,
                        icon: const Icon(CupertinoIcons.add_circled_solid),
                        color: const Color(0xFFFF1744),
                        tooltip: 'Add Section',
                      ),
                    ],
                  ),
                ),
                if (_selectedSection != null) ...[
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        final dayNum = index + 1;
                        final isSelected = _selectedDay == dayNum;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedDay = dayNum),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFF1744) : (isDark ? const Color(0xFF1E1E1E) : CupertinoColors.systemGrey6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _days[index],
                              style: TextStyle(
                                color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: _scheduleData[_selectedDay]!.isEmpty
                        ? Center(
                            child: Text(
                              'No classes scheduled for ${_days[_selectedDay - 1]}.',
                              style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600]),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _scheduleData[_selectedDay]!.length,
                            itemBuilder: (context, index) {
                              return _PeriodEditCard(
                                period: _scheduleData[_selectedDay]![index],
                                isDark: isDark,
                                onChanged: () => setState(() {}),
                                onRemove: () => _removePeriod(index),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: _addPeriod,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Period'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF1E1E1E) : CupertinoColors.systemGrey6,
                        foregroundColor: isDark ? Colors.white : Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Center(
                      child: Text(
                        'Please add a section to start editing schedules.',
                        style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600]),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _PeriodEditCard extends StatelessWidget {
  final Map<String, dynamic> period;
  final bool isDark;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _PeriodEditCard({
    required this.period,
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
                child: TextFormField(
                  initialValue: period['startTime'],
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Start Time (HH:MM)',
                    labelStyle: TextStyle(color: Colors.grey[500]),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (val) {
                    period['startTime'] = val;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: period['endTime'],
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'End Time (HH:MM)',
                    labelStyle: TextStyle(color: Colors.grey[500]),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (val) {
                    period['endTime'] = val;
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
                flex: 2,
                child: TextFormField(
                  initialValue: period['className'],
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Class/Subject Name',
                    labelStyle: TextStyle(color: Colors.grey[500]),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (val) {
                    period['className'] = val;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextFormField(
                  initialValue: period['room'],
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Room',
                    labelStyle: TextStyle(color: Colors.grey[500]),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (val) {
                    period['room'] = val;
                    onChanged();
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
