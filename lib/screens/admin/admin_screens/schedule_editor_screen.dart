import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../widgets/custom_glass_dialog.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import '../../../widgets/bottom_sheet_selector.dart';
import 'dart:convert';
import '../../../config.dart';
import '../../../widgets/toast_manager.dart';
import '../../../services/shared_preferences_service.dart';
import 'dart:math' as math;

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
  String? _originalClassesData;

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
          _originalClassesData = jsonEncode(_classesData);
          _selectedSection = _classesData.first['name'];
          _selectedDay = 1;
          _isExisting = true;
          _loadScheduleForSection(_selectedSection!);
        } else {
          _classesData = [];
          _originalClassesData = jsonEncode([]);
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

    // Build the data first so we can compare
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

    if (jsonEncode(_classesData) == _originalClassesData) {
      EduMateToast.showCompact(context, message: 'No changes made.', isSuccess: true);
      return;
    }

    _showSaveConfirmDialog();
  }

  void _showSaveConfirmDialog() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Save Changes',
      description: 'Are you sure you want to save the schedule changes for ${widget.branch} Semester ${widget.semester}?',
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
      final url = Uri.parse('${Config.scheduleBaseEndpoint}/${widget.branch}/${widget.semester}');

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
          EduMateToast.showCompact(context, message: 'Schedule saved successfully.', isSuccess: true);
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

  int _timeToMinutes(String time) {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return 0;
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (e) {
      return 0;
    }
  }

  bool _hasOverlap(String startTime, String endTime, int day, {int? ignoreIndex}) {
    final startMin = _timeToMinutes(startTime);
    final endMin = _timeToMinutes(endTime);
    
    if (startMin >= endMin) return true;

    final periods = _scheduleData[day] ?? [];
    for (int i = 0; i < periods.length; i++) {
      if (i == ignoreIndex) continue;
      
      final pStart = _timeToMinutes(periods[i]['startTime'] ?? '00:00');
      final pEnd = _timeToMinutes(periods[i]['endTime'] ?? '00:00');
      
      if (math.max(startMin, pStart) < math.min(endMin, pEnd)) {
        return true;
      }
    }
    return false;
  }

  InputDecoration _buildInputDecoration(String label, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 13),
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
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

  void _addPeriod() {
    String tempStartTime = '09:00';
    String tempEndTime = '10:00';
    String tempClassName = '';
    String tempRoom = '';
    
    final startTimeController = TextEditingController(text: tempStartTime);
    final endTimeController = TextEditingController(text: tempEndTime);

    showGlassmorphicDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add Period',
      widthFactor: 0.9,
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Period',
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
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: startTimeController,
                        readOnly: true,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
                        decoration: _buildInputDecoration('Start Time', isDark),
                        onTap: () async {
                          final parts = tempStartTime.split(':');
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(hour: int.tryParse(parts[0]) ?? 9, minute: int.tryParse(parts[1]) ?? 0),
                          );
                          if (picked != null) {
                            final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                            setDialogState(() {
                              tempStartTime = formatted;
                              startTimeController.text = formatted;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: endTimeController,
                        readOnly: true,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
                        decoration: _buildInputDecoration('End Time', isDark),
                        onTap: () async {
                          final parts = tempEndTime.split(':');
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(hour: int.tryParse(parts[0]) ?? 10, minute: int.tryParse(parts[1]) ?? 0),
                          );
                          if (picked != null) {
                            final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                            setDialogState(() {
                              tempEndTime = formatted;
                              endTimeController.text = formatted;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: tempClassName,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
                  decoration: _buildInputDecoration('Class/Subject Name', isDark),
                  onChanged: (val) => tempClassName = val,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: tempRoom,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
                  decoration: _buildInputDecoration('Room', isDark),
                  onChanged: (val) => tempRoom = val,
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
                        child: const Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_hasOverlap(tempStartTime, tempEndTime, _selectedDay)) {
                            EduMateToast.showCompact(context, message: 'Time overlap or invalid time.', isSuccess: false);
                            return;
                          }
                          setState(() {
                            _scheduleData[_selectedDay]!.add({
                              'startTime': tempStartTime,
                              'endTime': tempEndTime,
                              'className': tempClassName,
                              'room': tempRoom,
                            });
                          });
                          EduMateToast.showCompact(context, message: 'Period added.', isSuccess: true);
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
                        child: const Text('Save', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _removePeriod(int index) {
    setState(() {
      _scheduleData[_selectedDay]!.removeAt(index);
    });
    EduMateToast.showCompact(context, message: 'Period deleted.', isSuccess: true);
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 180, bottom: 120),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: BottomSheetSelector<String>(
                                  value: _selectedSection,
                                  items: _classesData.map<String>((s) => s['name'] as String).toList(),
                                  hint: _classesData.isEmpty ? 'No sections added' : 'Select a section',
                                  isAdmin: true,
                                  labelBuilder: (String val) => val,
                                  onChanged: (val) {
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
                                      
                                      final idx = _classesData.indexWhere((c) => c['name'] == _selectedSection);
                                      if (idx != -1) {
                                        _classesData[idx]['schedule'] = finalScheduleData;
                                      }
                                    }

                                    setState(() {
                                      _selectedSection = val;
                                      _loadScheduleForSection(val);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedSection != null) ...[
                          Container(
                            height: 55,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF141414).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: const Color(0xFFFF1744).withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: List.generate(5, (i) {
                                      final dayNum = i + 1;
                                      final isSelected = _selectedDay == dayNum;
                                      return GestureDetector(
                                        onTap: () => setState(() => _selectedDay = dayNum),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 250),
                                          curve: Curves.easeInOut,
                                          width: 60,
                                          height: 40,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: isSelected ? const Color(0xFFFF1744) : Colors.transparent,
                                            borderRadius: BorderRadius.circular(19),
                                          ),
                                          child: Text(
                                            _days[i],
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected
                                                  ? Colors.white
                                                  : (isDark ? Colors.white70 : Colors.black87),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _scheduleData[_selectedDay]!.isEmpty
                              ? Container(
                                  height: 200,
                                  alignment: Alignment.center,
                                  child: Text(
                                    'No classes scheduled for ${_days[_selectedDay - 1]}.',
                                    style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600]),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _scheduleData[_selectedDay]!.length,
                                  itemBuilder: (context, index) {
                                    final period = _scheduleData[_selectedDay]![index];
                                    return _PeriodEditCard(
                                      key: ObjectKey(period),
                                      period: period,
                                      isDark: isDark,
                                      onChanged: () => setState(() {}),
                                      onRemove: () => _removePeriod(index),
                                      onValidateTime: (start, end) => !_hasOverlap(start, end, _selectedDay, ignoreIndex: index),
                                    );
                                  },
                                ),
                        ] else ...[
                          Container(
                            height: 200,
                            alignment: Alignment.center,
                            child: Text(
                              'Please add a section to start editing schedules.',
                              style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600]),
                            ),
                          ),
                        ],
                      ],
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
                                        'Edit Schedule',
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
                                    _buildSummaryItem('Section', _selectedSection ?? 'N/A', isDark),
                                    _buildSummaryItem('Periods', '${_scheduleData[_selectedDay]?.length ?? 0}', isDark),
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
                if (_selectedSection != null)
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
                                onPressed: _addPeriod,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Period'),
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

class _PeriodEditCard extends StatefulWidget {
  final Map<String, dynamic> period;
  final bool isDark;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final bool Function(String, String)? onValidateTime;

  const _PeriodEditCard({
    super.key,
    required this.period,
    required this.isDark,
    required this.onChanged,
    required this.onRemove,
    this.onValidateTime,
  });

  @override
  State<_PeriodEditCard> createState() => _PeriodEditCardState();
}

class _PeriodEditCardState extends State<_PeriodEditCard> {

  void _confirmDelete(BuildContext context) async {
    final confirmed = await showDeleteConfirmationDialog(
      context: context,
      title: 'Delete Period',
      description: 'Are you sure you want to delete ${widget.period['className']?.toString().isNotEmpty == true ? "'${widget.period['className']}'" : 'this period'}? This action cannot be undone.',
    );
    if (confirmed == true) {
      widget.onRemove();
    }
  }

  void _showEditDialog(BuildContext context) {
    String tempStartTime = widget.period['startTime'] ?? '09:00';
    String tempEndTime = widget.period['endTime'] ?? '10:00';
    String tempClassName = widget.period['className'] ?? '';
    String tempRoom = widget.period['room'] ?? '';
    
    final startTimeController = TextEditingController(text: tempStartTime);
    final endTimeController = TextEditingController(text: tempEndTime);

    showGlassmorphicDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Edit Period',
      widthFactor: 0.9,
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Edit Period',
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
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: startTimeController,
                                readOnly: true,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
                                decoration: _buildInputDecoration('Start Time'),
                                onTap: () async {
                                  final parts = tempStartTime.split(':');
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay(hour: int.tryParse(parts[0]) ?? 9, minute: int.tryParse(parts[1]) ?? 0),
                                  );
                                  if (picked != null) {
                                    final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                    setDialogState(() {
                                      tempStartTime = formatted;
                                      startTimeController.text = formatted;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: endTimeController,
                                readOnly: true,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
                                decoration: _buildInputDecoration('End Time'),
                                onTap: () async {
                                  final parts = tempEndTime.split(':');
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay(hour: int.tryParse(parts[0]) ?? 10, minute: int.tryParse(parts[1]) ?? 0),
                                  );
                                  if (picked != null) {
                                    final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                    setDialogState(() {
                                      tempEndTime = formatted;
                                      endTimeController.text = formatted;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: tempClassName,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
                          decoration: _buildInputDecoration('Class/Subject Name'),
                          onChanged: (val) => tempClassName = val,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: tempRoom,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
                          decoration: _buildInputDecoration('Room'),
                          onChanged: (val) => tempRoom = val,
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
                                  if (widget.onValidateTime != null) {
                                    if (!widget.onValidateTime!(tempStartTime, tempEndTime)) {
                                      EduMateToast.showCompact(context, message: 'Time overlap or invalid time.', isSuccess: false);
                                      return;
                                    }
                                  }
                                  widget.period['startTime'] = tempStartTime;
                                  widget.period['endTime'] = tempEndTime;
                                  widget.period['className'] = tempClassName;
                                  widget.period['room'] = tempRoom;
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
        },
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
    final String title = widget.period['className']?.toString().trim().isNotEmpty == true 
        ? widget.period['className'] 
        : 'New Period';
    final String subtitle = '${widget.period['startTime'] ?? '09:00'} - ${widget.period['endTime'] ?? '10:00'}  •  Room: ${widget.period['room'] ?? 'N/A'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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

