import 'package:flutter/painting.dart';

import '../core/constants.dart';
import '../models/eco_level.dart';

extension CategoryMetaColors on CategoryMeta {
  Color get color => Color(colorValue);
  Color get bg => Color(bgValue);
}

extension EcoLevelColors on EcoLevel {
  Color get color => Color(colorValue);
}
