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
    required String? categoryId,
  }) {
    state.domain = domain;
    state.categoryId = categoryId;
    diaryLogic = Bind.find<DiaryLogic>(tag: domain.logicTag);
  }

  @override
  void onReady() async {
    await _getDiary();
    super.onReady();
  }

  Future<void> _getDiary() async {
    state.isFetching.value = true;
    state.diaryList.value = await IsarUtil.getDiaryByCategory(
      state.categoryId,
      0,
      state.initLen,
      domain: state.domain,
    );
    state.isFetching.value = false;
  }

  Future<void> updateDiary() async {
    state.isFetching.value = true;
    state.diaryList.value = await IsarUtil.getDiaryByCategory(
      state.categoryId,
      0,
      state.initLen,
      domain: state.domain,
    );
    state.isFetching.value = false;
  }

  Future<void> paginationDiary() async {
    state.diaryList.value += await IsarUtil.getDiaryByCategory(
      state.categoryId,
      state.diaryList.length,
      state.pageLen,
      domain: state.domain,
    );
  }
}
