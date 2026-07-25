import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class CompactToastWidget extends StatefulWidget {
  final String message;
  final bool isSuccess;
  final VoidCallback onDismiss;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final Duration? duration;

  const CompactToastWidget({
    super.key,
    required this.message,
    required this.isSuccess,
    required this.onDismiss,
    this.actionLabel,
    this.onActionTap,
    this.duration,
  });

  @override
  State<CompactToastWidget> createState() => _CompactToastWidgetState();
}

class _CompactToastWidgetState extends State<CompactToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isExpanded = false;
  double _pillWidth = 56.0; // Initial compact size matching the circular icon container
  double _pillHeight = 52.0;

  bool _isDoubleLine = false;
  double _targetWidth = 56.0;
  double _targetHeight = 52.0;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slideAnimation = Tween<double>(begin: -80.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOut,
      ),
    );

    // Start entrance animation
    _slideController.forward();

    // Trigger horizontal expansion after 250ms delay
    Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _isExpanded = true;
          _pillWidth = _targetWidth;
          _pillHeight = _targetHeight;
        });
      }
    });

    // Auto-dismiss duration
    Timer(widget.duration ?? const Duration(milliseconds: 3800), () {
      if (mounted) {
        setState(() {
          _isExpanded = false;
          _pillWidth = 56.0;
          _pillHeight = 52.0;
        });
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) {
            _slideController.reverse().then((_) {
              widget.onDismiss();
            });
          }
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final screenWidth = MediaQuery.of(context).size.width;
    final maxAllowedWidth = screenWidth > 600 ? 360.0 : screenWidth - 32.0;
    final maxTextWidth = maxAllowedWidth - 72.0; // 50px icon container + 22px padding

    // Calculate layout to check if double line is needed
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.message,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14.0,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
      ),
      maxLines: 2,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxTextWidth);
    
    double actionWidth = widget.actionLabel != null ? 80.0 : 0.0;
    _isDoubleLine = textPainter.height > 22.0;
    _targetWidth = (textPainter.width + 72.0 + actionWidth).clamp(56.0, maxAllowedWidth);
    _targetHeight = _isDoubleLine ? 68.0 : 52.0;
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isSuccess 
        ? const Color(0xFF10B981) // Emerald Green
        : const Color(0xFFEF4444); // Modern Red

    final glowColor = widget.isSuccess
        ? const Color(0xFF10B981).withOpacity(0.15)
        : const Color(0xFFEF4444).withOpacity(0.15);

    final iconData = widget.isSuccess 
        ? Icons.check_circle_rounded 
        : Icons.error_rounded;

    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 16.0 + _slideAnimation.value,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                width: _pillWidth,
                height: _pillHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 20.0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
                    child: Material(
                      type: MaterialType.transparency,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B).withOpacity(0.40), // Premium high translucency (40% opacity)
                          borderRadius: BorderRadius.circular(26.0),
                        ),
                        child: Row(
                          children: [
                            // Left indicator: Icon Container with subtle radial accent glow
                            Container(
                              width: 50.0,
                              height: 50.0,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: glowColor,
                                    blurRadius: 10.0,
                                    spreadRadius: 2.0,
                                  ),
                                ],
                              ),
                              child: Icon(
                                iconData,
                                color: accentColor,
                                size: 24.0,
                              ),
                            ),
                            // Expandable message text segment supporting up to 2 lines
                            Expanded(
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 150),
                                opacity: _isExpanded ? 1.0 : 0.0,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 20.0),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      widget.message,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: _isExpanded ? (_isDoubleLine ? 2 : 1) : 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (widget.actionLabel != null)
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 150),
                                opacity: _isExpanded ? 1.0 : 0.0,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: GestureDetector(
                                    onTap: widget.onActionTap,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                      child: Text(
                                        widget.actionLabel!,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.w700,
                                          color: accentColor,
                                        ),
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
              ),
            ),
          ),
        );
      },
    );
  }
}
