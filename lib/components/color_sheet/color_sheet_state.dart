import 'package:moodiary/persistence/pref.dart';
import 'package:moodiary/common/values/pref_keys.dart';

class ColorSheetState {
  int currentColor = PrefUtil.getValue<int>(PrefKeys.color)!;

  ColorSheetState();
}
