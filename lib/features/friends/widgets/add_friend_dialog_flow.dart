import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app/features/friends/models/friend_model.dart';
import 'package:app/features/friends/services/friends_storage_service.dart';
import 'package:app/shared/services/student_data_service.dart';
import 'package:app/theme/theme.dart';

enum AddFriendStep {
  enterDetails,
  sending,
  receiving,
  success,
  error,
}

class AddFriendDialogFlow extends StatefulWidget {
  final VoidCallback? onComplete;

  const AddFriendDialogFlow({super.key, this.onComplete});

  @override
  State<AddFriendDialogFlow> createState() => _AddFriendDialogFlowState();
}

class _AddFriendDialogFlowState extends State<AddFriendDialogFlow> with TickerProviderStateMixin {
  final _rollNoController = TextEditingController();
  final _nameTagController = TextEditingController();
  AddFriendStep _currentStep = AddFriendStep.enterDetails;
  String _errorMessage = '';

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
  }

  Future<void> _setStep(AddFriendStep step) async {
    await _fadeController.reverse();
    if (!mounted) return;
    setState(() => _currentStep = step);
    _fadeController.forward();
  }

  Future<void> _startSearch() async {
    final rollNo = _rollNoController.text.trim();
    final nameTag = _nameTagController.text.trim();

    if (rollNo.isEmpty || nameTag.isEmpty) {
      setState(() => _errorMessage = 'Please enter Roll Number and Name Tag.');
      return;
    }

    _setStep(AddFriendStep.sending);

    // Simulate sending animation
    await Future.delayed(const Duration(milliseconds: 1500));
    
    final result = await StudentDataService.lookupRollNo(rollNo);
    
    if (!mounted) return;

    if (result['success'] == true && result['data'] != null) {
      _setStep(AddFriendStep.receiving);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;

      final data = result['data'];
      List<String> friendElectives = [];
      if (data['electives'] is List) {
        friendElectives = List<String>.from((data['electives'] as List).map((e) => e.toString()));
      }

      final friend = FriendModel(
        rollNo: data['rollNo'] ?? rollNo,
        nameTag: nameTag,
        semester: data['semester'] ?? '',
        section: data['section'] ?? '',
        electives: friendElectives,
      );

      final added = await FriendsStorageService.addFriend(friend);
      
      if (!mounted) return;

      if (added) {
        _setStep(AddFriendStep.success);
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          widget.onComplete?.call();
          Navigator.pop(context);
        }
      } else {
        setState(() => _errorMessage = 'Could not add friend. They might already exist.');
        _setStep(AddFriendStep.error);
      }
    } else {
      setState(() => _errorMessage = result['message'] ?? 'Roll number not found');
      _setStep(AddFriendStep.error);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _rollNoController.dispose();
    _nameTagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = AuthPalette.coral; // using coral for friends

    return PopScope(
      canPop: false, // Prevent dismissing while loading
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: FadeTransition(
          opacity: _fadeController,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4, // Strictly limit to 40% of screen to avoid keyboard overflow
            ),
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
      ),
    );
  }

  Widget _buildCurrentStep(Color accent) {
    switch (_currentStep) {
      case AddFriendStep.enterDetails:
        return _buildEnterDetails(accent);
      case AddFriendStep.sending:
        return _buildAnimationState(accent, sending: true);
      case AddFriendStep.receiving:
        return _buildAnimationState(accent, sending: false);
      case AddFriendStep.success:
        return _buildSuccess();
      case AddFriendStep.error:
        return _buildError(accent);
    }
  }

  Widget _buildEnterDetails(Color accent) {
    return Column(
      children: [
        const Text(
          'Add Friend',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        CupertinoTextField(
          controller: _rollNoController,
          placeholder: 'Roll Number (e.g., 2405001)',
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
        CupertinoTextField(
          controller: _nameTagController,
          placeholder: 'Name Tag (e.g., John)',
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        if (_errorMessage.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Center(
                    child: Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _startSearch,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimationState(Color accent, {required bool sending}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.globe, size: 40, color: Colors.white70),
            const SizedBox(width: 20),
            _BarsScaleAnimation(color: accent),
            const SizedBox(width: 20),
            const Icon(CupertinoIcons.device_phone_portrait, size: 40, color: Colors.white70),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          sending ? 'Fetching Friend...' : 'Found! Adding...',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF10B981).withValues(alpha: 0.2),
          ),
          child: const Icon(CupertinoIcons.checkmark_alt, color: Color(0xFF10B981), size: 40),
        ),
        const SizedBox(height: 16),
        const Text(
          'Friend Added!',
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

  Widget _buildError(Color accent) {
    return Column(
      children: [
        const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.orange, size: 40),
        const SizedBox(height: 16),
        const Text(
          'Could not add friend',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
        ),
        const SizedBox(height: 20),
        CupertinoButton(
          onPressed: () => _setStep(AddFriendStep.enterDetails),
          child: Text('Try Again', style: TextStyle(color: accent, fontWeight: FontWeight.w600, fontSize: 16)),
        ),
      ],
    );
  }
}

class _BarsScaleAnimation extends StatefulWidget {
  final Color color;
  const _BarsScaleAnimation({required this.color});

  @override
  State<_BarsScaleAnimation> createState() => _BarsScaleAnimationState();
}

class _BarsScaleAnimationState extends State<_BarsScaleAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
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
