import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

typedef DropdownOverlayEntryAnimationBuilder = Widget Function(Widget);

abstract class DropdownOverlayEntryAnimations {
  static DropdownOverlayEntryAnimation fade({
    Duration duration = const Duration(milliseconds: 200),
    Curve curve = Curves.easeInOutCubic,
  }) =>
      DropdownOverlayEntryAnimation(
        duration,
        (child) {
          return AnimatedSwitcher(
            duration: duration,
            switchInCurve: curve,
            switchOutCurve: curve,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            layoutBuilder: _layoutBuilder,
            child: child,
          );
        },
      );

  static DropdownOverlayEntryAnimation dropDown({
    Duration duration = const Duration(milliseconds: 200),
    Curve curve = Curves.easeInOutCubic,
  }) =>
      DropdownOverlayEntryAnimation(
        duration,
        (child) => Transform.translate(
          offset: Offset(-16, -16),
          child: AnimatedSwitcher(
            duration: duration,
            switchInCurve: curve,
            switchOutCurve: curve,
            transitionBuilder: (child, animation) => SizeTransition(
              axisAlignment: -1,
              sizeFactor: animation,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: child,
              ),
            ),
            layoutBuilder: _layoutBuilder,
            child: child,
          ),
        ),
      );

  static Widget _layoutBuilder(Widget? currentChild, List<Widget> previousChildren) {
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        ...previousChildren,
        if (currentChild != null) currentChild,
      ],
    );
  }
}

class DropdownOverlayEntryAnimation {
  final Duration duration;
  final DropdownOverlayEntryAnimationBuilder builder;

  DropdownOverlayEntryAnimation(this.duration, this.builder);
}
