import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

typedef OnSaveSettings = void Function(
  String branch,
  int semester,
  String section,
  Map<String, String> selectedElectives,
  bool savePreference,
);

// ============================================================
// Settings Bottom Sheet
// ============================================================
class SettingsBottomSheet extends StatefulWidget {
  final String initialBranch;
  final int initialSemester;
  final String initialSection;
  final Map<String, String> initialSelectedElectives;
  final List<String> branches;
  final bool hasPreference; // Whether saved prefs exist
  final Future<List<String>> Function(String branch, int semester) fetchSections;
  final Future<Map<String, List<String>>> Function(String branch, int semester) fetchElectives;
  final OnSaveSettings onSave;

  const SettingsBottomSheet({
    super.key,
    required this.initialBranch,
    required this.initialSemester,
    required this.initialSection,
    required this.initialSelectedElectives,
    required this.branches,
    required this.fetchSections,
    required this.fetchElectives,
    required this.onSave,
    this.hasPreference = false,
  });

  @override
  State<SettingsBottomSheet> createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends State<SettingsBottomSheet> {
  late String selectedBranch;
  late int selectedSemester;
  late String selectedSection;
  late Map<String, String> selectedElectives;

  List<String> availableSections = [];
  Map<String, List<String>> availableElectives = {};
  bool isLoadingSections = false;
  bool isLoadingElectives = false;

  // Shortened UI names for display
  final Map<int, List<String>> semesterElectiveMap = {
    1: ['Eng - II', 'Science'],
    2: ['Eng - I', 'HASS - I'],
    3: [],
    4: ['HASS - II'],
    5: ['Open - I', 'PE - I', 'PE - II'],
    6: ['PE - III', 'HASS - III', 'Open - II'],
    7: ['PE - IV'],
    8: [],
  };

  @override
  void initState() {
    super.initState();
    selectedBranch = widget.initialBranch.isEmpty ? 'CSE' : widget.initialBranch;
    selectedSemester = widget.initialSemester;
    selectedSection = widget.initialSection;
    selectedElectives = Map.from(widget.initialSelectedElectives);
    _loadDependencies();
  }

  void _loadDependencies() {
    _loadSections();
    _loadElectives();
  }

  Future<void> _loadSections() async {
    setState(() => isLoadingSections = true);
    final sections = await widget.fetchSections(selectedBranch, selectedSemester);
    if (mounted) {
      setState(() {
        availableSections = sections;
        if (sections.isNotEmpty && !sections.contains(selectedSection)) {
          selectedSection = sections.first;
        }
        isLoadingSections = false;
      });
    }
  }

  Future<void> _loadElectives() async {
    setState(() => isLoadingElectives = true);
    final electives = await widget.fetchElectives(selectedBranch, selectedSemester);
    if (mounted) {
      setState(() {
        availableElectives = electives;
        isLoadingElectives = false;
      });
    }
  }

  // Maps shortened UI name → backend group name
  String _getBackendGroupName(String uiName) {
    switch (uiName) {
      case 'Open - I':   return 'K-Explore';
      case 'Open - II':  return 'Open Elective - II';
      case 'PE - I':     return 'PE-1';
      case 'PE - II':    return 'PE-2';
      case 'PE - III':   return 'PE-3';
      case 'PE - IV':    return 'PE-4';
      case 'Eng - I':    return 'Engineering Elective - I';
      case 'Eng - II':   return 'Engineering Elective - II';
      case 'Science':    return 'Science Elective';
      case 'HASS - I':   return 'HASS Elective - I';
      case 'HASS - II':  return 'HASS Elective - II';
      case 'HASS - III': return 'HASS Elective - III';
      default: return uiName;
    }
  }

  // Returns true if current modal state differs from what was initially passed in
  bool get _isEdited {
    if (selectedBranch != widget.initialBranch) return true;
    if (selectedSemester != widget.initialSemester) return true;
    if (selectedSection != widget.initialSection) return true;
    
    if (selectedElectives.length != widget.initialSelectedElectives.length) return true;
    for (var key in widget.initialSelectedElectives.keys) {
      if (selectedElectives[key] != widget.initialSelectedElectives[key]) return true;
    }
    return false;
  }

  void _showInfoDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Settings Info', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 12),
            Row(children: [
              Icon(CupertinoIcons.circle, color: Colors.grey, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('Grey Tick: No save preference', style: TextStyle(fontSize: 13, fontFamily: 'Poppins'), textAlign: TextAlign.left,))
            ]),
            SizedBox(height: 8),
            Row(children: [
              Icon(CupertinoIcons.check_mark_circled_solid, color: CupertinoColors.activeGreen, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('Green Tick: Save preference active', style: TextStyle(fontSize: 13, fontFamily: 'Poppins'), textAlign: TextAlign.left,))
            ]),
            SizedBox(height: 8),
            Row(children: [
              Icon(CupertinoIcons.check_mark_circled_solid, color: CupertinoColors.activeOrange, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('Orange Tick: Edit has been made', style: TextStyle(fontSize: 13, fontFamily: 'Poppins'), textAlign: TextAlign.left,))
            ]),
            SizedBox(height: 16),
            Text('Show: Views current config without altering the saved preference.\n\nSave: Saves the current config to preferences.', style: TextStyle(fontSize: 12, fontFamily: 'Poppins', color: Colors.white70), textAlign: TextAlign.left,),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Got it', style: TextStyle(color: AuthPalette.coral, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showTwoColumnPicker({
    required String title,
    required List<String> items,
    required String? currentValue,
    required ValueChanged<String> onSelected,
  }) {
    // Group items by subject and section
    final Map<String, Map<String, String>> grouped = {};
    for (final item in items) {
      // e.g. "DMDW10" -> match(1)="DMDW", match(2)="10"
      // e.g. "DOS 4" -> match(1)="DOS", match(2)="4"
      final match = RegExp(r'^([a-zA-Z\s\-]+?)\s*(\d+)$').firstMatch(item.trim());
      if (match != null) {
        final subject = match.group(1)!.trim();
        final section = match.group(2)!.trim();
        grouped.putIfAbsent(subject, () => {})[section] = item;
      } else {
        // Fallback if it doesn't match the expected pattern
        grouped.putIfAbsent(item, () => {})[''] = item;
      }
    }

    final subjects = grouped.keys.toList();
    if (subjects.isEmpty) return;

    // Determine initial indices
    int initialSubjectIdx = 0;
    int initialSectionIdx = 0;
    if (currentValue != null && currentValue.isNotEmpty) {
      for (int i = 0; i < subjects.length; i++) {
        final subject = subjects[i];
        final sections = grouped[subject]!.keys.toList();
        final sectionIdx = sections.indexWhere((sec) => grouped[subject]![sec] == currentValue);
        if (sectionIdx != -1) {
          initialSubjectIdx = i;
          initialSectionIdx = sectionIdx;
          break;
        }
      }
    }

    String selectedSubject = subjects[initialSubjectIdx];
    List<String> currentSections = grouped[selectedSubject]!.keys.toList();
    String selectedSection = currentSections.isNotEmpty ? currentSections[initialSectionIdx] : '';

    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: 300,
            color: const Color(0xFF1C1C1E),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(title, style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration: TextDecoration.none,
                        )),
                        CupertinoButton(
                          child: const Text('Done', style: TextStyle(
                            fontFamily: 'Poppins',
                            color: AuthPalette.coral,
                            fontWeight: FontWeight.bold,
                          )),
                          onPressed: () {
                            final originalValue = grouped[selectedSubject]?[selectedSection];
                            if (originalValue != null) {
                              onSelected(originalValue);
                            }
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: CupertinoPicker(
                            itemExtent: 40,
                            magnification: 1.22,
                            useMagnifier: true,
                            scrollController: FixedExtentScrollController(initialItem: initialSubjectIdx),
                            onSelectedItemChanged: (i) {
                              setModalState(() {
                                selectedSubject = subjects[i];
                                currentSections = grouped[selectedSubject]!.keys.toList();
                                selectedSection = currentSections.isNotEmpty ? currentSections[0] : '';
                                initialSectionIdx = 0; // reset right column
                              });
                            },
                            children: subjects.map((e) => Center(
                              child: Text(e, style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.none,
                              )),
                            )).toList(),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: CupertinoPicker(
                            key: ValueKey(selectedSubject), // Rebuild when subject changes
                            itemExtent: 40,
                            magnification: 1.22,
                            useMagnifier: true,
                            scrollController: FixedExtentScrollController(initialItem: initialSectionIdx),
                            onSelectedItemChanged: (i) {
                              selectedSection = currentSections[i];
                            },
                            children: currentSections.map((e) => Center(
                              child: Text(e, style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.none,
                              )),
                            )).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPicker({
    required String title,
    required List<String> items,
    required String? currentValue,
    required ValueChanged<String> onSelected,
  }) {
    int idx = items.indexOf(currentValue ?? '');
    if (idx == -1) idx = 0;
    String picked = items[idx];

    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: const Color(0xFF1C1C1E),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(title, style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration: TextDecoration.none,
                    )),
                    CupertinoButton(
                      child: Text('Done', style: TextStyle(
                        fontFamily: 'Poppins',
                        color: AuthPalette.coral,
                        fontWeight: FontWeight.bold,
                      )),
                      onPressed: () {
                        onSelected(picked);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40,
                  magnification: 1.22,
                  useMagnifier: true,
                  scrollController: FixedExtentScrollController(initialItem: idx),
                  onSelectedItemChanged: (i) => picked = items[i],
                  children: items.map((e) => Center(
                    child: Text(e, style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    )),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Builds a row: Icon | Label ............. [  Pill Selector ▼  ]
  Widget _buildSettingsRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 14),
          Expanded(
            flex: 4,
            child: Text(label, style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w500,
            )),
          ),
          const SizedBox(width: 8),
          isLoading
            ? const CupertinoActivityIndicator()
            : Expanded(
                flex: 5,
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: Text(
                            value.isEmpty ? 'Select' : value,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(CupertinoIcons.chevron_down, color: Colors.white54, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requiredElectives = semesterElectiveMap[selectedSemester] ?? [];

    return Material(
      type: MaterialType.transparency,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1D).withValues(alpha: 0.92),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40, height: 5,
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3)),
                    ),
                  ),

                  // Header with tick logic
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        const Text('Preferences', style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        )),
                        const SizedBox(width: 10),
                        Builder(
                          builder: (context) {
                            if (_isEdited) {
                              return Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: CupertinoColors.activeOrange, shape: BoxShape.circle),
                                child: const Icon(CupertinoIcons.check_mark, color: Colors.white, size: 14),
                              );
                            } else if (widget.hasPreference) {
                              return Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: CupertinoColors.activeGreen, shape: BoxShape.circle),
                                child: const Icon(CupertinoIcons.check_mark, color: Colors.white, size: 14),
                              );
                            } else {
                              return Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                                child: const Icon(CupertinoIcons.check_mark, color: Colors.white54, size: 14),
                              );
                            }
                          },
                        ),
                        const Spacer(),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _showInfoDialog,
                          child: const Icon(CupertinoIcons.info_circle_fill, color: Colors.white38, size: 26),
                        ),
                        const SizedBox(width: 8),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          child: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white38, size: 26),
                        ),
                      ],
                    ),
                  ),

                  // Branch segment
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: SizedBox(
                      width: double.infinity,
                      child: CupertinoSlidingSegmentedControl<String>(
                        groupValue: selectedBranch,
                        thumbColor: AuthPalette.coral.withValues(alpha: 0.8),
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        children: {
                          for (var b in widget.branches)
                            b: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(b, style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 13,
                              )),
                            ),
                        },
                        onValueChanged: (val) {
                          if (val != null) {
                            setState(() { selectedBranch = val; selectedSection = ''; });
                            _loadDependencies();
                          }
                        },
                      ),
                    ),
                  ),

                  const Divider(color: Colors.white10, height: 20),

                  // Semester
                  _buildSettingsRow(
                    icon: CupertinoIcons.book,
                    label: 'Semester',
                    value: 'Sem $selectedSemester',
                    onTap: () => _showPicker(
                      title: 'Select Semester',
                      items: List.generate(8, (i) => 'Sem ${i + 1}'),
                      currentValue: 'Sem $selectedSemester',
                      onSelected: (val) {
                        setState(() {
                          selectedSemester = int.parse(val.replaceAll('Sem ', ''));
                          selectedSection = '';
                          selectedElectives.clear();
                        });
                        _loadDependencies();
                      },
                    ),
                  ),

                  // Section
                  _buildSettingsRow(
                    icon: CupertinoIcons.person_2,
                    label: 'Section',
                    value: selectedSection,
                    isLoading: isLoadingSections,
                    onTap: () {
                      if (availableSections.isEmpty) return;
                      _showPicker(
                        title: 'Select Section',
                        items: availableSections,
                        currentValue: selectedSection,
                        onSelected: (val) => setState(() => selectedSection = val),
                      );
                    },
                  ),

                  // Dynamic electives
                  ...requiredElectives.map((uiGroup) {
                    final backendGroup = _getBackendGroupName(uiGroup);
                    final options = availableElectives[backendGroup] ?? [];
                    final current = selectedElectives[backendGroup] ?? '';
                    return _buildSettingsRow(
                      icon: CupertinoIcons.square_stack_3d_up,
                      label: uiGroup,
                      value: current.isEmpty ? 'Select' : current,
                      isLoading: isLoadingElectives,
                      onTap: () {
                        if (options.isEmpty) return;
                        _showTwoColumnPicker(
                          title: uiGroup,
                          items: options,
                          currentValue: current,
                          onSelected: (val) => setState(() => selectedElectives[backendGroup] = val),
                        );
                      },
                    );
                  }),

                  const Divider(color: Colors.white10, height: 20),

                  // Show + Save buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: Row(
                      children: [
                        // Show button (coral) — shows schedule without saving prefs
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            color: AuthPalette.coral,
                            borderRadius: BorderRadius.circular(14),
                            onPressed: () => widget.onSave(
                              selectedBranch, selectedSemester, selectedSection,
                              selectedElectives, false, // savePreference = false
                            ),
                            child: const Text('Show', style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            )),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Save button (green) — saves prefs + shows schedule
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            color: CupertinoColors.activeGreen,
                            borderRadius: BorderRadius.circular(14),
                            onPressed: () => widget.onSave(
                              selectedBranch, selectedSemester, selectedSection,
                              selectedElectives, true, // savePreference = true
                            ),
                            child: const Text('Save', style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            )),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
