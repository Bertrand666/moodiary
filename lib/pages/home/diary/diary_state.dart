import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moodiary/common/models/isar/category.dart';
import 'package:moodiary/common/values/diary_domain.dart';
import 'package:moodiary/common/values/view_mode.dart';
import 'package:moodiary/components/scroll/fix_scroll.dart';
import 'package:moodiary/persistence/isar.dart';
import 'package:moodiary/persistence/pref.dart';
import 'package:moodiary/common/values/pref_keys.dart';
import 'package:moodiary/common/values/diary_template.dart';

class DiaryState {
  final DiaryDomain domain;

  //自定义标题名称，如果为空则为默认值
  late RxString customTitleName;

  //自定义副标题名称，如果不为空则替代一言
  late RxString customSubTitleName;

  // 动态标签列表，用于 tab 显示 (提取该 domain 下最热门的前 N 个标签)
  late List<String> dynamicTags;

  //分类列表对应的key map，key是列表id
  late Map<String, GlobalKey<PrimaryScrollWrapperState>> keyMap;

  //主滚动列表key
  late GlobalKey<NestedScrollViewState> nestedScrollKey;

  ScrollController get innerController =>
      nestedScrollKey.currentState!.innerController;

  ScrollController get outerController =>
      nestedScrollKey.currentState!.outerController;

  //视图模式状态
  late Rx<ViewModeType> viewModeType = ViewModeType.getType(
    PrefUtil.getValue<int>(PrefKeys.homeViewMode)!,
  ).obs;

  //当前tab bar位置
  late int currentTabBarIndex;

  // 一言
  RxString hitokoto = '...'.obs;

  DiaryState({required this.domain}) {
    customTitleName = PrefUtil.getValue<String>(PrefKeys.customTitleName)!.obs;
    customSubTitleName = PrefUtil.getValue<String>(PrefKeys.customSubTitleName)!.obs;

    nestedScrollKey = GlobalKey<NestedScrollViewState>();

    currentTabBarIndex = 0;

    // 初始化动态标签：同步读取所有日记并提取最常用的5个标签
    final diaries = IsarUtil.getAllDiariesSync(domain: domain);
    final tagCounts = <String, int>{};
    for (var diary in diaries) {
      for (var tag in diary.tags) {
        if (tag == DiaryTemplateConst.memoirTag || tag == DiaryTemplateConst.legacyMemoirTag) continue;
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    final sortedTags = tagCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    dynamicTags = sortedTags.take(5).map((e) => e.key).toList();

    // 默认分类 key
    keyMap = {domain.defaultTabTag: GlobalKey<PrimaryScrollWrapperState>()};
    for (final tag in dynamicTags) {
      keyMap[domain.tabTag(tag)] = GlobalKey<PrimaryScrollWrapperState>();
    }
  }
}
