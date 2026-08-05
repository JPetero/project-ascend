import 'package:flutter/widgets.dart';

/// Project Ascend's corner radius scale.
abstract final class AscendRadius {
  static const double small = 8;
  static const double medium = 16;
  static const double large = 24;
  static const double extraLarge = 32;
  static const double pill = 999;

  static const BorderRadius smallRadius = BorderRadius.all(
    Radius.circular(small),
  );
  static const BorderRadius mediumRadius = BorderRadius.all(
    Radius.circular(medium),
  );
  static const BorderRadius largeRadius = BorderRadius.all(
    Radius.circular(large),
  );
  static const BorderRadius extraLargeRadius = BorderRadius.all(
    Radius.circular(extraLarge),
  );
  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(pill),
  );
}
