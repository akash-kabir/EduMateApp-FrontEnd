import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../widgets/custom_glass_dialog.dart';
import '../../constants/app_constants.dart';
import '../../widgets/toast_manager.dart';
import 'profile_setup_logic.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String? userId;
  final String? token;
  final VoidCallback? onProfileSetupComplete;

  const ProfileSetupScreen({
    super.key,
    this.userId,
    this.token,
    this.onProfileSetupComplete,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late final ProfileSetupLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = ProfileSetupLogic(
      userId: widget.userId,
      token: widget.token,
      onKiitEmailPrefilled: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showKiitPreFillDialog();
          }
        });
      },
    );
    _logic.addListener(_onLogicChange);
  }

  void _onLogicChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _logic.removeListener(_onLogicChange);
    _logic.dispose();
    super.dispose();
  }

  void _showKiitPreFillDialog() {
    showGlassmorphicDialog(
      context: context,
      barrierDismissible: false,
      child: Material(
        color: Colors.transparent,
        child: Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64.0,
                  height: 64.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AuthPalette.coral.withOpacity(0.15),
                    border: Border.all(
                      color: AuthPalette.coral.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.checkmark_seal_fill,
                    color: AuthPalette.coral,
                    size: 32.0,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Details Pre-filled',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "We've automatically filled in your details based on your KIIT email address.",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14.0,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AuthPalette.coral.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Please select your Branch and Semester to complete.',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AuthPalette.coral,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuthPalette.coral,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _submitProfile() async {
    final result = await _logic.saveProfile();
    if (mounted) {
      if (result['success'] == true) {
        EduMateToast.showCompact(
          context,
          message: 'Profile saved successfully!',
          isSuccess: true,
        );
        widget.onProfileSetupComplete?.call();
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        EduMateToast.showCompact(
          context,
          message: result['message'] ?? 'Failed to save profile',
          isSuccess: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F0F11) : const Color(0xFFFAFAFA),
        ),
        child: Stack(
          children: [
            // Ambient glowing orbs
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AuthPalette.coral.withOpacity(isDark ? 0.15 : 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AuthPalette.coral.withOpacity(isDark ? 0.1 : 0.05),
                ),
              ),
            ),
            // Blur layer
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
            ),
            CupertinoPageScaffold(
              backgroundColor: Colors.transparent,
              navigationBar: CupertinoNavigationBar(
                middle: const Text('Complete Your Profile'),
                backgroundColor: isDark
                    ? const Color(0xFF0F0F11).withOpacity(0.65)
                    : Colors.white.withOpacity(0.65),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12,
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Provide your academic details to get started',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // First Name & Last Name
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'First Name',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  CupertinoTextField(
                                    controller: _logic.firstNameController,
                                    placeholder: 'First name',
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                                    ),
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                    placeholderStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Last Name',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  CupertinoTextField(
                                    controller: _logic.lastNameController,
                                    placeholder: 'Last name',
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                                    ),
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                    placeholderStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Roll Number Input
                        Text(
                          'Roll Number',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CupertinoTextField(
                          controller: _logic.rollNoController,
                          placeholder: 'Enter your roll number',
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                          ),
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          placeholderStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                        ),
                        const SizedBox(height: 24),
                        // Year and Semester side by side
                        Row(
                          children: [
                            // Year Dropdown
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Year',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildDropdown(
                                    context,
                                    hint: 'Select',
                                    value: _logic.selectedYear,
                                    items: ProfileSetupConstants.academicYears,
                                    onChanged: (value) {
                                      _logic.selectedYear = value;
                                      _logic.updateSemester(null);
                                    },
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Semester Dropdown
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Semester',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildDropdown(
                                    context,
                                    hint: 'Select',
                                    value: _logic.selectedSemester,
                                    items: ProfileSetupConstants.semestersByYear[_logic.selectedYear] ?? [],
                                    onChanged: (value) {
                                      _logic.updateSemester(value);
                                    },
                                    isDark: isDark,
                                    enabled: _logic.selectedYear != null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Class & Section Picker
                        Row(
                          children: [
                            Text(
                              'Branch & Section',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            if (_logic.loadingSections) ...[
                              const SizedBox(width: 8),
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Material(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: (_logic.selectedSemester != null && !_logic.loadingSections)
                                ? () => _showTwoColumnPicker(context, isDark)
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _logic.selectedBranch != null && _logic.selectedSection != null
                                          ? _logic.selectedSection!
                                          : (_logic.loadingSections ? 'Loading...' : 'Select your class'),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _logic.selectedBranch != null && _logic.selectedSection != null
                                            ? (isDark ? Colors.white : Colors.black)
                                            : (isDark ? Colors.grey[500] : Colors.grey[400]),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    CupertinoIcons.chevron_down,
                                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Submit Button
                        CupertinoButton(
                          onPressed: _logic.isLoading ? null : _submitProfile,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _logic.isLoading ? (isDark ? Colors.grey[800] : Colors.grey[300]) : AuthPalette.coral,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _logic.isLoading
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: AuthPalette.coral.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: _logic.isLoading
                                  ? const SizedBox(
                                      height: 15,
                                      width: 20,
                                      child: CupertinoActivityIndicator(color: Colors.white),
                                    )
                                  : Text(
                                      'Complete Setup',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isDark,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled
          ? () async {
              FocusManager.instance.primaryFocus?.unfocus();
              await Future.delayed(const Duration(milliseconds: 50));
              if (!context.mounted) return;

              int initialIndex = value != null ? items.indexOf(value).clamp(0, items.length - 1) : 0;
              if (items.isNotEmpty && value == null) {
                onChanged(items[initialIndex]);
              }

              showCupertinoModalPopup(
                context: context,
                builder: (context) => Material(
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
                                  child: const Text('Cancel'),
                                ),
                                Text(
                                  hint,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                CupertinoButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Done'),
                                ),
                              ],
                            ),
                          ),
                          Divider(color: Colors.grey[400], height: 1, indent: 16, endIndent: 16),
                          Expanded(
                            child: CupertinoPicker(
                              magnification: 1.22,
                              squeeze: 1.2,
                              useMagnifier: true,
                              itemExtent: 32.0,
                              scrollController: FixedExtentScrollController(
                                initialItem: initialIndex,
                              ),
                              onSelectedItemChanged: (index) {
                                onChanged(items[index]);
                              },
                              children: items.map((item) => Center(child: Text(item))).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: enabled
                    ? (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1))
                    : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
              ),
              borderRadius: BorderRadius.circular(12),
              color: enabled
                  ? (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03))
                  : (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value ?? hint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: value == null
                        ? (enabled ? (isDark ? Colors.grey[500] : Colors.grey[400]) : (isDark ? Colors.grey[700] : Colors.grey[300]))
                        : (isDark ? Colors.white : Colors.black),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_down,
                  color: enabled ? (isDark ? Colors.grey[500] : Colors.grey[400]) : (isDark ? Colors.grey[700] : Colors.grey[300]),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTwoColumnPicker(BuildContext context, bool isDark) {
    if (_logic.dynamicSections.isEmpty) {
      EduMateToast.showCompact(context, message: 'No classes found for this semester', isSuccess: false);
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
        final sections = grouped[_logic.selectedBranch!]!.keys.toList()..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
        // Find the key in the grouped map where the value matches selectedSection
        final sectionKey = sections.firstWhere((k) => grouped[_logic.selectedBranch!]![k] == _logic.selectedSection, orElse: () => '');
        initialSectionIdx = sections.indexOf(sectionKey);
        if (initialSectionIdx == -1) initialSectionIdx = 0;
      } else {
        initialSubjectIdx = 0;
      }
    }

    String tempSubject = subjects[initialSubjectIdx];
    List<String> tempSections = grouped[tempSubject]!.keys.toList()..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
    String tempSection = tempSections.isNotEmpty ? tempSections[initialSectionIdx] : '';

    if (_logic.selectedBranch == null || _logic.selectedSection == null) {
      final originalValue = grouped[tempSubject]?[tempSection];
      if (originalValue != null) {
        _logic.selectedBranch = tempSubject;
        _logic.selectedSection = originalValue;
        _onLogicChange();
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
                            onPressed: () {
                              // If cancelled, we should ideally revert, but simple picker behaves like iOS native (auto-saves)
                              Navigator.pop(context);
                            }, 
                            child: const Text('Cancel')
                          ),
                          const Text('Select Class', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          CupertinoButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Done'),
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
                                  tempSections = grouped[tempSubject]!.keys.toList()..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
                                  tempSection = tempSections.isNotEmpty ? tempSections[0] : '';
                                });
                                // Apply immediately
                                final originalValue = grouped[tempSubject]?[tempSection];
                                if (originalValue != null) {
                                  _logic.selectedBranch = tempSubject;
                                  _logic.selectedSection = originalValue;
                                  _onLogicChange();
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
                              scrollController: FixedExtentScrollController(initialItem: tempSections.indexOf(tempSection).clamp(0, tempSections.length - 1)),
                              onSelectedItemChanged: (index) {
                                tempSection = tempSections[index];
                                // Apply immediately
                                final originalValue = grouped[tempSubject]?[tempSection];
                                if (originalValue != null) {
                                  _logic.selectedBranch = tempSubject;
                                  _logic.selectedSection = originalValue;
                                  _onLogicChange();
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
