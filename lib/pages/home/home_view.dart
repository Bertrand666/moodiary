import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:get/get.dart';
import 'package:moodiary/common/values/diary_domain.dart';
import 'package:moodiary/common/values/diary_template.dart';
import 'package:moodiary/common/values/diary_type.dart';
import 'package:moodiary/common/values/home_tabs.dart';
import 'package:moodiary/components/base/modal.dart';
import 'package:moodiary/components/desktop_wrapper/background.dart';
import 'package:moodiary/components/home_fab/home_fab_view.dart';
import 'package:moodiary/components/home_nativatorbar/navigatorbar.dart';
import 'package:moodiary/l10n/l10n.dart';
import 'package:moodiary/pages/home/calendar/calendar_view.dart';
import 'package:moodiary/pages/home/diary/diary_view.dart';
import 'package:moodiary/pages/home/media/media_view.dart';
import 'package:moodiary/pages/home/setting/setting_view.dart';

import 'home_logic.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// 根据 HomeTab 创建对应的 Page Widget
  static Widget _buildPageForTab(HomeTab tab) {
    switch (tab) {
      case HomeTab.diary:
        return const DiaryPage(domain: DiaryDomain.normal);
      case HomeTab.memoir:
        return const DiaryPage(domain: DiaryDomain.memoir);
      case HomeTab.calendar:
        return const CalendarPage();
      case HomeTab.media:
        return const MediaPage();
      case HomeTab.setting:
        return const SettingPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final HomeLogic logic = Get.put(HomeLogic());

    return Scaffold(
      body: Stack(
        children: [
          AdaptiveLayout(
            transitionDuration: const Duration(milliseconds: 200),
            primaryNavigation: SlotLayout(
              config: {
                Breakpoints.mediumAndUp: SlotLayout.from(
                  key: const ValueKey('navigation medium'),
                  builder: (_) {
                    // 侧边导航：用 Obx 包裹以响应 activeTabs 变化
                    return Obx(() {
                      final tabs = logic.activeTabs;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        color: context.theme.colorScheme.surfaceContainer,
                        child: AdaptiveScaffold.standardNavigationRail(
                          destinations: tabs
                              .map(
                                (tab) => NavigationDestination(
                                  icon: Icon(tab.outlinedIcon),
                                  label: tab.label(context),
                                  selectedIcon: Icon(tab.filledIcon),
                                ),
                              )
                              .map(AdaptiveScaffold.toRailDestination)
                              .toList(),
                          selectedIndex: logic.navigatorIndex.value
                              .clamp(0, tabs.length - 1),
                          backgroundColor:
                              context.theme.colorScheme.surfaceContainer,
                          labelType: NavigationRailLabelType.all,
                          padding: EdgeInsets.zero,
                          trailing: Expanded(
                            child: DesktopHomeFabComponent(
                              isToTopShow: logic.isToTopShow,
                              toTop: logic.toTop,
                              toMarkdown: () async {
                                await logic.toEditPage(
                                  type: DiaryType.markdown,
                                );
                              },
                              toPlainText: () async {
                                await logic.toEditPage(type: DiaryType.text);
                              },
                              toRichText: () async {
                                await logic.toEditPage(
                                  type: DiaryType.richText,
                                  template: logic.currentDomain ==
                                          DiaryDomain.memoir
                                      ? DiaryTemplate.memoir
                                      : null,
                                );
                              },
                            ),
                          ),
                          onDestinationSelected: logic.changeNavigator,
                        ),
                      );
                    });
                  },
                ),
              },
            ),
            body: SlotLayout(
              config: {
                Breakpoints.standard: SlotLayout.from(
                  key: const ValueKey('body'),
                  builder: (_) {
                    return AdaptiveBackground(
                      // PageView 的 children 由 activeTabs 决定，用 Obx 包裹
                      child: Obx(() {
                        final tabs = logic.activeTabs;
                        return PageView(
                          key: logic.bodyKey,
                          controller: logic.pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: tabs.map(_buildPageForTab).toList(),
                        );
                      }),
                    );
                  },
                ),
              },
            ),
          ),
          Modal(onTap: logic.closeFab, animation: logic.fabAnimation),
        ],
      ),
      bottomNavigationBar: HomeNavigatorBar(
        animation: logic.barAnimation,
        navigatorIndex: logic.navigatorIndex,
        activeTabs: logic.activeTabs,
        onTap: logic.changeNavigator,
        modal: Modal(onTap: logic.closeFab, animation: logic.fabAnimation),
      ),
      floatingActionButton: HomeFabComponent(
        animation: logic.fabAnimation,
        shouldShow: logic.shouldShow,
        isToTopShow: logic.isToTopShow,
        isExpanded: logic.isFabExpanded,
        showShadow: true,
        toTop: logic.toTop,
        toMarkdown: () async {
          await logic.toEditPage(type: DiaryType.markdown);
        },
        toPlainText: () async {
          await logic.toEditPage(type: DiaryType.text);
        },
        toRichText: () async {
          await logic.toEditPage(
            type: DiaryType.richText,
            template: logic.currentDomain == DiaryDomain.memoir
                ? DiaryTemplate.memoir
                : null,
          );
        },
        closeFab: logic.closeFab,
        openFab: logic.openFab,
      ),
    );
  }
}
