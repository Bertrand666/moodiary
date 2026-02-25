import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moodiary/common/models/isar/diary.dart';
import 'package:moodiary/common/values/diary_domain.dart';
import 'package:moodiary/components/diary_tab_view/diary_tab_view_logic.dart';
import 'package:moodiary/pages/diary_details/diary_details_logic.dart';
import 'package:moodiary/pages/home/diary/diary_logic.dart';
import 'package:moodiary/persistence/isar.dart';
import 'package:moodiary/router/app_routes.dart';

mixin BasicCardLogic {
  DiaryDomain _domainOf(Diary diary) => DiaryDomain.fromValue(diary.domain);

  Future<void> toDiary(Diary diary) async {
    HapticFeedback.mediumImpact();
    Bind.lazyPut(() => DiaryDetailsLogic(), tag: diary.id);
    final res = await Get.toNamed(
      AppRoutes.diaryPage,
      arguments: [diary.clone(), true],
    );
    if (res == 'delete') {
      final domain = _domainOf(diary);
      //如果分类为空，删除主页即可，如果分类不为空，双删除
      if (diary.categoryId != null &&
          Bind.isRegistered<DiaryTabViewLogic>(
            tag: domain.tabTag(diary.categoryId),
          )) {
        Bind.find<DiaryTabViewLogic>(
          tag: domain.tabTag(diary.categoryId),
        ).state.diaryList.removeWhere((e) => e.id == diary.id);
        Bind.find<DiaryTabViewLogic>(
          tag: domain.tabTag(diary.categoryId),
        ).update();
      }
      Bind.find<DiaryTabViewLogic>(
        tag: domain.defaultTabTag,
      ).state.diaryList.removeWhere((e) => e.id == diary.id);
      Bind.find<DiaryTabViewLogic>(tag: domain.defaultTabTag).update();
    } else {
      final newDiary = await IsarUtil.getDiaryByID(diary.isarId);
      if (newDiary == null) return;
      if (diary == newDiary) {
        return;
      }
      final domain = _domainOf(newDiary);
      final newCategoryId = newDiary.categoryId;
      final oldCategoryId = diary.categoryId;
      //如果修改了但是没有修改分类，就替换掉原来的
      if (oldCategoryId == newCategoryId) {
        //替换掉全部分类中的
        final oldIndex = Bind.find<DiaryTabViewLogic>(
          tag: domain.defaultTabTag,
        ).state.diaryList.indexWhere((e) => e.id == newDiary.id);
        Bind.find<DiaryTabViewLogic>(
          tag: domain.defaultTabTag,
        ).state.diaryList.replaceRange(oldIndex, oldIndex + 1, [newDiary]);
        Bind.find<DiaryTabViewLogic>(tag: domain.defaultTabTag).update();
        //如果注册了控制器
        if (newDiary.categoryId != null &&
            Bind.isRegistered<DiaryTabViewLogic>(
              tag: domain.tabTag(newDiary.categoryId),
            )) {
          final oldIndex = Bind.find<DiaryTabViewLogic>(
            tag: domain.tabTag(newDiary.categoryId),
          ).state.diaryList.indexWhere((e) => e.id == newDiary.id);
          Bind.find<DiaryTabViewLogic>(
            tag: domain.tabTag(newDiary.categoryId),
          ).state.diaryList.replaceRange(oldIndex, oldIndex + 1, [newDiary]);
          Bind.find<DiaryTabViewLogic>(
            tag: domain.tabTag(newDiary.categoryId),
          ).update();
        }
        //await Bind.find<DiaryLogic>().updateDiary(oldCategoryId);
      } else {
        //如果修改了分类
        //再去新的分类
        await Bind.find<DiaryLogic>(
          tag: domain.logicTag,
        ).updateDiary(newCategoryId);
        //先改旧分类
        await Bind.find<DiaryLogic>(
          tag: domain.logicTag,
        ).updateDiary(oldCategoryId, jump: false);
      }
    }
  }

  Future<void> toDiaryInCalendar(Diary diary) async {
    await HapticFeedback.mediumImpact();
    Bind.lazyPut(() => DiaryDetailsLogic(), tag: diary.id);
    await Get.toNamed(AppRoutes.diaryPage, arguments: [diary.clone(), false]);
  }

  int getMaxLines(String context) {
    return switch (context.length) {
      >= 20 && < 30 => 2,
      >= 30 && < 40 => 3,
      >= 40 => 4,
      _ => 1,
    };
  }
}
