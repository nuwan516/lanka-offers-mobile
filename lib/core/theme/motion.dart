import 'package:flutter/animation.dart';

abstract final class Motion {
  static const press = Duration(milliseconds: 100);
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 600);
  static const celebration = Duration(milliseconds: 1200);

  static const curve = Curves.easeOutCubic;
  static const emphasized = Curves.easeInOutCubicEmphasized;
  static const countUp = Curves.easeOutExpo;
}
