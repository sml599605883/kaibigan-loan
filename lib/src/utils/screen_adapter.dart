import 'package:flutter/widgets.dart';

class ScreenAdapter {
  const ScreenAdapter._(this._size);

  static const designWidth = 375.0;
  static const designHeight = 812.0;

  final Size _size;
  static Size _currentSize = const Size(designWidth, designHeight);

  static void init(BuildContext context) {
    _currentSize = MediaQuery.sizeOf(context);
  }

  static ScreenAdapter get current => ScreenAdapter._(_currentSize);

  static ScreenAdapter of(BuildContext context) {
    init(context);
    return current;
  }

  double get scaleWidth => _size.width / designWidth;

  double get scaleHeight => _size.height / designHeight;

  double get scaleText => scaleWidth;

  double w(num value) => value * scaleWidth;

  double h(num value) => value * scaleHeight;

  double sp(num value) => value * scaleText;

  double r(num value) => value * scaleWidth;

  Size size(num width, num height) => Size(w(width), h(height));

  EdgeInsets edgeInsetsAll(num value) {
    return EdgeInsets.all(w(value));
  }

  EdgeInsets edgeInsetsSymmetric({num horizontal = 0, num vertical = 0}) {
    return EdgeInsets.symmetric(
      horizontal: w(horizontal),
      vertical: h(vertical),
    );
  }

  EdgeInsets edgeInsetsOnly({
    num left = 0,
    num top = 0,
    num right = 0,
    num bottom = 0,
  }) {
    return EdgeInsets.only(
      left: w(left),
      top: h(top),
      right: w(right),
      bottom: h(bottom),
    );
  }

  EdgeInsets edgeInsetsFromLTRB(num left, num top, num right, num bottom) {
    return EdgeInsets.fromLTRB(w(left), h(top), w(right), h(bottom));
  }

  BorderRadius borderRadiusAll(num radius) {
    return BorderRadius.circular(r(radius));
  }
}

extension ScreenAdapterBuildContextX on BuildContext {
  ScreenAdapter get screen => ScreenAdapter.of(this);
}

extension ScreenAdapterNumX on num {
  double get w => ScreenAdapter.current.w(this);

  double get h => ScreenAdapter.current.h(this);

  double get sp => ScreenAdapter.current.sp(this);

  double get r => ScreenAdapter.current.r(this);

  double wOf(BuildContext context) => context.screen.w(this);

  double hOf(BuildContext context) => context.screen.h(this);

  double spOf(BuildContext context) => context.screen.sp(this);

  double rOf(BuildContext context) => context.screen.r(this);

  Size size(num height) {
    return ScreenAdapter.current.size(this, height);
  }

  Size sizeOf(BuildContext context, num height) {
    return context.screen.size(this, height);
  }

  EdgeInsets get insetsAll {
    return ScreenAdapter.current.edgeInsetsAll(this);
  }

  EdgeInsets insetsAllOf(BuildContext context) {
    return context.screen.edgeInsetsAll(this);
  }

  EdgeInsets insetsSymmetric({num? horizontal, num? vertical}) {
    return ScreenAdapter.current.edgeInsetsSymmetric(
      horizontal: horizontal ?? this,
      vertical: vertical ?? this,
    );
  }

  EdgeInsets insetsSymmetricOf(
    BuildContext context, {
    num? horizontal,
    num? vertical,
  }) {
    return context.screen.edgeInsetsSymmetric(
      horizontal: horizontal ?? this,
      vertical: vertical ?? this,
    );
  }

  EdgeInsets insetsOnly({num? left, num? top, num? right, num? bottom}) {
    return ScreenAdapter.current.edgeInsetsOnly(
      left: left ?? this,
      top: top ?? 0,
      right: right ?? 0,
      bottom: bottom ?? 0,
    );
  }

  EdgeInsets insetsOnlyOf(
    BuildContext context, {
    num? left,
    num? top,
    num? right,
    num? bottom,
  }) {
    return context.screen.edgeInsetsOnly(
      left: left ?? this,
      top: top ?? 0,
      right: right ?? 0,
      bottom: bottom ?? 0,
    );
  }

  BorderRadius get radiusAll {
    return ScreenAdapter.current.borderRadiusAll(this);
  }

  BorderRadius radiusAllOf(BuildContext context) {
    return context.screen.borderRadiusAll(this);
  }
}
