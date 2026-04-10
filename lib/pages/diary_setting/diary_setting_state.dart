import 'package:get/get.dart';
import 'package:moodiary/persistence/pref.dart';
import 'package:moodiary/common/values/pref_keys.dart';

class DiarySettingState {
  // 图片质量
  RxInt quality = PrefUtil.getValue<int>(PrefKeys.quality)!.obs;

  // 动态配色
  RxBool dynamicColor = PrefUtil.getValue<bool>(PrefKeys.dynamicColor)!.obs;

  // 自动天气
  RxBool autoWeather = PrefUtil.getValue<bool>(PrefKeys.autoWeather)!.obs;

  // 日记页头图
  RxBool diaryHeader = PrefUtil.getValue<bool>(PrefKeys.diaryHeader)!.obs;

  // 首行缩进
  RxBool firstLineIndent = PrefUtil.getValue<bool>(PrefKeys.firstLineIndent)!.obs;

  // 自动分类
  RxBool autoCategory = PrefUtil.getValue<bool>(PrefKeys.autoCategory)!.obs;

  // 展示写作时长
  RxBool showWriteTime = PrefUtil.getValue<bool>(PrefKeys.showWritingTime)!.obs;

  // 展示字数统计
  RxBool showWordCount = PrefUtil.getValue<bool>(PrefKeys.showWordCount)!.obs;

  DiarySettingState();
}
