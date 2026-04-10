import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moodiary/common/values/diary_domain.dart';
import 'package:moodiary/common/values/diary_template.dart';
import 'package:moodiary/common/values/diary_type.dart';
import 'package:moodiary/components/frosted_glass_overlay/frosted_glass_overlay_logic.dart';
import 'package:moodiary/pages/edit/edit_args.dart';
import 'package:moodiary/pages/home/diary/diary_logic.dart';
import 'package:moodiary/persistence/pref.dart';
import 'package:moodiary/router/app_routes.dart';
import 'package:moodiary/common/values/pref_keys.dart';

class HomeLogic extends GetxController with GetTickerProviderStateMixin {
  RxBool isFabExpanded = false.obs;

  RxBool isToTopShow = false.obs;

  RxBool shouldShow = true.obs;

  RxInt navigatorIndex = 0.obs;

  late final GlobalKey bodyKey = GlobalKey();
  late final AnimationController _fabAnimationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  late Animation<double> fabAnimation = Tween(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
  );

  late final AnimationController _barAnimationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  late Animation<double> barAnimation = Tween(begin: 1.0, end: 0.0).animate(
    CurvedAnimation(parent: _barAnimationController, curve: Curves.easeInOut),
  );

  late final PageController pageController = PageController();

  late final FrostedGlassOverlayLogic frostedGlassOverlayLogic =
      Bind.find<FrostedGlassOverlayLogic>();

  late final AppLifecycleListener _appLifecycleListener;

  DiaryDomain get currentDomain =>
      navigatorIndex.value == 1 ? DiaryDomain.memoir : DiaryDomain.normal;

  @override
  void onReady() async {
    _appLifecycleListener = AppLifecycleListener(
      onStateChange: (state) {
        if (state == AppLifecycleState.inactive) {
          _privacyMode(isEnable: true);
          _lockPage();
        }
        if (state == AppLifecycleState.resumed) {
          _privacyMode(isEnable: false);
        }
      },
    );

    super.onReady();
  }

  @override
  void onClose() {
    _fabAnimationController.dispose();
    _barAnimationController.dispose();
    pageController.dispose();
    _appLifecycleListener.dispose();
    super.onClose();
  }

  void _lockPage() {
    if (PrefUtil.getValue<bool>(PrefKeys.lock) == true &&
        PrefUtil.getValue<bool>(PrefKeys.lockNow) == true) {
      if (Get.currentRoute != AppRoutes.editPage &&
          Get.currentRoute != AppRoutes.sharePage) {
        Get.toNamed(AppRoutes.lockPage, arguments: 'pause');
      }
    }
  }

  void _privacyMode({required bool isEnable}) {
    if (PrefUtil.getValue<bool>(PrefKeys.backendPrivacy) == true) {
      isEnable
          ? frostedGlassOverlayLogic.enable()
          : frostedGlassOverlayLogic.disable();
    }
  }

  Future<void> openFab() async {
    await HapticFeedback.vibrate();
    isFabExpanded.value = true;
    await _fabAnimationController.forward();
  }

  Future<void> closeFab() async {
    await HapticFeedback.selectionClick();
    await _fabAnimationController.reverse();
    isFabExpanded.value = false;
  }

  Future<void> toTop() async {
    final tag = currentDomain.logicTag;
    if (Bind.isRegistered<DiaryLogic>(tag: tag)) {
      await Bind.find<DiaryLogic>(tag: tag).toTop();
    }
  }

  void changeNavigator(int index) {
    navigatorIndex.value = index;
    shouldShow.value = index == 0 || index == 1;
    pageController.jumpToPage(index);
  }

  Future<void> hideNavigatorBar() async {
    await _barAnimationController.forward();
  }

  Future<void> showNavigatorBar() async {
    await _barAnimationController.reverse();
  }

  void resetNavigatorBar() {
    _barAnimationController.reset();
  }

  Future<void> toEditPage({
    DiaryDomain? domain,
    required DiaryType type,
    DiaryTemplate? template,
  }) async {
    HapticFeedback.selectionClick();
    final targetDomain = domain ?? currentDomain;
    final logicTag = targetDomain.logicTag;
    final DiaryLogic? diaryLogic =
        Bind.isRegistered<DiaryLogic>(tag: logicTag)
            ? Bind.find<DiaryLogic>(tag: logicTag)
            : null;
    String? categoryId;
    if (diaryLogic == null || diaryLogic.tabController.index == 0) {
      categoryId = null;
    } else {
      categoryId = diaryLogic
          .state
          .categoryList[diaryLogic.tabController.index - 1]
          .id;
    }

    /// 需要注意，返回值为 '' 时才是没有选择分类，而返回值为 null 时，是没有进行操作直接返回
    final res = await Get.toNamed(
      AppRoutes.editPage,
      arguments: EditCreateArgs(
        domain: targetDomain,
        type: type,
        categoryId: categoryId,
        template: template,
      ),
    );
    _fabAnimationController.reset();
    isFabExpanded.value = false;
    if (res != null && diaryLogic != null) {
      if (res == '') {
        await diaryLogic.updateDiary(null);
      } else {
        await diaryLogic.updateDiary(res);
      }
    }
  }
}
