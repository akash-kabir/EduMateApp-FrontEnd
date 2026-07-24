import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../widgets/toast_manager.dart';
import 'profile_setup_logic.dart';

/// Multi-step profile setup screen with roll-number auto-detection and lookup.
///
/// Steps:
///   0 - Welcome / "Set Up Profile"
///   1 - Roll Number Detection / Entry
///   2 - Searching for Data (animated)
///   3a - Auto-populated results → Confirm & Save
///   3b - Manual fallback → Dropdowns → Complete Setup
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

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with TickerProviderStateMixin {
  late final ProfileSetupLogic _logic;

  // 0=welcome, 1=rollNo, 2=searching, 3=results/manual
  int _currentStep = 0;

  // For manual fallback
  bool _isManualMode = false;

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _logic = ProfileSetupLogic(
      userId: widget.userId,
      token: widget.token,
    );
    _logic.addListener(_onLogicChange);

    _fadeController.forward();
  }

  void _onLogicChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _logic.removeListener(_onLogicChange);
    _logic.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // Transition to the next step with a fade animation
  void _goToStep(int step) {
    _fadeController.reverse().then((_) {
      if (mounted) {
        setState(() => _currentStep = step);
        _fadeController.forward();
      }
    });
  }

  // Roll number detected or entered → search
  Future<void> _onRollNoSubmit() async {
    final rollNo = _logic.rollNoController.text.trim();
    if (rollNo.isEmpty) {
      EduMateToast.showCompact(context,
          message: 'Please enter your roll number', isSuccess: false);
      return;
    }
    _goToStep(2); // searching
    await Future.delayed(const Duration(milliseconds: 600));

    final found = await _logic.autoSetupFromRollNo(rollNo);

    if (mounted) {
      if (found) {
        _goToStep(3); // results
        _isManualMode = false;
      } else {
        _isManualMode = true;
        _goToStep(3); // manual fallback
      }
    }
  }

  Future<void> _submitProfile() async {
    final result = await _logic.saveProfile();
    if (mounted) {
      if (result['success'] == true) {
        EduMateToast.showCompact(context,
            message: 'Profile saved successfully!', isSuccess: true);
        widget.onProfileSetupComplete?.call();
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.pop(context);
      } else {
        EduMateToast.showCompact(context,
            message: result['message'] ?? 'Failed to save profile',
            isSuccess: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = AuthPalette.coral;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F0F11) : const Color(0xFFFAFAFA),
        ),
        child: Stack(
          children: [
            // Ambient orbs
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(isDark ? 0.15 : 0.08),
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
                  color: accentColor.withOpacity(isDark ? 0.1 : 0.05),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
            ),
            CupertinoPageScaffold(
              backgroundColor: Colors.transparent,
              navigationBar: CupertinoNavigationBar(
                middle: Text(
                  _currentStep == 0
                      ? 'Profile Setup'
                      : _currentStep == 1
                          ? 'Roll Number'
                          : _currentStep == 2
                              ? 'Searching...'
                              : _isManualMode
                                  ? 'Complete Your Profile'
                                  : 'Your Details',
                ),
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
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildCurrentStep(isDark, accentColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(bool isDark, Color accent) {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep(isDark, accent);
      case 1:
        return _buildRollNoStep(isDark, accent);
      case 2:
        return _buildSearchingStep(isDark, accent);
      case 3:
        return _isManualMode
            ? _buildManualStep(isDark, accent)
            : _buildAutoResultStep(isDark, accent);
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── STEP 0: Welcome ─────────────────────────────────────────────────────────
  Widget _buildWelcomeStep(bool isDark, Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [accent.withOpacity(0.2), accent.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                    color: accent.withOpacity(0.3), width: 2),
              ),
              child: Icon(CupertinoIcons.person_crop_circle,
                  color: accent, size: 50),
            ),
            const SizedBox(height: 32),
            Text(
              'Welcome to EduMate',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Let\'s set up your profile so we can personalise your timetable, schedule, and campus experience.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildPrimaryButton(
              label: 'Set Up Profile',
              accent: accent,
              onPressed: () => _goToStep(1),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  // ─── STEP 1: Roll Number Detection / Entry ───────────────────────────────────
  Widget _buildRollNoStep(bool isDark, Color accent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // First name / last name row
          Row(
            children: [
              Expanded(
                child: _buildLabeledField(
                  context,
                  label: 'First Name',
                  isDark: isDark,
                  child: CupertinoTextField(
                    controller: _logic.firstNameController,
                    placeholder: 'First name',
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: _inputDecoration(isDark),
                    style:
                        TextStyle(color: isDark ? Colors.white : Colors.black),
                    placeholderStyle: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[400]),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLabeledField(
                  context,
                  label: 'Last Name',
                  isDark: isDark,
                  child: CupertinoTextField(
                    controller: _logic.lastNameController,
                    placeholder: 'Last name',
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: _inputDecoration(isDark),
                    style:
                        TextStyle(color: isDark ? Colors.white : Colors.black),
                    placeholderStyle: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[400]),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Roll number detection banner
          if (_logic.isKiitEmail && _logic.detectedRollNo != null) ...[
            _buildDetectedBanner(isDark, accent),
            const SizedBox(height: 20),
          ],

          _buildLabeledField(
            context,
            label: 'Roll Number',
            isDark: isDark,
            child: CupertinoTextField(
              controller: _logic.rollNoController,
              placeholder: 'e.g. 2105001',
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: _inputDecoration(isDark),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              placeholderStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[400]),
              keyboardType: TextInputType.text,
              readOnly: _logic.isKiitEmail,
            ),
          ),

          if (!_logic.isKiitEmail) ...[
            const SizedBox(height: 8),
            Text(
              'Enter the roll number from your KIIT ID card.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 36),
          _buildPrimaryButton(
            label: 'Search for Data',
            accent: accent,
            onPressed: _onRollNoSubmit,
            isDark: isDark,
            icon: CupertinoIcons.search,
          ),
          const SizedBox(height: 16),
          Center(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                _isManualMode = true;
                _goToStep(3);
              },
              child: Text(
                'Set up manually instead',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                  decorationColor: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedBanner(bool isDark, Color accent) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF10B981).withOpacity(isDark ? 0.15 : 0.1),
            border: Border.all(
              color: const Color(0xFF10B981).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withOpacity(0.2),
                ),
                child: const Icon(CupertinoIcons.checkmark_seal_fill,
                    color: Color(0xFF10B981), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Roll No Detected',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'From your KIIT email: ${_logic.detectedRollNo}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
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
  }

  // ─── STEP 2: Searching ────────────────────────────────────────────────────────
  Widget _buildSearchingStep(bool isDark, Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _pulseAnimation.value,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withOpacity(0.1),
                      border:
                          Border.all(color: accent.withOpacity(0.3), width: 2),
                    ),
                    child: Icon(CupertinoIcons.search,
                        color: accent, size: 40),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            Text(
              'Searching for your data...',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Looking up roll number ${_logic.rollNoController.text.trim()} in the student database.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const CupertinoActivityIndicator(radius: 14),
          ],
        ),
      ),
    );
  }

  // ─── STEP 3a: Auto Result ─────────────────────────────────────────────────────
  Widget _buildAutoResultStep(bool isDark, Color accent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Success banner
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFF10B981).withOpacity(isDark ? 0.12 : 0.08),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF10B981).withOpacity(0.2),
                      ),
                      child: const Icon(CupertinoIcons.checkmark_alt_circle_fill,
                          color: Color(0xFF10B981), size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data Found!',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your academic details have been auto-populated.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
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
          const SizedBox(height: 28),

          // Detail cards
          _buildDetailRow(isDark, 'Roll Number', _logic.rollNoController.text, CupertinoIcons.number),
          _buildDetailRow(isDark, 'Year', _logic.selectedYear ?? '-', CupertinoIcons.calendar),
          _buildDetailRow(isDark, 'Semester', _logic.selectedSemester ?? '-', CupertinoIcons.book),
          _buildDetailRow(isDark, 'Branch', _logic.selectedBranch ?? '-', CupertinoIcons.building_2_fill),
          _buildDetailRow(isDark, 'Section', _logic.selectedSection ?? '-', CupertinoIcons.person_2),
          if (_logic.detectedElectives.isNotEmpty)
            _buildDetailRow(isDark, 'Electives', _logic.detectedElectives.join(', '), CupertinoIcons.square_list),

          const SizedBox(height: 32),
          _buildPrimaryButton(
            label: _logic.isLoading ? '' : 'Confirm & Save',
            accent: accent,
            onPressed: _logic.isLoading ? null : _submitProfile,
            isDark: isDark,
            isLoading: _logic.isLoading,
          ),
          const SizedBox(height: 14),
          Center(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                _isManualMode = true;
                _goToStep(3);
              },
              child: Text(
                'Edit manually',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                  decorationColor: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(bool isDark, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.03),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
              ),
            ),
            child: Row(
              children: [
                Icon(icon,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
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
    );
  }

  // ─── STEP 3b: Manual Fallback ─────────────────────────────────────────────────
  Widget _buildManualStep(bool isDark, Color accent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          if (_logic.autoSetupError != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.orange.withOpacity(isDark ? 0.12 : 0.08),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.exclamationmark_triangle_fill,
                          color: Colors.orange, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Could not find your data. Please set up manually.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.orange[200] : Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            'Provide your academic details',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          // First Name & Last Name
          Row(
            children: [
              Expanded(
                child: _buildLabeledField(
                  context,
                  label: 'First Name',
                  isDark: isDark,
                  child: CupertinoTextField(
                    controller: _logic.firstNameController,
                    placeholder: 'First name',
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: _inputDecoration(isDark),
                    style:
                        TextStyle(color: isDark ? Colors.white : Colors.black),
                    placeholderStyle: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[400]),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLabeledField(
                  context,
                  label: 'Last Name',
                  isDark: isDark,
                  child: CupertinoTextField(
                    controller: _logic.lastNameController,
                    placeholder: 'Last name',
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: _inputDecoration(isDark),
                    style:
                        TextStyle(color: isDark ? Colors.white : Colors.black),
                    placeholderStyle: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[400]),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Roll Number
          _buildLabeledField(
            context,
            label: 'Roll Number',
            isDark: isDark,
            child: CupertinoTextField(
              controller: _logic.rollNoController,
              placeholder: 'Enter your roll number',
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: _inputDecoration(isDark),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              placeholderStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[400]),
            ),
          ),
          const SizedBox(height: 24),
          // Year and Semester
          Row(
            children: [
              Expanded(
                child: _buildLabeledField(
                  context,
                  label: 'Year',
                  isDark: isDark,
                  child: _buildDropdown(
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
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLabeledField(
                  context,
                  label: 'Semester',
                  isDark: isDark,
                  child: _buildDropdown(
                    context,
                    hint: 'Select',
                    value: _logic.selectedSemester,
                    items: ProfileSetupConstants
                            .semestersByYear[_logic.selectedYear] ??
                        [],
                    onChanged: (value) => _logic.updateSemester(value),
                    isDark: isDark,
                    enabled: _logic.selectedYear != null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Branch & Section
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
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: (_logic.selectedSemester != null &&
                      !_logic.loadingSections)
                  ? () => _showTwoColumnPicker(context, isDark)
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _logic.selectedBranch != null &&
                                _logic.selectedSection != null
                            ? _logic.selectedSection!
                            : (_logic.loadingSections
                                ? 'Loading...'
                                : 'Select your class'),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _logic.selectedBranch != null &&
                                  _logic.selectedSection != null
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[400]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(CupertinoIcons.chevron_down,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                        size: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          _buildPrimaryButton(
            label: _logic.isLoading ? '' : 'Complete Setup',
            accent: accent,
            onPressed: _logic.isLoading ? null : _submitProfile,
            isDark: isDark,
            isLoading: _logic.isLoading,
          ),
        ],
      ),
    );
  }

  // ─── Shared Widgets ───────────────────────────────────────────────────────────

  Widget _buildLabeledField(BuildContext context,
      {required String label, required bool isDark, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  BoxDecoration _inputDecoration(bool isDark) {
    return BoxDecoration(
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.1),
      ),
      borderRadius: BorderRadius.circular(12),
      color: isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.03),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required Color accent,
    required bool isDark,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: onPressed == null
              ? (isDark ? Colors.grey[800] : Colors.grey[300])
              : accent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: onPressed == null
              ? []
              : [
                  BoxShadow(
                    color: accent.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 15,
                  width: 20,
                  child: CupertinoActivityIndicator(color: Colors.white),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ─── Dropdown & Two Column Picker (kept from original) ────────────────────────

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

              int initialIndex = value != null
                  ? items.indexOf(value).clamp(0, items.length - 1)
                  : 0;
              if (items.isNotEmpty && value == null) {
                onChanged(items[initialIndex]);
              }

              showCupertinoModalPopup(
                context: context,
                builder: (context) => Material(
                  child: Container(
                    height: 280,
                    padding: const EdgeInsets.only(top: 6),
                    margin: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom),
                    color: CupertinoColors.systemBackground
                        .resolveFrom(context),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                CupertinoButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                Text(hint,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                                CupertinoButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Done'),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                              color: Colors.grey[400],
                              height: 1,
                              indent: 16,
                              endIndent: 16),
                          Expanded(
                            child: CupertinoPicker(
                              magnification: 1.22,
                              squeeze: 1.2,
                              useMagnifier: true,
                              itemExtent: 32.0,
                              scrollController:
                                  FixedExtentScrollController(
                                      initialItem: initialIndex),
                              onSelectedItemChanged: (index) {
                                onChanged(items[index]);
                              },
                              children: items
                                  .map((item) =>
                                      Center(child: Text(item)))
                                  .toList(),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: enabled
                    ? (isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1))
                    : (isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05)),
              ),
              borderRadius: BorderRadius.circular(12),
              color: enabled
                  ? (isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03))
                  : (isDark
                      ? Colors.white.withOpacity(0.02)
                      : Colors.black.withOpacity(0.01)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value ?? hint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: value == null
                            ? (enabled
                                ? (isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[400])
                                : (isDark
                                    ? Colors.grey[700]
                                    : Colors.grey[300]))
                            : (isDark ? Colors.white : Colors.black),
                      ),
                ),
                Icon(
                  CupertinoIcons.chevron_down,
                  color: enabled
                      ? (isDark ? Colors.grey[500] : Colors.grey[400])
                      : (isDark ? Colors.grey[700] : Colors.grey[300]),
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
      EduMateToast.showCompact(context,
          message: 'No classes found for this semester', isSuccess: false);
      return;
    }

    final Map<String, Map<String, String>> grouped = {};
    for (final item in _logic.dynamicSections) {
      final match =
          RegExp(r'^([a-zA-Z\s\-]+?)\s*(\d+)$').firstMatch(item.trim());
      if (match != null) {
        final subject = match.group(1)!.trim();
        final section = match.group(2)!.trim();
        grouped.putIfAbsent(subject, () => {})[section] = item;
      } else {
        final match2 =
            RegExp(r'^([a-zA-Z]+)-?(\w+)$').firstMatch(item.trim());
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
          ..sort((a, b) =>
              (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
        final sectionKey = sections.firstWhere(
            (k) =>
                grouped[_logic.selectedBranch!]![k] ==
                _logic.selectedSection,
            orElse: () => '');
        initialSectionIdx = sections.indexOf(sectionKey);
        if (initialSectionIdx == -1) initialSectionIdx = 0;
      } else {
        initialSubjectIdx = 0;
      }
    }

    String tempSubject = subjects[initialSubjectIdx];
    List<String> tempSections = grouped[tempSubject]!.keys.toList()
      ..sort(
          (a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
    String tempSection =
        tempSections.isNotEmpty ? tempSections[initialSectionIdx] : '';

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
              margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              color:
                  CupertinoColors.systemBackground.resolveFrom(context),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                              onPressed: () =>
                                  Navigator.pop(context),
                              child: const Text('Cancel')),
                          const Text('Select Class',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          CupertinoButton(
                            onPressed: () =>
                                Navigator.pop(context),
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                        color: Colors.grey[400],
                        height: 1,
                        indent: 16,
                        endIndent: 16),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoPicker(
                              magnification: 1.22,
                              squeeze: 1.2,
                              useMagnifier: true,
                              itemExtent: 32.0,
                              scrollController:
                                  FixedExtentScrollController(
                                      initialItem:
                                          initialSubjectIdx),
                              onSelectedItemChanged: (index) {
                                setModalState(() {
                                  tempSubject = subjects[index];
                                  tempSections = grouped[
                                          tempSubject]!
                                      .keys
                                      .toList()
                                    ..sort((a, b) =>
                                        (int.tryParse(a) ?? 0)
                                            .compareTo(
                                                int.tryParse(b) ??
                                                    0));
                                  tempSection =
                                      tempSections.isNotEmpty
                                          ? tempSections[0]
                                          : '';
                                });
                                final originalValue = grouped[
                                    tempSubject]?[tempSection];
                                if (originalValue != null) {
                                  _logic.selectedBranch =
                                      tempSubject;
                                  _logic.selectedSection =
                                      originalValue;
                                  _onLogicChange();
                                }
                              },
                              children: subjects
                                  .map((s) =>
                                      Center(child: Text(s)))
                                  .toList(),
                            ),
                          ),
                          Expanded(
                            key: ValueKey(tempSubject),
                            child: CupertinoPicker(
                              magnification: 1.22,
                              squeeze: 1.2,
                              useMagnifier: true,
                              itemExtent: 32.0,
                              scrollController:
                                  FixedExtentScrollController(
                                      initialItem: tempSections
                                          .indexOf(tempSection)
                                          .clamp(
                                              0,
                                              tempSections.length -
                                                  1)),
                              onSelectedItemChanged: (index) {
                                tempSection =
                                    tempSections[index];
                                final originalValue = grouped[
                                    tempSubject]?[tempSection];
                                if (originalValue != null) {
                                  _logic.selectedBranch =
                                      tempSubject;
                                  _logic.selectedSection =
                                      originalValue;
                                  _onLogicChange();
                                }
                              },
                              children: tempSections
                                  .map((s) =>
                                      Center(child: Text(s)))
                                  .toList(),
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
