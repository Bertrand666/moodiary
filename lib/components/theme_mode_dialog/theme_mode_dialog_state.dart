import 'package:moodiary/persistence/pref.dart';
import 'package:moodiary/common/values/pref_keys.dart';

class ThemeModeDialogState {
  int themeMode = PrefUtil.getValue<int>(PrefKeys.themeMode)!;

  ThemeModeDialogState();
}
