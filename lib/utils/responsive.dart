import 'package:flutter/material.dart';

class R {
  static late MediaQueryData _mq;

  static void init(BuildContext context) {
    _mq = MediaQuery.of(context);
  }

  // Screen dimensions
  static double get width => _mq.size.width;
  static double get height => _mq.size.height;

  // Responsive font sizes - scales with screen width (base: 390px iPhone 16)
  static double fs(double size) => size * (width / 390).clamp(0.85, 1.2);

  // Responsive spacing
  static double sp(double size) => size * (width / 390).clamp(0.85, 1.2);

  // Responsive padding
  static EdgeInsets p(double all) => EdgeInsets.all(sp(all));
  static EdgeInsets ph(double h, double v) =>
      EdgeInsets.symmetric(horizontal: sp(h), vertical: sp(v));

  // Safe bottom padding
  static double get bottomPadding => _mq.padding.bottom;
  static double get topPadding => _mq.padding.top;

  // Is tablet
  static bool get isTablet => width > 600;
}
