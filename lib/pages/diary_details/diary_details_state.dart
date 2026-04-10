import 'package:get/get.dart';
import 'package:moodiary/common/models/isar/diary.dart';
import 'package:moodiary/persistence/pref.dart';
import 'package:moodiary/common/values/pref_keys.dart';

class DiaryDetailsState {
  Diary diary = Get.arguments[0];

  bool showAction = Get.arguments[1];

  double? get aspect => diary.aspect;

  int? get imageColor => diary.imageColor;

  RxBool isScrolling = false.obs;

  bool get diaryHeader => PrefUtil.getValue<bool>(PrefKeys.diaryHeader)!;

  DiaryDetailsState();
}
