import 'package:get/get.dart';
import 'package:moodiary/common/values/diary_domain.dart';
import 'package:moodiary/pages/home/diary/diary_logic.dart';

class DiaryLogicUtil {
  static Future<void> refreshAllDomains() async {
    for (final domain in DiaryDomain.values) {
      if (Bind.isRegistered<DiaryLogic>(tag: domain.logicTag)) {
        await Bind.find<DiaryLogic>(tag: domain.logicTag).refreshAll();
      }
    }
  }
}
