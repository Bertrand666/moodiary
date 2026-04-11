import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moodiary/common/values/home_tabs.dart';
import 'package:moodiary/components/base/modal.dart';
import 'package:moodiary/l10n/l10n.dart';

class HomeNavigatorBar extends StatelessWidget {
  static const double defaultNavigatorBarHeight = 56.0;

  final Animation<double> animation;

  final RxInt navigatorIndex;

  final RxList<HomeTab> activeTabs;

  final Function(int) onTap;

  final Modal modal;

  const HomeNavigatorBar({
    super.key,
    required this.animation,
    required this.navigatorIndex,
    required this.activeTabs,
    required this.onTap,
    required this.modal,
  });

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);

    final navigatorBarHeight = defaultNavigatorBarHeight + padding.bottom;
    return Visibility(
      visible: size.width < 600,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return SizedBox(
            height: (navigatorBarHeight) * animation.value,
            child: child,
          );
        },
        child: OverflowBox(
          maxHeight: navigatorBarHeight,
          alignment: Alignment.topCenter,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: context.theme.colorScheme.outline.withValues(
                    alpha: 0.5,
                  ),
                  width: 0.5,
                ),
              ),
            ),
            child: Stack(
              children: [
                Obx(() {
                  return NavigationBar(
                    destinations: activeTabs.map((tab) {
                      return NavigationDestination(
                        icon: Icon(tab.outlinedIcon),
                        label: tab.label(context),
                        selectedIcon: Icon(tab.filledIcon),
                      );
                    }).toList(),
                    selectedIndex: navigatorIndex.value.clamp(0, activeTabs.length - 1),
                    height: navigatorBarHeight,
                    onDestinationSelected: onTap,
                    backgroundColor: context.theme.colorScheme.surfaceContainer,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysHide,
                  );
                }),
                modal,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
