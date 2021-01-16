import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gm5_utils/gm5_utils.dart';

typedef DropdownOverlayentryButtonBuilder = Widget Function(BuildContext context, GlobalKey key, bool isOpen);
typedef DropdownOverlayentryBuilder = Widget Function(BuildContext context, Rect buttonRect);
typedef DropdownOverlayentryAlignment = Offset Function(Rect buttonRect);
enum DropdownOverlayEntryRepositionType { debounceAnimate, throttle, always }

class DropdownOverlayEntry extends StatefulWidget {
  final DropdownOverlayentryButtonBuilder triggerBuilder;
  final DropdownOverlayentryBuilder dropdownBuilder;

  /// determines whether the dropdown content is rebuilt with the button
  /// if set to false, the dropdown won't resize with the button without calling the rebuild() method
  /// usually this is set to false only for performance optimizations
  final bool autoRebuild;

  /// if true, there's no need to manually call updatePosition()
  final bool autoReposition;

  final DropdownOverlayEntryRepositionType repositionType;

  /// calculating position from RenderObject can be expensive
  /// if null, calls aren't throttled
  final Duration repositionDelay;
  final Duration repositionAnimationDuration;

  /// returns the offset relative to the top left corner of the button rect (if null, it aligns to the bottom left corner)
  final DropdownOverlayentryAlignment alignment;

  /// gets added to the default / returned alignment (just a shortcut for simple alignment use-cases)
  final Offset alignmentOffset;

  const DropdownOverlayEntry({
    Key key,
    @required this.triggerBuilder,
    @required this.dropdownBuilder,
    this.autoRebuild = true,
    this.autoReposition = true,
    this.alignment,
    this.repositionDelay = const Duration(milliseconds: 100),
    this.repositionType = DropdownOverlayEntryRepositionType.debounceAnimate,
    this.repositionAnimationDuration = const Duration(milliseconds: 100),
    this.alignmentOffset = const Offset(0, 1),
  }) : super(key: key);

  @override
  DropdownOverlayEntryState createState() => DropdownOverlayEntryState();
}

class DropdownOverlayEntryState extends State<DropdownOverlayEntry> with SingleTickerProviderStateMixin {
  AnimationController _repositionAnimationController;
  Tween<Offset> _repositionAnimationTween;
  Animation<Offset> _repositionAnimation;
  GlobalKey _buttonKey = GlobalKey();
  OverlayEntry _overlayEntry;
  Rect _prevButtonRect;
  Rect _buttonRect;
  bool _isOpen = false;

  bool get isOpen => _isOpen;

  @override
  Widget build(BuildContext context) {
    // this ensures that we rebuild on size changes
    MediaQuery.of(context);
    if (_isOpen) {
      if (widget.autoReposition) {
        updatePosition();
      } else if (widget.autoRebuild) {
        rebuild();
      }
    }
    return widget.triggerBuilder(context, _buttonKey, _isOpen);
  }

  @override
  void initState() {
    super.initState();
    _repositionAnimationController = AnimationController(vsync: this);
    _repositionAnimationController.addListener(() {
      rebuild();
    });
    _repositionAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _prevButtonRect = _buttonRect;
        _repositionAnimationTween = null;
      }
    });
  }

  @override
  void didUpdateWidget(covariant DropdownOverlayEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void rebuild() {
    _overlayEntry?.markNeedsBuild();
  }

  void updatePosition() {
    switch (widget.repositionType) {
      case DropdownOverlayEntryRepositionType.debounceAnimate:
        gm5Utils.eventUtils.debounce(widget.repositionDelay.inMilliseconds, () {
          _updatePosition();
          rebuild();
        }, key: _buttonKey);
        break;
      case DropdownOverlayEntryRepositionType.throttle:
        gm5Utils.eventUtils.throttle(widget.repositionDelay.inMilliseconds, () {
          _updatePosition();
          rebuild();
        }, key: _buttonKey);
        break;
      case DropdownOverlayEntryRepositionType.always:
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          _updatePosition();
          rebuild();
        });
        break;
    }
  }

  void _updatePosition() {
    _prevButtonRect = _buttonRect;
    _buttonRect = _getButtonRect();
  }

  void toggle() {
    if (_isOpen)
      close();
    else
      open();
  }

  void open() {
    _updatePosition();
    _overlayEntry = OverlayEntry(builder: (context) => _dropdownChild());
    Navigator.of(context).overlay.insert(_overlayEntry);
    setState(() {
      _isOpen = true;
    });
    print('open $_isOpen');
  }

  void close() {
    _overlayEntry?.remove();
    setState(() {
      _isOpen = false;
    });
    print('open $_isOpen');
  }

  Rect _getButtonRect() {
    RenderObject renderObject = _buttonKey.currentContext?.findRenderObject();
    assert(renderObject != null);
    assert(renderObject.attached);
    RenderBox box = (renderObject as RenderBox);
    Offset topLeft = box.localToGlobal(Offset.zero);
    Offset bottomRight = topLeft + box.size.bottomRight(Offset.zero);
    return Rect.fromPoints(topLeft, bottomRight);
  }

  Offset _getAlignmentForRect(Rect rect) {
    Offset alignment = Offset(0, rect.height);
    if (widget.alignment != null) {
      alignment = widget.alignment(rect) ?? alignment;
    }
    alignment += rect.topLeft;
    alignment += widget.alignmentOffset;
    return alignment;
  }

  void _updateRepositionAnimation() {
    Offset alignment = _getAlignmentForRect(_buttonRect);
    if (widget.repositionType == DropdownOverlayEntryRepositionType.debounceAnimate) {
      Offset prevAlignment = _getAlignmentForRect(_prevButtonRect ?? _buttonRect);
      _repositionAnimationTween = Tween(begin: _repositionAnimationTween?.begin ?? prevAlignment, end: alignment);
      _repositionAnimation = _repositionAnimationTween.animate(_repositionAnimationController);
      if (!_repositionAnimationController.isAnimating && alignment != prevAlignment) {
        _repositionAnimationController.duration = Duration(milliseconds: 100);
        _repositionAnimationController.forward(from: 0);
      }
    } else {
      _repositionAnimation = AlwaysStoppedAnimation(alignment);
    }
  }

  Widget _dropdownChild() {
    _updateRepositionAnimation();
    return AnimatedBuilder(
      animation: _repositionAnimationController,
      builder: (context, child) => Padding(
        padding: EdgeInsets.only(top: _repositionAnimation.value.dy, left: _repositionAnimation.value.dx),
        child: Align(
          alignment: Alignment.topLeft,
          child: Material(
            type: MaterialType.transparency,
            child: widget.dropdownBuilder(context, _buttonRect),
          ),
        ),
      ),
    );
  }
}
