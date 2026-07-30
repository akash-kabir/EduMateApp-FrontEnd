import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app/features/auth_and_profile/screens/profile_setup/profile_setup_constants.dart';
import 'package:app/theme/theme.dart';
import 'package:app/features/auth_and_profile/screens/profile_setup/profile_setup_logic.dart';

enum DialogStep {
  init,
  emailDetected,
  enterRollNo,
  sending,
  receiving,
  dataFound,
  manualEntry,
  success,
}

class ProfileSetupDialogFlow extends StatefulWidget {
  final String? userId;
  final String? token;
  final VoidCallback? onComplete;

  const ProfileSetupDialogFlow({
    super.key,
    this.userId,
    this.token,
    this.onComplete,
  });

  @override
  State<ProfileSetupDialogFlow> createState() => _ProfileSetupDialogFlowState();
}

class _ProfileSetupDialogFlowState extends State<ProfileSetupDialogFlow>
    with TickerProviderStateMixin {
  late final ProfileSetupLogic _logic;
  DialogStep _currentStep = DialogStep.init;
  String _errorMessage = '';

  // Animations
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _logic = ProfileSetupLogic(
      userId: widget.userId,
      token: widget.token,
    );
    _logic.addListener(_onLogicChange);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _runInitSequence();
  }

  Future<void> _runInitSequence() async {
    // Wait slightly for logic to init
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    if (_logic.isKiitEmail && _logic.detectedRollNo != null) {
      _setStep(DialogStep.emailDetected);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) _startSearch(_logic.detectedRollNo!);
    } else {
      _setStep(DialogStep.enterRollNo);
    }
  }

  void _onLogicChange() {
    if (mounted) setState(() {});
  }

  Future<void> _setStep(DialogStep step) async {
    await _fadeController.reverse();
    if (!mounted) return;
    setState(() => _currentStep = step);
    _fadeController.forward();
  }

  Future<void> _startSearch(String rollNo) async {
    if (rollNo.isEmpty) {
      setState(() => _errorMessage = 'Please enter a roll number');
      return;
    }
    _setStep(DialogStep.sending);
    
    // Animate "Fetching Data..." for at least 1 second while doing the network request
    final minAnimTime = Future.delayed(const Duration(milliseconds: 1000));
    final profileFuture = _logic.fetchProfileData(rollNo);
    
    await Future.wait([minAnimTime, profileFuture]);
    final found = await profileFuture;
    
    if (!mounted) return;

    if (found) {
      _setStep(DialogStep.receiving);
      
      // Animate "Downloading Data..." for at least 1 second while downloading schedules
      final minDownloadAnimTime = Future.delayed(const Duration(milliseconds: 1000));
      final downloadFuture = _logic.downloadScheduleAndSave();
      
      await Future.wait([minDownloadAnimTime, downloadFuture]);
      final downloadSuccess = await downloadFuture;
      
      if (!mounted) return;
      if (downloadSuccess) {
        _setStep(DialogStep.dataFound);
      } else {
        _setStep(DialogStep.manualEntry);
      }
    } else {
      _setStep(DialogStep.manualEntry);
    }
  }



  @override
  void dispose() {
    _logic.removeListener(_onLogicChange);
    _logic.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final accent = AuthPalette.coral;

    return PopScope(
      canPop: false, // Non-dismissible
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: FadeTransition(
          opacity: _fadeController,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCurrentStep(accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(Color accent) {
    switch (_currentStep) {
      case DialogStep.init:
        return const SizedBox(
          height: 100,
          child: Center(child: CupertinoActivityIndicator(radius: 14)),
        );
      
      case DialogStep.emailDetected:
        return _buildEmailDetected(accent);
      
      case DialogStep.enterRollNo:
        return _buildEnterRollNo(accent);
      
      case DialogStep.sending:
        return _buildAnimationState(accent, sending: true);
      
      case DialogStep.receiving:
        return _buildAnimationState(accent, sending: false);
      
      case DialogStep.dataFound:
        return _buildDataFound(accent);
      
      case DialogStep.manualEntry:
        return _buildManualEntry(accent);
      
      case DialogStep.success:
        return _buildSuccess(accent);
    }
  }

  // ─── Individual Steps ────────────────────────────────────────────────────────

  Widget _buildEmailDetected(Color accent) {
    return Column(
      children: [
        Icon(CupertinoIcons.checkmark_seal_fill, color: const Color(0xFF10B981), size: 50),
        const SizedBox(height: 16),
        Text(
          'KIIT Email Detected',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Roll Number: ${_logic.detectedRollNo}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 20),
        const CupertinoActivityIndicator(),
      ],
    );
  }

  Widget _buildEnterRollNo(Color accent) {
    return Column(
      children: [
        Icon(CupertinoIcons.person_crop_circle_badge_exclam, color: accent, size: 40),
        const SizedBox(height: 16),
        Text(
          'Enter Roll Number',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We couldn\'t auto-detect your roll number.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 20),
        CupertinoTextField(
          controller: _logic.rollNoController,
          placeholder: 'e.g. 2105001',
          padding: const EdgeInsets.only(left: 14, top: 12, bottom: 12, right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          suffix: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => _startSearch(_logic.rollNoController.text.trim()),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.arrow_right, color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
        if (_errorMessage.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildAnimationState(Color accent, {required bool sending}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.globe, size: 40, color: Colors.white70),
            const SizedBox(width: 20),
            BarsScaleAnimation(color: accent),
            const SizedBox(width: 20),
            Icon(CupertinoIcons.device_phone_portrait, size: 40, color: Colors.white70),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          sending ? 'Fetching Data...' : 'Downloading Data...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildDataFound(Color accent) {
    return Column(
      children: [
        Icon(CupertinoIcons.checkmark_alt_circle_fill, color: const Color(0xFF10B981), size: 40),
        const SizedBox(height: 12),
        Text(
          'Data Found',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow('Roll No:', _logic.rollNoController.text),
        _buildInfoRow('Year:', _logic.selectedYear ?? '-'),
        _buildInfoRow('Semester:', _logic.selectedSemester ?? '-'),
        _buildInfoRow('Branch:', _logic.selectedBranch ?? '-'),
        _buildInfoRow('Section:', _logic.selectedSection ?? '-'),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            color: accent,
            borderRadius: BorderRadius.circular(12),
            onPressed: () {
              widget.onComplete?.call();
              Navigator.pop(context);
            },
            child: const Text('Okay', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildManualEntry(Color accent) {
    return Column(
      children: [
        Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.orange, size: 40),
        const SizedBox(height: 12),
        Text(
          'Data Not Found',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please enter your details manually.',
          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
        ),
        const SizedBox(height: 20),
        // Just the essentials for dialog
        _buildDropdown(
          context: context,
          hint: 'Select Year',
          value: _logic.selectedYear,
          items: ProfileSetupConstants.academicYears,
          onChanged: (val) {
            _logic.selectedYear = val;
            _logic.updateSemester(null);
          },

        ),
        const SizedBox(height: 12),
        _buildDropdown(
          context: context,
          hint: 'Select Semester',
          value: _logic.selectedSemester,
          items: ProfileSetupConstants.semestersByYear[_logic.selectedYear] ?? [],
          onChanged: (val) => _logic.updateSemester(val),
          enabled: _logic.selectedYear != null,

        ),
        const SizedBox(height: 12),
        _logic.loadingSections
            ? const CupertinoActivityIndicator()
            : _logic.dynamicSections.isNotEmpty
                ? _buildDropdown(
                    context: context,
                    hint: 'Select Class',
                    value: (_logic.selectedBranch != null && _logic.selectedSection != null)
                        ? '${_logic.selectedBranch} - ${_logic.selectedSection}'
                        : null,
                    items: const [], // Intercepted by gesture
                    onChanged: (v) {},
                    onTapOverride: () => _showTwoColumnPicker(context),
                  )
                : const SizedBox.shrink(),
        if (_errorMessage.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
        const SizedBox(height: 16),
        CupertinoButton(
          onPressed: _logic.isLoading 
            ? null 
            : () async {
                // Wait for the background fetch to complete before proceeding
                final result = await _logic.saveProfile();
                if (result['success'] == true) {
                  widget.onComplete?.call();
                  if (mounted) Navigator.pop(context);
                } else {
                  setState(() => _errorMessage = result['message'] ?? 'Failed to save');
                }
              },
          child: _logic.isLoading 
            ? const CupertinoActivityIndicator()
            : Text('Done', style: TextStyle(color: accent, fontWeight: FontWeight.w600, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required BuildContext context,
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,

    bool enabled = true,
    VoidCallback? onTapOverride,
  }) {
    return GestureDetector(
      onTap: enabled
          ? (onTapOverride ??
              () {
                showCupertinoModalPopup(
                  context: context,
                  builder: (ctx) => Container(
                    height: 250,
                    color: CupertinoColors.systemBackground.resolveFrom(context),
                    child: CupertinoPicker(
                      itemExtent: 32,
                      onSelectedItemChanged: (idx) {
                        onChanged(items[idx]);
                      },
                      children: items.map((i) => Center(child: Text(i))).toList(),
                    ),
                  ),
                );
              })
          : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value ?? hint,
              style: TextStyle(color: value == null ? Colors.grey : Colors.white),
            ),
            const Icon(CupertinoIcons.chevron_down, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess(Color accent) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF10B981).withOpacity(0.2),
          ),
          child: const Icon(CupertinoIcons.checkmark_alt, color: Color(0xFF10B981), size: 40),
        ),
        const SizedBox(height: 16),
        Text(
          'Profile Setup Complete!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
  void _showTwoColumnPicker(BuildContext context) {
    if (_logic.dynamicSections.isEmpty) {
      return;
    }

    final Map<String, Map<String, String>> grouped = {};
    for (final item in _logic.dynamicSections) {
      final match = RegExp(r'^([a-zA-Z\s\-]+?)\s*(\d+)$').firstMatch(item.trim());
      if (match != null) {
        final subject = match.group(1)!.trim();
        final section = match.group(2)!.trim();
        grouped.putIfAbsent(subject, () => {})[section] = item;
      } else {
        final match2 = RegExp(r'^([a-zA-Z]+)-?(\w+)$').firstMatch(item.trim());
        if (match2 != null) {
          final subject = match2.group(1)!.trim();
          final section = match2.group(2)!.trim();
          grouped.putIfAbsent(subject, () => {})[section] = item;
        } else {
          grouped.putIfAbsent(item, () => {})[''] = item;
        }
      }
    }

    final subjects = grouped.keys.toList();
    if (subjects.isEmpty) return;

    int initialSubjectIdx = 0;
    int initialSectionIdx = 0;
    if (_logic.selectedBranch != null && _logic.selectedSection != null) {
      initialSubjectIdx = subjects.indexOf(_logic.selectedBranch!);
      if (initialSubjectIdx != -1) {
        final sections = grouped[_logic.selectedBranch!]!.keys.toList()
          ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
        final sectionKey = sections.firstWhere(
            (k) => grouped[_logic.selectedBranch!]![k] == _logic.selectedSection,
            orElse: () => '');
        initialSectionIdx = sections.indexOf(sectionKey);
        if (initialSectionIdx == -1) initialSectionIdx = 0;
      } else {
        initialSubjectIdx = 0;
      }
    }

    String tempSubject = subjects[initialSubjectIdx];
    List<String> tempSections = grouped[tempSubject]!.keys.toList()
      ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
    String tempSection = tempSections.isNotEmpty ? tempSections[initialSectionIdx] : '';

    if (_logic.selectedBranch == null || _logic.selectedSection == null) {
      final originalValue = grouped[tempSubject]?[tempSection];
      if (originalValue != null) {
        _logic.selectedBranch = tempSubject;
        _logic.selectedSection = originalValue;
        setState(() {});
      }
    }

    showCupertinoModalPopup(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Material(
            child: Container(
              height: 280,
              padding: const EdgeInsets.only(top: 6),
              margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel')),
                          const Text('Select Class',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          CupertinoButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Done', style: TextStyle(color: Color(0xFFFF7A59), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: Colors.grey[400], height: 1, indent: 16, endIndent: 16),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoPicker(
                              magnification: 1.22,
                              squeeze: 1.2,
                              useMagnifier: true,
                              itemExtent: 32.0,
                              scrollController: FixedExtentScrollController(initialItem: initialSubjectIdx),
                              onSelectedItemChanged: (index) {
                                setModalState(() {
                                  tempSubject = subjects[index];
                                  tempSections = grouped[tempSubject]!.keys.toList()
                                    ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
                                  tempSection = tempSections.isNotEmpty ? tempSections[0] : '';
                                });
                                final originalValue = grouped[tempSubject]?[tempSection];
                                if (originalValue != null) {
                                  _logic.selectedBranch = tempSubject;
                                  _logic.selectedSection = originalValue;
                                  setState(() {});
                                }
                              },
                              children: subjects.map((s) => Center(child: Text(s))).toList(),
                            ),
                          ),
                          Expanded(
                            key: ValueKey(tempSubject),
                            child: CupertinoPicker(
                              magnification: 1.22,
                              squeeze: 1.2,
                              useMagnifier: true,
                              itemExtent: 32.0,
                              scrollController: FixedExtentScrollController(
                                  initialItem: tempSections.indexOf(tempSection).clamp(0, tempSections.length - 1)),
                              onSelectedItemChanged: (index) {
                                tempSection = tempSections[index];
                                final originalValue = grouped[tempSubject]?[tempSection];
                                if (originalValue != null) {
                                  _logic.selectedBranch = tempSubject;
                                  _logic.selectedSection = originalValue;
                                  setState(() {});
                                }
                              },
                              children: tempSections.map((s) => Center(child: Text(s))).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class BarsScaleAnimation extends StatefulWidget {
  final Color color;
  const BarsScaleAnimation({super.key, required this.color});

  @override
  State<BarsScaleAnimation> createState() => _BarsScaleAnimationState();
}

class _BarsScaleAnimationState extends State<BarsScaleAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Some emulators freeze animations if duration is 0 or unhandled. 
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    // Use a post frame callback to start the animation to ensure the ticker is fully attached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      width: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(5, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double delay = index * 0.15;
              double progress = (_controller.value - delay);
              if (progress < 0) progress += 1.0;

              double height = 12.0;
              if (progress < 0.5) {
                // scale from 12 up to 24 and back down
                height = 12.0 + (12.0 * sin(progress * 3.14159 / 0.5)); 
              }

              return Container(
                width: 4,
                height: 24,
                alignment: Alignment.center,
                child: Container(
                  width: 4,
                  height: height,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
