import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'event_utils.dart';
import 'package:dropdown_overlayentry/dropdown_overlayentry_animations.dart';

typedef DropdownOverlayentryButtonBuilder = Widget Function(
    BuildContext context, GlobalKey key, bool isOpen, VoidCallback toggle);
typedef DropdownOverlayentryBuilder = Widget Function(BuildContext context, Rect buttonRect);
typedef DropdownOverlayentryAlignment = Offset Function(Rect buttonRect);
enum DropdownOverlayEntryRepositionType { debounceAnimate, throttle, always }

class DropdownOverlayEntry extends StatefulWidget {
  static final StreamController _closeAll = StreamController.broadcast();

  static void closeAll() => _closeAll.add(null);

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
  final Duration? repositionDelay;
  final Duration repositionAnimationDuration;

  /// returns the offset relative to the top left corner of the button rect (if null, it aligns to the bottom left corner)
  final DropdownOverlayentryAlignment? alignment;

  /// returns the offset relative to the top left corner of the button rect (if null, it aligns to the bottom left corner)
  /// this will effectively shift the trigger when opened, if `behindTrigger` is true
  final DropdownOverlayentryAlignment? openTriggerAlignment;

  /// gets added to the default / returned alignment (just a shortcut for simple alignment use-cases)
  final Offset alignmentOffset;

  /// automatically closes this dropdown if other instance is opened
  final bool closeIfOtherIsOpened;

  /// if true, trigger is drawn on top of the dropdown layout
  final bool behindTrigger;

  /// if trigger is inside scrollable widget, we cannot know when to refresh its position
  /// unless we have access to the parent updates - let me know if you see any better solutions
  final ScrollController? scrollController;

  /// DDOE can be opened either by this value or through it's state.
  final bool? isOpen;

  final DropdownOverlayEntryAnimation? animation;

  final bool barrierDismissible;

  final Color barrierColor;

  const DropdownOverlayEntry({
    Key? key,
    required this.triggerBuilder,
    required this.dropdownBuilder,
    this.autoRebuild = true,
    this.autoReposition = true,
    this.alignment,
    this.openTriggerAlignment,
    this.repositionDelay,
    this.repositionType = DropdownOverlayEntryRepositionType.throttle,
    this.repositionAnimationDuration = const Duration(milliseconds: 100),
    this.alignmentOffset = const Offset(0, 1),
    this.closeIfOtherIsOpened = true,
    this.barrierDismissible = false,
    this.barrierColor = Colors.transparent,
    this.behindTrigger = false,
    this.scrollController,
    this.isOpen,
    this.animation,
  })  : assert(openTriggerAlignment == null || behindTrigger),
        super(key: key);

  @override
  DropdownOverlayEntryState createState() => DropdownOverlayEntryState();
}

