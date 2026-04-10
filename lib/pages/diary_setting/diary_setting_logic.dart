import 'package:get/get.dart';
import 'package:moodiary/persistence/pref.dart';

import 'diary_setting_state.dart';
import 'package:moodiary/common/values/pref_keys.dart';

class DiarySettingLogic extends GetxController {
  final DiarySettingState state = DiarySettingState();

  //图片质量
  Future<void> quality(int value) async {
    await PrefUtil.setValue<int>(PrefKeys.quality, value);
    state.quality.value = value;
  }

  //自动天气
  Future<void> autoWeather(bool value) async {
    await PrefUtil.setValue<bool>(PrefKeys.autoWeather, value);
    state.autoWeather.value = value;
  }

  //动态配色
  Future<void> dynamicColor(bool value) async {
    await PrefUtil.setValue<bool>(PrefKeys.dynamicColor, value);
    state.dynamicColor.value = value;
  }

  // 日记页头图
  Future<void> diaryHeader(bool value) async {
    await PrefUtil.setValue<bool>(PrefKeys.diaryHeader, value);
    state.diaryHeader.value = value;
  }

  // 首行缩进
  Future<void> firstLineIndent(bool value) async {
    await PrefUtil.setValue<bool>(PrefKeys.firstLineIndent, value);
    state.firstLineIndent.value = value;
  }

  // 自动设置分类
  Future<void> autoCategory(bool value) async {
    await PrefUtil.setValue<bool>(PrefKeys.autoCategory, value);
    state.autoCategory.value = value;
  }

  // 展示写作时长
  Future<void> showWriteTime(bool value) async {
    await PrefUtil.setValue<bool>(PrefKeys.showWritingTime, value);
    state.showWriteTime.value = value;
  }

  // 展示字数统计
  Future<void> showWordCount(bool value) async {
    await PrefUtil.setValue<bool>(PrefKeys.showWordCount, value);
    state.showWordCount.value = value;
  }
}
