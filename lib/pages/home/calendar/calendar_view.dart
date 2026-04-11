import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:moodiary/common/values/border.dart';
import 'package:moodiary/common/values/colors.dart';
import 'package:moodiary/common/values/diary_domain.dart';
import 'package:moodiary/components/base/loading.dart';
import 'package:moodiary/components/diary_card/demo_unified_card.dart';
import 'package:moodiary/components/time_line/time_line_view.dart';
import 'package:moodiary/l10n/l10n.dart';
import 'package:moodiary/utils/array_util.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'calendar_logic.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  /// 根据 DiaryDomain 返回对应的时间线圆点颜色
  Color _domainColor(DiaryDomain domain, ColorScheme cs) {
    switch (domain) {
      case DiaryDomain.normal:
        return cs.primary;
      case DiaryDomain.memoir:
        return cs.tertiary;
      case DiaryDomain.note:
        return cs.secondary;
    }
  }

  /// 根据当天日记的数量配置颜色的范围，从0到1
  double getDayColor({required int count}) {
    if (count == 0) return 0;
    if (count >= 5) return 1;
    return count / 5;
  }

  Widget _buildActiveInfo({
    required Color lessColor,
    required Color moreColor,
    required TextStyle? textStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        spacing: 2.0,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('少', style: textStyle),
          ...List.generate(5, (index) {
            return Container(
              width: 12.0,
              height: 12.0,
              decoration: BoxDecoration(
                color: Color.lerp(lessColor, moreColor, (index + 1) / 5),
                borderRadius: BorderRadius.circular(4.0),
              ),
            );
          }),
          Text('多', style: textStyle),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logic = Get.put(CalendarLogic());
    final state = Bind.find<CalendarLogic>().state;

    final size = MediaQuery.sizeOf(context);

    // ── 日历选择器 ───────────────────────────────────────────────
    Widget buildDatePicker() {
      final dateWithDiaryList = <DateTime>[];
      final allDate = <DateTime>[];
      for (final diary in state.currentMonthDiaryList) {
        final time = diary.time;
        allDate.add(DateTime(time.year, time.month, time.day));
        if (!dateWithDiaryList.contains(
          DateTime(time.year, time.month, time.day),
        )) {
          dateWithDiaryList.add(DateTime(time.year, time.month, time.day));
        }
      }
      final dateCountMap = ArrayUtil.countList(allDate);

      return Stack(
        children: [
          Card.filled(
            color: context.theme.colorScheme.surfaceContainerLow,
            margin: EdgeInsets.zero,
            child: Obx(() {
              return CalendarDatePicker2(
                displayedMonthDate: state.currentMonth.value,
                config: CalendarDatePicker2Config(
                  calendarViewMode: CalendarDatePicker2Mode.day,
                  calendarType: CalendarDatePicker2Type.single,
                  hideMonthPickerDividers: true,
                  hideYearPickerDividers: true,
                  useAbbrLabelForMonthModePicker: true,
                  allowSameValueSelection: true,
                  dayBuilder: ({
                    required DateTime date,
                    TextStyle? textStyle,
                    BoxDecoration? decoration,
                    bool? isSelected,
                    bool? isDisabled,
                    bool? isToday,
                  }) {
                    final contains = dateWithDiaryList.contains(date);
                    final bgColor =
                        contains
                            ? Color.lerp(
                              context.theme.colorScheme.surfaceContainer,
                              context.theme.colorScheme.primary,
                              getDayColor(count: dateCountMap[date] ?? 0),
                            )
                            : null;
                    return Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: bgColor,
                        ),
                        child: Center(
                          child: Text(
                            date.day.toString(),
                            style: textStyle?.copyWith(
                              color:
                                  contains
                                      ? ThemeData.estimateBrightnessForColor(
                                                bgColor!,
                                              ) ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black
                                      : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  selectableDayPredicate: (DateTime date) {
                    return dateWithDiaryList.contains(date);
                  },
                ),
                onValueChanged: (value) {
                  logic.animateToSelectedDateWithLock(value.first);
                },
                onDisplayedMonthChanged: (value) async {
                  final lastDate = logic.findLatestDateInMonth(
                    dateWithDiaryList,
                    value.year,
                    value.month,
                  );
                  if (lastDate != null) {
                    await logic.animateToSelectedDateWithLock(lastDate);
                  }
                },
                value: const [],
              );
            }),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: _buildActiveInfo(
              lessColor: context.theme.colorScheme.surfaceContainer,
              moreColor: context.theme.colorScheme.primary,
              textStyle: context.textTheme.labelSmall?.copyWith(
                color: context.theme.colorScheme.onSurface.withValues(
                  alpha: 0.8,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // ── 筛选芯片行 ───────────────────────────────────────────────
    Widget buildFilterChips() {
      return Obx(() {
        final current = state.domainFilter.value;

        final chips = <Widget>[
          // 全部
          FilterChip(
            selected: current == null,
            showCheckmark: false,
            label: const Text('全部'),
            avatar: current == null
                ? null
                : const Icon(Icons.apps_rounded, size: 14),
            onSelected: (_) => logic.setDomainFilter(null),
          ),
          // 日记
          FilterChip(
            selected: current == DiaryDomain.normal,
            showCheckmark: false,
            selectedColor: context.theme.colorScheme.primaryContainer,
            avatar: CircleAvatar(
              radius: 5,
              backgroundColor: context.theme.colorScheme.primary,
            ),
            label: Text(context.l10n.homeNavigatorDiary),
            onSelected: (_) => logic.setDomainFilter(DiaryDomain.normal),
          ),
          // 回忆录
          FilterChip(
            selected: current == DiaryDomain.memoir,
            showCheckmark: false,
            selectedColor: context.theme.colorScheme.tertiaryContainer,
            avatar: CircleAvatar(
              radius: 5,
              backgroundColor: context.theme.colorScheme.tertiary,
            ),
            label: Text(context.l10n.homeNavigatorMemoir),
            onSelected: (_) => logic.setDomainFilter(DiaryDomain.memoir),
          ),
          // 随手记
          FilterChip(
            selected: current == DiaryDomain.note,
            showCheckmark: false,
            selectedColor: context.theme.colorScheme.secondaryContainer,
            avatar: CircleAvatar(
              radius: 5,
              backgroundColor: context.theme.colorScheme.secondary,
            ),
            label: const Text('随手记'),
            onSelected: (_) => logic.setDomainFilter(DiaryDomain.note),
          ),
        ];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            spacing: 8,
            children: chips,
          ),
        );
      });
    }

    // ── 时间线条目 ───────────────────────────────────────────────
    Widget buildCardList() {
      return Obx(() {
        final list = state.filteredList;
        if (list.isEmpty) {
          return Center(
            key: const ValueKey('filtered-empty'),
            child: FaIcon(
              FontAwesomeIcons.boxOpen,
              color: context.theme.colorScheme.onSurface,
              size: 56,
            ),
          );
        }
        return ScrollablePositionedList.builder(
          itemBuilder: (context, index) {
            final diary = list[index];
            final domain = DiaryDomain.fromValue(diary.domain);
            final dotColor = state.domainFilter.value != null
                // 单一筛选时退回情绪色
                ? Color.lerp(
                    AppColor.emoColorList.first,
                    AppColor.emoColorList.last,
                    diary.mood,
                  )!
                : _domainColor(domain, context.theme.colorScheme);
            return TimeLineComponent(
              actionColor: dotColor,
              child: Padding(
                padding: EdgeInsets.only(
                  top: index == 0 ? 0 : 4.0,
                  bottom: index == list.length - 1 ? 0 : 4.0,
                ),
                child: DemoUnifiedCard(diary: diary),
              ),
            );
          },
          itemScrollController: logic.itemScrollController,
          itemPositionsListener: logic.itemPositionsListener,
          scrollOffsetController: logic.scrollOffsetController,
          scrollOffsetListener: logic.scrollOffsetListener,
          itemCount: list.length,
        );
      });
    }

    final calendar = Obx(() => buildDatePicker());

    final diaryBody = ClipRRect(
      borderRadius: AppBorderRadius.mediumBorderRadius,
      child: Obx(() {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child:
              state.isFetching.value
                  ? const MoodiaryLoading()
                  : (state.currentMonthDiaryList.isNotEmpty
                      ? buildCardList()
                      : Center(
                        key: const ValueKey('empty'),
                        child: FaIcon(
                          FontAwesomeIcons.boxOpen,
                          color: context.theme.colorScheme.onSurface,
                          size: 56,
                        ),
                      )),
        );
      }),
    );

    return GetBuilder<CalendarLogic>(
      assignId: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: SafeArea(
            child:
                size.width > 600
                    ? Row(
                      spacing: 8.0,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              buildFilterChips(),
                              const SizedBox(height: 4),
                              Expanded(child: diaryBody),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(width: 320, child: calendar),
                        ),
                      ],
                    )
                    : Column(
                      spacing: 0,
                      children: [
                        calendar,
                        const SizedBox(height: 4),
                        buildFilterChips(),
                        const SizedBox(height: 4),
                        Expanded(child: diaryBody),
                      ],
                    ),
          ),
        );
      },
    );
  }
}
