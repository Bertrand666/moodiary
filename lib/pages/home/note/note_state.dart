import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moodiary/common/models/isar/diary.dart';
import 'package:moodiary/common/values/view_mode.dart';
import 'package:moodiary/persistence/pref.dart';
import 'package:moodiary/common/values/pref_keys.dart';

class NoteState {
  /// 视图模式状态
  late Rx<ViewModeType> viewModeType = ViewModeType.getType(
    PrefUtil.getValue<int>(PrefKeys.homeViewMode)!,
  ).obs;

  /// 笔记列表（按时间倒序）
  RxList<Diary> notes = <Diary>[].obs;

  /// 行内输入框控制器
  final TextEditingController inputController = TextEditingController();

  /// 是否正在输入（控制发送按钮样式）
  RxBool isComposing = false.obs;

  /// 是否正在加载
  RxBool isLoading = true.obs;

  /// 副标题（与日记页共享同一 PrefKey）
  RxString customSubTitleName =
      (PrefUtil.getValue<String>(PrefKeys.customSubTitleName) ?? '').obs;
}
