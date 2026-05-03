import 'package:flutter/material.dart';
import 'one_ui_scroll_simulation.dart';

class OneUiScrollPhysics extends ScrollPhysics {
  const OneUiScrollPhysics(this.expandedHeight, {super.parent});

  final double expandedHeight;

  @override
  ScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return OneUiScrollPhysics(expandedHeight, parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity.abs() < toleranceFor(position).velocity) ||
        (velocity > 0.0 && position.pixels >= position.maxScrollExtent) ||
        (velocity < 0.0 && position.pixels <= position.minScrollExtent)) {
      return null;
    }
    return OneUiScrollSimulation(
      position: position.pixels,
      velocity: velocity,
      expandedHeight: expandedHeight,
    );
  }
}
