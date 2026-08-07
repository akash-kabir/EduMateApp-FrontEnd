import 'package:flutter/material.dart';

class CappedBouncingScrollPhysics extends BouncingScrollPhysics {
  final double maxOverscroll;

  const CappedBouncingScrollPhysics({
    this.maxOverscroll = 120.0,
    super.parent,
  });

  @override
  CappedBouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CappedBouncingScrollPhysics(
      maxOverscroll: maxOverscroll,
      parent: buildParent(ancestor),
    );
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // If we are already overscrolled past the max limit at the top edge
    if (position.pixels <= -maxOverscroll && offset > 0) {
      return 0.0; // Stop allowing further pull down
    }
    return super.applyPhysicsToUserOffset(position, offset);
  }
}
