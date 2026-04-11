import 'package:flutter/material.dart';
import 'package:moodiary/l10n/l10n.dart';
import 'package:unicons/unicons.dart';

/// 主页导航 Tab 枚举
enum HomeTab {
  diary,
  memoir,
  note,
  calendar,
  media,
  setting;

  /// 序列化（存储到 SharedPreferences）
  String get key => name;

  /// 反序列化
  static HomeTab? fromKey(String key) {
    return HomeTab.values.where((e) => e.key == key).firstOrNull;
  }

  /// 默认全部顺序（未配置时使用）
  static const List<HomeTab> defaultTabs = [
    HomeTab.diary,
    HomeTab.memoir,
    HomeTab.note,
    HomeTab.calendar,
    HomeTab.media,
    HomeTab.setting,
  ];

  /// 未选中图标
  IconData get outlinedIcon {
    switch (this) {
      case HomeTab.diary:
        return Icons.article_outlined;
      case HomeTab.memoir:
        return Icons.auto_stories_outlined;
      case HomeTab.note:
        return Icons.edit_note_outlined;
      case HomeTab.calendar:
        return UniconsLine.calender;
      case HomeTab.media:
        return UniconsLine.image_v;
      case HomeTab.setting:
        return UniconsLine.layer_group;
    }
  }

  /// 已选中图标
  IconData get filledIcon {
    switch (this) {
      case HomeTab.diary:
        return Icons.article;
      case HomeTab.memoir:
        return Icons.auto_stories;
      case HomeTab.note:
        return Icons.edit_note;
      case HomeTab.calendar:
        return UniconsSolid.calender;
      case HomeTab.media:
        return UniconsSolid.image_v;
      case HomeTab.setting:
        return UniconsSolid.layer_group;
    }
  }

  /// 是否为日记类（用于控制 FAB 显示）
  bool get isDiaryType =>
      this == HomeTab.diary || this == HomeTab.memoir;

  /// 对应的 DiaryDomain（仅日记类有效）
  bool get isMemoir => this == HomeTab.memoir;

  /// 读取 l10n 标签（需要 BuildContext）
  String label(BuildContext context) {
    switch (this) {
      case HomeTab.diary:
        return context.l10n.homeNavigatorDiary;
      case HomeTab.memoir:
        return context.l10n.homeNavigatorMemoir;
      case HomeTab.note:
        return '随手记';
      case HomeTab.calendar:
        return context.l10n.homeNavigatorCalendar;
      case HomeTab.media:
        return context.l10n.homeNavigatorMedia;
      case HomeTab.setting:
        return context.l10n.homeNavigatorSetting;
    }
  }
}
