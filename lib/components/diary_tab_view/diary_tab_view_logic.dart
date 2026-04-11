import 'package:get/get.dart';
import 'package:moodiary/common/values/diary_domain.dart';
import 'package:moodiary/pages/home/diary/diary_logic.dart';
import 'package:moodiary/persistence/isar.dart';

import 'diary_tab_view_state.dart';

class DiaryTabViewLogic extends GetxController {
  final DiaryTabViewState state = DiaryTabViewState();

  late final DiaryLogic diaryLogic;

  DiaryTabViewLogic({
    required DiaryDomain domain,
    required String? tagName,
  }) {
    state.domain = domain;
    state.tagName = tagName;
    diaryLogic = Bind.find<DiaryLogic>(tag: domain.logicTag);
  }

  @override
  void onReady() async {
    try {
      await _getDiary();
    } catch (e, s) {
      print('[DiaryTabViewLogic] onReady error: $e\n$s');
      state.isFetching.value = false;
    }
    super.onReady();
  }

  Future<void> _getDiary() async {
    state.isFetching.value = true;
    try {
      state.diaryList.value = await IsarUtil.getDiaryByTag(
        state.tagName,
        0,
        state.initLen,
        domain: state.domain,
      );
    } catch (e, s) {
      print('[DiaryTabViewLogic] _getDiary error (domain=${state.domain}, tag=${state.tagName}): $e\n$s');
    } finally {
      state.isFetching.value = false;
    }
  }

  Future<void> updateDiary() async {
    state.isFetching.value = true;
    state.diaryList.value = await IsarUtil.getDiaryByTag(
      state.tagName,
      0,
      state.initLen,
      domain: state.domain,
    );
    state.isFetching.value = false;
  }

  Future<void> paginationDiary() async {
    state.diaryList.value += await IsarUtil.getDiaryByTag(
      state.tagName,
      state.diaryList.length,
      state.pageLen,
      domain: state.domain,
    );
  }
}
