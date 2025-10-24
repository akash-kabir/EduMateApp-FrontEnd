import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AnimatedChevronDown extends StatefulWidget {
  final bool isExpanded;
  final Color? color;
  final double size;
  final AnimationController? controller;

  const AnimatedChevronDown({
    super.key,
    required this.isExpanded,
    this.color,
    this.size = 24.0,
    this.controller,
  });

  @override
  State<AnimatedChevronDown> createState() => _AnimatedChevronDownState();
}

class _AnimatedChevronDownState extends State<AnimatedChevronDown>
    with SingleTickerProviderStateMixin {
  AnimationController? _internalController;

  AnimationController get _controller =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();

    if (widget.controller == null) {
      _internalController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );

      if (widget.isExpanded) {
        _internalController!.value = 1.0;
      }
    }
  }

  @override
  void didUpdateWidget(AnimatedChevronDown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null &&
        widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _internalController!.forward();
      } else {
        _internalController!.reverse();
      }
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chevronColor = widget.color ?? Colors.grey;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final curvedValue = CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ).value;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(pi * curvedValue),
          child: Icon(
            CupertinoIcons.chevron_down,
            color: chevronColor,
            size: widget.size,
          ),
        );
      },
    );
  }
}
