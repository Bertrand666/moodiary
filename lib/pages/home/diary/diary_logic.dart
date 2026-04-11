import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moodiary/api/api.dart';
import 'package:moodiary/common/values/diary_domain.dart';
import 'package:moodiary/common/values/diary_template.dart';
import 'package:moodiary/common/values/view_mode.dart';
import 'package:moodiary/components/diary_tab_view/diary_tab_view_logic.dart';
import 'package:moodiary/components/scroll/fix_scroll.dart';
import 'package:moodiary/pages/home/home_logic.dart';
import 'package:moodiary/persistence/isar.dart';
import 'package:moodiary/persistence/pref.dart';
import 'package:moodiary/utils/cache_util.dart';
import 'package:moodiary/utils/webdav_util.dart';

import 'diary_state.dart';
import 'package:moodiary/common/values/pref_keys.dart';

class DiaryLogic extends GetxController with GetTickerProviderStateMixin {
  final DiaryDomain domain;
  late final DiaryState state = DiaryState(domain: domain);

  //初始化tab控制器，长度加一由于有一个默认分类
  late TabController tabController;

  late HomeLogic homeLogic = Bind.find<HomeLogic>();

  double lastScrollOffset = .0;

  DiaryLogic({required this.domain});

  @override
  void onInit() {
    if (domain == DiaryDomain.normal) {
      autoSync();
    }
    tabController = TabController(
      length: state.dynamicTags.length + 1,
      vsync: this,
    );
    super.onInit();
  }

