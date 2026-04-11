import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moodiary/common/values/home_tabs.dart';
import 'package:moodiary/pages/home/home_logic.dart';

/// 导航栏自定义对话框
/// 支持拖拽排序 + 开关各 Tab（Setting 不可关闭）
class NavTabsManagerSheet extends StatefulWidget {
  const NavTabsManagerSheet({super.key});

  @override
  State<NavTabsManagerSheet> createState() => _NavTabsManagerSheetState();
}

class _NavTabsManagerSheetState extends State<NavTabsManagerSheet> {
  late List<HomeTab> _ordered;
  late Set<HomeTab> _enabled;

  @override
  void initState() {
    super.initState();
    final logic = Bind.find<HomeLogic>();
    _ordered = List<HomeTab>.from(HomeTab.defaultTabs); // 保持默认枚举顺序用于全体展示
    // 当前已激活的 Tab（含顺序）
    final active = List<HomeTab>.from(logic.activeTabs);
    _enabled = active.toSet();
    // 以当前激活顺序为基准重排 _ordered
    final inactive = HomeTab.values.where((t) => !_enabled.contains(t)).toList();
    _ordered = [...active, ...inactive];
  }

  List<HomeTab> get _resultTabs =>
      _ordered.where((t) => _enabled.contains(t)).toList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '导航栏布局',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '长按拖拽可调整顺序，「设置」不可隐藏',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    await Bind.find<HomeLogic>().setActiveTabs(_resultTabs);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('完成'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _ordered.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _ordered.removeAt(oldIndex);
                _ordered.insert(newIndex, item);
              });
            },
            itemBuilder: (context, i) {
              final tab = _ordered[i];
              final isSetting = tab == HomeTab.setting;
              final isEnabled = _enabled.contains(tab);
              return ListTile(
                key: ValueKey(tab),
                leading: Icon(
                  isEnabled ? tab.filledIcon : tab.outlinedIcon,
                  color: isEnabled
                      ? context.theme.colorScheme.primary
                      : context.theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.4),
                ),
                title: Text(
                  tab.label(context),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: isEnabled
                        ? null
                        : context.theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: isEnabled,
                      onChanged: isSetting
                          ? null // 设置不可关闭
                          : (value) {
                              setState(() {
                                if (value) {
                                  _enabled.add(tab);
                                } else {
                                  _enabled.remove(tab);
                                }
                              });
                            },
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.drag_handle_rounded),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
        ],
      ),
    );
  }
}
