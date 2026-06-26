import 'package:flutter/widgets.dart';

class ScreenAdapter {
  const ScreenAdapter._(this._size);

  static const designWidth = 375.0;
  static const designHeight = 812.0;

  final Size _size;

  static ScreenAdapter of(BuildContext context) {
    return ScreenAdapter._(MediaQuery.sizeOf(context));
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