class DropdownOverlayEntryState extends State<DropdownOverlayEntry>
    with SingleTickerProviderStateMixin {
  static StreamController<GlobalKey> _openedStreamController = StreamController.broadcast();
  GlobalKey _triggerTree = GlobalKey();
  late AnimationController _repositionAnimationController;
  Tween<Offset>? _repositionAnimationTween;
  late Animation<Offset> _repositionAnimation;
  GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  Rect? _prevButtonRect;
  Rect? _buttonRect;
  Rect? _triggerRect;
  bool _isOpen = false;
  Widget? _trigger;
  late BoxConstraints _triggerConstraints;
  bool _updateTriggerConstraints = false;

  late StreamSubscription _otherOpenedSubscription;
  late StreamSubscription _closeSubscription;

  double? _prevScrollOffset;

  bool get isOpen => _isOpen && !_isClosing;
  bool _isClosing = false;
  bool _justOpened = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isOpen != null && isOpen != widget.isOpen) {
      WidgetsBinding.instance?.addPostFrameCallback((timeStamp) => toggle());
    }
    // this ensures that we rebuild on size changes
    MediaQuery.of(context);
    if (_isOpen && !_updateTriggerConstraints) {
      if (widget.autoReposition) {
        updatePosition();
      } else if (widget.autoRebuild) {
        rebuild();
      }
    }

    _updateTriggerConstraints = false;

    if (!widget.behindTrigger) return widget.triggerBuilder(context, _buttonKey, isOpen, toggle);

    return LayoutBuilder(
      builder: (context, constraints) {
        final trigger = widget.triggerBuilder(context, _buttonKey, isOpen, toggle);
        _triggerConstraints = constraints;
        _trigger = KeyedSubtree(
          key: _triggerTree,
          child: Material(type: MaterialType.transparency, child: trigger),
        );

        if (_isOpen)
          return SizedBox(
            width: _triggerRect!.width,
            height: _triggerRect!.height,
          );
        return _trigger!;
      },
    );
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
    _otherOpenedSubscription = _openedStreamController.stream.listen(_onOtherOpened);
    _closeSubscription = DropdownOverlayEntry._closeAll.stream.listen((_) => close());
    widget.scrollController?.addListener(_onScroll);
    _prevScrollOffset = widget.scrollController?.offset;
  }

  @override
  void dispose() {
    super.dispose();
    close();
    _otherOpenedSubscription.cancel();
    _closeSubscription.cancel();
    widget.scrollController?.removeListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant DropdownOverlayEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void rebuild() {
    if (!widget.autoReposition && !widget.autoRebuild) {
      _overlayEntry?.markNeedsBuild();
    } else if (!widget.autoReposition) {
      updatePosition();
    }

    if (mounted && !widget.autoRebuild) {
      setState(() {});
    }
  }

  void updatePosition() {
    VoidCallback update = () {
      _updatePosition();
      _overlayEntry?.markNeedsBuild();
    };
    if (widget.behindTrigger) {
      // we neet two rebuilds to 1) get new position of the trigger and 2) reposition the dropdown
      update = () {
        _updatePosition();
        _overlayEntry?.markNeedsBuild();
        WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
          _updatePosition();
          _overlayEntry?.markNeedsBuild();
          if (mounted) {
            setState(() {
              _updateTriggerConstraints = true;
            });
          }
        });
      };
    }

    switch (widget.repositionType) {
      case DropdownOverlayEntryRepositionType.debounceAnimate:
        if (widget.repositionDelay == null)
          WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
            update();
          });
        else
          EventUtils.debounce(widget.repositionDelay!.inMilliseconds, update, key: _buttonKey);
        break;
      case DropdownOverlayEntryRepositionType.throttle:
        if (widget.repositionDelay == null)
          WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
            update();
          });
        else
          EventUtils.throttle(widget.repositionDelay!.inMilliseconds, update, key: _buttonKey);
        break;
      case DropdownOverlayEntryRepositionType.always:
        WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
          update();
        });
        break;
    }
  }

  void _updatePosition() {
    _prevButtonRect = _buttonRect;
    _buttonRect = _getButtonRect();
    if (widget.behindTrigger) {
      _triggerRect = _getTriggerRect();
    }
  }

  void toggle() {
    if (isOpen)
      close();
    else
      open();
  }

  void open() {
    if (isOpen) return;
    if (_isClosing) {
      _overlayEntry?.remove();
      _isClosing = false;
    }
    _openedStreamController.add(_buttonKey);
    _updatePosition();
    _overlayEntry = OverlayEntry(builder: (context) => _dropdownChild());
    Navigator.of(context, rootNavigator: true).overlay!.insert(_overlayEntry!);
    _isOpen = true;
    if (widget.animation != null) {
      _justOpened = true;
      WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
        _justOpened = false;
        _overlayEntry?.markNeedsBuild();
      });
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future close() async {
    if (!isOpen) return;
    if (mounted) {
      setState(() {});
    }
    if (widget.animation != null) {
      _isClosing = true;
      _overlayEntry?.markNeedsBuild();
      await Future.delayed(widget.animation!.duration);
      if (_isClosing) {
        _isOpen = false;
        _overlayEntry?.remove();
        _isClosing = false;
        setState(() {});
      }
    } else {
      _isOpen = false;
      _overlayEntry?.remove();
    }
  }

  RenderObject? buttonRO;

  Rect _getButtonRect() {
    buttonRO ??= _buttonKey.currentContext!.findRenderObject()!;
    assert(buttonRO!.attached);
    RenderBox box = (buttonRO as RenderBox);
    Offset topLeft = box.localToGlobal(Offset.zero);
    Offset bottomRight = topLeft + box.size.bottomRight(Offset.zero);
    return Rect.fromPoints(topLeft, bottomRight);
  }

  RenderObject? triggerRO;

  Rect _getTriggerRect() {
    triggerRO ??= _triggerTree.currentContext!.findRenderObject()!;
    assert(triggerRO!.attached);
    RenderBox box = (triggerRO as RenderBox);
    Offset topLeft = box.localToGlobal(Offset.zero);
    Offset bottomRight = topLeft + box.size.bottomRight(Offset.zero);
    return Rect.fromPoints(topLeft, bottomRight);
  }

  Offset _getAlignmentForRect(Rect rect) {
    Offset alignment = Offset(0, widget.behindTrigger ? 0 : rect.height);
    if (widget.alignment != null) {
      alignment = widget.alignment!(rect);
    }
    alignment += rect.topLeft;
    alignment += widget.alignmentOffset;
    return alignment;
  }

  void _updateRepositionAnimation() {
    Offset alignment = _getAlignmentForRect(_buttonRect!);
    if (widget.repositionType == DropdownOverlayEntryRepositionType.debounceAnimate) {
      Offset prevAlignment = _getAlignmentForRect(_prevButtonRect ?? _buttonRect!);
      _repositionAnimationTween =
          Tween(begin: _repositionAnimationTween?.begin ?? prevAlignment, end: alignment);
      _repositionAnimation = _repositionAnimationTween!.animate(_repositionAnimationController);
      if (!_repositionAnimationController.isAnimating && alignment != prevAlignment) {
        _repositionAnimationController.duration = widget.repositionAnimationDuration;
        _repositionAnimationController.forward(from: 0);
      }
    } else {
      _repositionAnimation = AlwaysStoppedAnimation(alignment);
    }
  }

  Widget _dropdownChild() {
    _updateRepositionAnimation();
    Offset triggerAlignmentOffset = Offset(0, 0);
    if (widget.openTriggerAlignment != null) {
      triggerAlignmentOffset = widget.openTriggerAlignment!(_triggerRect!);
    }

    // overlay
    Widget child = GestureDetector(
      onTap: () {},
      child: Material(
        type: MaterialType.transparency,
        child: widget.dropdownBuilder(context, _buttonRect!),
      ),
    );

    // open / close animation
    if (widget.animation != null) {
      child = widget.animation!.builder(isOpen && !_justOpened ? child : Offstage());
    }

    // reposition animation
    Widget animatedChild = AnimatedBuilder(
      animation: _repositionAnimationController,
      builder: (context, _) => Stack(
        children: [
          Positioned(
            top: _repositionAnimation.value.dy,
            left: _repositionAnimation.value.dx,
            child: child,
          ),
          if (widget.behindTrigger)
            Positioned(
              top: _triggerRect!.top + triggerAlignmentOffset.dy,
              left: _triggerRect!.left + triggerAlignmentOffset.dx,
              child: ConstrainedBox(
                constraints: _triggerConstraints,
                child: _trigger,
              ),
            ),
        ],
      ),
    );

    if (widget.barrierDismissible) {
      return GestureDetector(
        onTap: close,
        child: Container(
          color: widget.barrierColor,
          width: double.infinity,
          height: double.infinity,
          child: animatedChild,
        ),
      );
    } else {
      return animatedChild;
    }
  }

  void _onOtherOpened(key) {
    if (key != _buttonKey && widget.closeIfOtherIsOpened && isOpen) close();
  }

  void _onScroll() {
    double delta = widget.scrollController!.offset - _prevScrollOffset!;
    _prevScrollOffset = widget.scrollController!.offset;

    Offset dOffset = Offset(
      widget.scrollController!.position.axis == Axis.horizontal ? -delta : 0,
      widget.scrollController!.position.axis == Axis.horizontal ? 0 : -delta,
    );

    _prevButtonRect = _prevButtonRect?.translate(dOffset.dx, dOffset.dy);
    _buttonRect = _buttonRect?.translate(dOffset.dx, dOffset.dy);
    _triggerRect = _triggerRect?.translate(dOffset.dx, dOffset.dy);
    _overlayEntry?.markNeedsBuild();
    if (buttonRO!.paintBounds.isEmpty) close();
  }
}
