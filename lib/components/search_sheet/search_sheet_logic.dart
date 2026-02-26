import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moodiary/common/models/isar/diary.dart';
import 'package:moodiary/common/values/diary_domain.dart';
import 'package:moodiary/common/values/diary_template.dart';
import 'package:moodiary/common/values/keyboard_state.dart';
import 'package:moodiary/components/keyboard_listener/keyboard_listener.dart';
import 'package:moodiary/persistence/isar.dart';
import 'package:moodiary/src/rust/api/jieba.dart';
import 'package:throttling/throttling.dart';

import 'search_sheet_state.dart';

class SearchSheetLogic extends GetxController {
  final DiaryDomain domain;
  final SearchSheetState state = SearchSheetState();
  late TextEditingController textEditingController = TextEditingController();
  late FocusNode focusNode = FocusNode();

  late final KeyboardObserver _keyboardObserver;

  late final Throttling _throttling = Throttling(
    duration: const Duration(milliseconds: 500),
  );

  SearchSheetLogic({required this.domain});

  @override
  void onInit() {
    _keyboardObserver = KeyboardObserver(
      onHeightChanged: (height) {
        if (height > 0) {
          state.keyboardHeight.value = height;
        }
      },
      onStateChanged: (state) {
        switch (state) {
          case KeyboardState.opening:
            break;
          case KeyboardState.closing:
            unFocus();
            break;
          case KeyboardState.closed:
            break;
          case KeyboardState.unknown:
            break;
        }
      },
    );
    _keyboardObserver.start();
    textEditingController.addListener(() {
      _throttling.throttle(() async {
        await doSearch();
      });
    });
    super.onInit();
  }

  @override
  void onClose() {
    _keyboardObserver.stop();
    textEditingController.dispose();
    focusNode.dispose();
    _throttling.close();
    super.onClose();
  }

  void unFocus() {
    focusNode.unfocus();
  }

  void clear() {
    state.searchList.clear();
    state.totalCount.value = 0;
    state.queryList = [];
    state.isSearching.value = false;
    update();
  }

  Future<void> setChildhoodMemoirOnly(bool value) async {
    state.childhoodMemoirOnly.value = value;
    final currentText = textEditingController.text.trim();
    if (currentText.isBlank && !value) {
      clear();
      return;
    }
    await doSearch();
  }

  Future<void> doSearch() async {
    final currentText = textEditingController.text.trim();
    if (currentText.isBlank && !state.childhoodMemoirOnly.value) {
      clear();
      return;
    }
    state.isSearching.value = true;

    if (currentText.isBlank) {
      final memoirList = await IsarUtil.searchDiariesByTag(
        DiaryTemplateConst.memoirTag,
        domain: domain,
      );
      final legacyMemoirList = await IsarUtil.searchDiariesByTag(
        DiaryTemplateConst.legacyMemoirTag,
        domain: domain,
      );
      final merged = <int, Diary>{};
      for (final diary in [...memoirList, ...legacyMemoirList]) {
        merged[diary.isarId] = diary;
      }
      state.searchList = merged.values.toList();
      state.queryList = [];
      state.totalCount.value = state.searchList.length;
      state.isSearching.value = false;
      return;
    }

    final queryList = await JiebaRs.cutForSearch(text: currentText, hmm: true);
    final searchList = await IsarUtil.searchDiaries(
      queryList: queryList,
      domain: domain,
    );
    state.searchList = state.childhoodMemoirOnly.value
        ? searchList
              .where((diary) => DiaryTemplateConst.hasMemoirTag(diary.tags))
              .toList()
        : searchList;
    state.totalCount.value = state.searchList.length;
    state.queryList = queryList;
    state.isSearching.value = false;
  }
}
