import 'dart:async';

class EventUtils {
  static Map debounceTimeouts = {};
  static Map throttleMethods = {};

  static void debounce(int timeoutMs, Function target, {key, List? arguments}) {
    key = key ?? target;
    if (debounceTimeouts.containsKey(key)) {
      debounceTimeouts[key].cancel();
    }

    Timer timer = Timer(Duration(milliseconds: timeoutMs), () {
      Function.apply(target, arguments ?? []);
    });

    debounceTimeouts[key] = timer;
  }

  static void throttle(int period, Function target, {key, List? arguments, bool callAtStart = false}) {
    key = key ?? target;
    if (debounceTimeouts[key]?.isActive ?? false) {
      throttleMethods[key] = target;
      return;
    }

    Timer timer = Timer(Duration(milliseconds: period), () {
      if (!callAtStart)
        Function.apply(target, arguments ?? []);
      else if (throttleMethods[key] != null) {
        Function.apply(throttleMethods[key], arguments ?? []);
      }
    });

    if (callAtStart) Function.apply(target, arguments ?? []);
    debounceTimeouts[key] = timer;
  }

  static void dropAbove(int period, Function target, {key, List? arguments}) {
    key = key ?? target;
    if (debounceTimeouts[key]?.isActive ?? false) {
      return;
    }

    Timer timer = Timer(Duration(milliseconds: period), () => null);
    debounceTimeouts[key] = timer;
    Function.apply(target, arguments ?? []);
  }
}
