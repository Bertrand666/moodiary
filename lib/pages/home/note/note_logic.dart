import 'dart:async';

import 'package:get/get.dart';
import 'package:moodiary/common/models/isar/diary.dart';
import 'package:moodiary/common/values/diary_domain.dart';
import 'package:moodiary/common/values/diary_type.dart';
import 'package:moodiary/common/values/view_mode.dart';
import 'package:moodiary/pages/edit/edit_args.dart';
import 'package:moodiary/persistence/isar.dart';
import 'package:moodiary/persistence/pref.dart';
import 'package:moodiary/router/app_routes.dart';
import 'package:moodiary/components/diary_tab_view/diary_tab_view_logic.dart';
import 'package:moodiary/common/values/pref_keys.dart';
import 'package:moodiary/src/rust/api/jieba.dart';

import 'note_state.dart';

class NoteLogic extends GetxController {
  final NoteState state = NoteState();

  @override
  void onReady() {
    unawaited(loadNotes());
    super.onReady();
  }

  @override
  void onClose() {
    state.inputController.dispose();
    super.onClose();
  }

  /// 从 Isar 加载所有随手记（降序）
  Future<void> loadNotes() async {
    state.isLoading.value = true;
    final all = await IsarUtil.getAllDiariesSorted();
    final noteList = all.where((d) => d.domain == DiaryDomain.note.value && d.show).toList();

    // 一次性数据迁移/兼容：为早期没有填充 tokenizer 的随手记补充该字段，让搜索能够命中历史数据
    for (var note in noteList) {
      if (note.tokenizer.isEmpty && note.contentText.isNotEmpty) {
        note.tokenizer = await JiebaRs.cutAll(text: note.contentText);
        await IsarUtil.updateADiary(oldDiary: note, newDiary: note);
      }
    }

    state.notes.assignAll(noteList);
    state.isLoading.value = false;
  }

  /// 保存一条随手记（纯文本，自动解析 #标签）
  Future<void> addNote() async {
    final raw = state.inputController.text.trim();
    if (raw.isEmpty) return;

    // 解析 #标签
    final tagRegex = RegExp(r'#(\S+)');
    final tags = tagRegex
        .allMatches(raw)
        .map((m) => m.group(1)!)
        .toSet()
        .toList();
    final contentText = raw.replaceAll(tagRegex, '').trim();

    // 分词（用于全文搜索）
    final tokenizer = await JiebaRs.cutAll(text: contentText);

    final diary = Diary()
      ..domain = DiaryDomain.note.value
      ..type = DiaryType.text.value
      ..title = ''
      ..content = contentText
      ..contentText = contentText
      ..tags = tags
      ..tokenizer = tokenizer
      ..time = DateTime.now()
      ..lastModified = DateTime.now()
      ..show = true;

    await IsarUtil.insertADiary(diary);

    // 触发当前随手记分类 Tab 的更新
    if (Bind.isRegistered<DiaryTabViewLogic>(tag: DiaryDomain.note.defaultTabTag)) {
      Bind.find<DiaryTabViewLogic>(tag: DiaryDomain.note.defaultTabTag).updateDiary();
    }

    state.inputController.clear();
    state.isComposing.value = false;
  }

  /// 软删除（移入回收站）
  Future<void> deleteNote(Diary note) async {
    note.show = false;
    await IsarUtil.updateADiary(newDiary: note);
    state.notes.remove(note);
  }

  /// 点击卡片进入编辑页（传入 Diary 对象，编辑模式）
  Future<void> editNote(Diary note) async {
    final res = await Get.toNamed(
      AppRoutes.editPage,
      arguments: note,  // 传 Diary → edit_logic 走编辑分支
    );
    // 返回后刷新列表
    if (res != null) {
      await loadNotes();
    }
  }

  /// 更新副标题（从设置页回来后调用）
  void updateSubTitle() {
    state.customSubTitleName.value =
        PrefUtil.getValue<String>(PrefKeys.customSubTitleName) ?? '';
  }

  /// 切换视图模式
  Future<void> changeViewMode(ViewModeType targetMode) async {
    if (state.viewModeType.value == targetMode) {
      return;
    }
    state.viewModeType.value = targetMode;
    // 将状态保存到全局
    await PrefUtil.setValue(PrefKeys.homeViewMode, targetMode.number);
  }
}