  @override
  void onReady() {
    getHitokoto();
    //监听 tab
    tabController.addListener(_tabBarListener);
    //监听 inner
    state.innerController.addListener(_innerControllerListener);
    super.onReady();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  Future<void> getHitokoto() async {
    try {
      final res = await CacheUtil.getCacheList(
        PrefKeys.hitokoto,
        Api.updateHitokoto,
        maxAgeMillis: 15 * 60000,
      );
      if (res != null) {
        state.hitokoto.value = res.first;
      }
    } catch (e) {
      state.hitokoto.value = DateFormat.yMMMMEEEEd().format(DateTime.now());
    }
  }

  Future<void> autoSync() async {
    if (PrefUtil.getValue<bool>(PrefKeys.autoSync) == true &&
        await WebDavUtil().checkConnectivity()) {
      final diary = await IsarUtil.getAllDiaries();
      await WebDavUtil().syncDiary(
        diary,
        onDownload: () async {
          for (final domain in DiaryDomain.values) {
            if (Bind.isRegistered<DiaryLogic>(tag: domain.logicTag)) {
              await Bind.find<DiaryLogic>(tag: domain.logicTag).refreshAll();
            }
          }
        },
      );
    }
  }

  /// tab 监听函数
  /// 在动态更新分类后要重新监听
  void _tabBarListener() {
    if (tabController.indexIsChanging) return;
    checkPageChange();
    // 检查是否显示顶部内容
    _checkShowTop();
    homeLogic.resetNavigatorBar();
  }

  /// 跳转到指定动态标签
  void jumpToTag({required String? tagName}) {
    if (tagName == null) {
      tabController.animateTo(0);
      return;
    }
    final int index = state.dynamicTags.indexOf(tagName);
    if (index != -1) {
      tabController.animateTo(index + 1);
    }
  }

  /// inner controller 监听函数
  /// 用于分页
  void _innerControllerListener() async {
    final double offset = state.innerController.offset;
    final double maxScrollExtent =
        state.innerController.position.maxScrollExtent;
    _checkShowTop();
    if (offset - lastScrollOffset > 100) {
      lastScrollOffset = offset;
      await homeLogic.hideNavigatorBar();
    }
    if (lastScrollOffset - offset > 100) {
      lastScrollOffset = offset;
      await homeLogic.showNavigatorBar();
    }
    if (offset == maxScrollExtent) {
      if (tabController.index == 0) {
        await Bind.find<DiaryTabViewLogic>(
          tag: domain.defaultTabTag,
        ).paginationDiary();
      } else {
        final tagName = state.dynamicTags[tabController.index - 1];
        await Bind.find<DiaryTabViewLogic>(
          tag: domain.tabTag(tagName),
        ).paginationDiary();
      }
    }
  }

  /// 检查回到顶部函数
  /// 通过检测inner controller实现
  /// 需要注意的是，可能需要随时手动刷新
  ///
  /// 以下时候需要调用
  /// 1. 在inner中滑动时
  /// 2. tab切换时
  /// 3. view mode刷新时（实际上肯定在顶部，干脆直接改state）
  void _checkShowTop() {
    if (state.innerController.hasClients) {
      if (homeLogic.isToTopShow.value != state.innerController.offset > 100) {
        homeLogic.isToTopShow.value = state.innerController.offset > 100;
      }
    } else {
      homeLogic.isToTopShow.value = false;
    }
  }

  /// 自定义 PrimaryController 的修改
  /// 需要在以下情况调用
  /// 1. tab bar 修改
  /// 2. update ho
  void checkPageChange() {
    state.currentTabBarIndex = tabController.index;
    // 获取当前动态Tag，若为默认分类，设为 'default'
    final String currentTabTag = state.currentTabBarIndex == 0
        ? domain.defaultTabTag
        : domain.tabTag(state.dynamicTags[state.currentTabBarIndex - 1]);
    // 遍历 keyMap，更新每个页面的状态
    state.keyMap.forEach((k, v) {
      v.currentState?.onPageChange(k == currentTabTag);
    });
  }

  /// 日记刷新函数
  /// 需要在以下情况调用
  ///
  /// 1. 新增日记之后
  /// 2. 回收站恢复日记之后
  /// 3. 编辑时修改了分类
  Future<void> updateDiary(String? tagName, {bool jump = true}) async {
    int tabViewIndex;
    if (tagName == null) {
      tabViewIndex = 0;
      if (jump && tabController.index != 0) {
        tabController.animateTo(0);
      }
    } else {
      //查找Tag对应位置
      tabViewIndex = state.dynamicTags.indexOf(tagName) + 1;
      // 如果没有这个Tag，tabViewIndex 将返回 0，这刚好不会跳错；如果跳，我们可以安全地跳
      if (jump && tabViewIndex > 0 && tabController.index != tabViewIndex) {
        tabController.animateTo(tabViewIndex);
      }
    }
    if (tabViewIndex != 0 && Bind.isRegistered<DiaryTabViewLogic>(tag: domain.tabTag(tagName))) {
      await Bind.find<DiaryTabViewLogic>(
        tag: domain.tabTag(tagName),
      ).updateDiary();
    }
    await Bind.find<DiaryTabViewLogic>(tag: domain.defaultTabTag).updateDiary();
  }

  Future<void> refreshAll() async {
    await updateDynamicTags();
    await updateDiary(null, jump: true);
    await Future.wait(
      state.dynamicTags.map(
        (tag) => updateDiary(tag, jump: false),
      ),
    );
  }

  /// 动态标签刷新函数
  /// 收集当前域下所有日记的标签，提取频次最高的 Top 5
  Future<void> updateDynamicTags() async {
    final diaries = await IsarUtil.getAllDiaries(domain: domain);
    final tagCounts = <String, int>{};
    for (var diary in diaries) {
      for (var tag in diary.tags) {
        // 排除保留的特定内置tag (如回忆录等)
        if (tag == DiaryTemplateConst.memoirTag || tag == DiaryTemplateConst.legacyMemoirTag) continue;
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // 降序排列
    
    // 只取前 5 个标签
    state.dynamicTags = sortedTags.take(5).map((e) => e.key).toList();

    // 移除 Map 中不再存在的 Tag
    state.keyMap.removeWhere(
      (k, v) =>
          !state.dynamicTags
              .map((tag) => domain.tabTag(tag))
              .contains(k) &&
          k != domain.defaultTabTag,
    );

    // 为新的 Tag 添加新的 GlobalKey
    for (final tag in state.dynamicTags) {
      final tabToken = domain.tabTag(tag);
      if (!state.keyMap.containsKey(tabToken)) {
        state.keyMap[tabToken] = GlobalKey<PrimaryScrollWrapperState>();
      }
    }
    //重新初始化Tab控制器
    state.currentTabBarIndex = tabController.index;
    //如果删除了最后一个，就往左移
    if (state.dynamicTags.length < state.currentTabBarIndex) {
      state.currentTabBarIndex = state.dynamicTags.length;
    }

    //重新创建控制器
    tabController.removeListener(_tabBarListener);
    tabController = TabController(
      length: state.dynamicTags.length + 1,
      vsync: this,
      initialIndex: state.currentTabBarIndex,
    );
    tabController.addListener(_tabBarListener);
    update();
    checkPageChange();
  }

  //切换视图模式
  Future<void> changeViewMode(ViewModeType viewModeType) async {
    state.viewModeType.value = viewModeType;
    _checkShowTop();
    await PrefUtil.setValue<int>(PrefKeys.homeViewMode, viewModeType.number);
  }

  // 回到顶部函数
  Future<void> toTop() async {
    await state.innerController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  // 更新标题
  void updateTitle() {
    state.customTitleName.value = PrefUtil.getValue<String>(PrefKeys.customTitleName)!;
    state.customSubTitleName.value = PrefUtil.getValue<String>(PrefKeys.customSubTitleName)!;
  }
}
