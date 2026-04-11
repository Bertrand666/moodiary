import 'package:get/get.dart';
import 'package:moodiary/common/values/language.dart';
import 'package:moodiary/persistence/pref.dart';
import 'package:moodiary/common/values/pref_keys.dart';

class SettingState {
  //当前占用空间
  String dataUsage = '';

  int themeMode = PrefUtil.getValue<int>(PrefKeys.themeMode)!;

  int color = PrefUtil.getValue<int>(PrefKeys.color)!;

  late RxInt fontTheme;

  bool lock = PrefUtil.getValue<bool>(PrefKeys.lock)!;

  bool lockNow = PrefUtil.getValue<bool>(PrefKeys.lockNow)!;

  bool local = PrefUtil.getValue<bool>(PrefKeys.local)!;

  String customTitle = PrefUtil.getValue<String>(PrefKeys.customTitleName)!;

  String customSubTitle = PrefUtil.getValue<String>(PrefKeys.customSubTitleName)!;

  RxBool backendPrivacy = PrefUtil.getValue<bool>(PrefKeys.backendPrivacy)!.obs;

  RxString userKey = ''.obs;

  Rx<Language> language =
      Language.values
          .firstWhere(
            (e) => e.languageCode == PrefUtil.getValue<String>(PrefKeys.language)!,
            orElse: () => Language.system,
          )
          .obs;

  SettingState() {
    fontTheme = PrefUtil.getValue<int>(PrefKeys.fontTheme)!.obs;
  }
}
