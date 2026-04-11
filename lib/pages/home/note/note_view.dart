import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moodiary/common/values/border.dart';
import 'package:moodiary/common/values/diary_domain.dart';
import 'package:moodiary/pages/home/diary/diary_view.dart';
import 'note_logic.dart';

class NotePage extends StatelessWidget {
  const NotePage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.put(NoteLogic());
    final state = logic.state;

    // ── 底部输入框 ──────────────────────────────────────────────
    Widget buildInputBar() {
      return Obx(() {
        return Card.filled(
          color: context.theme.colorScheme.surfaceContainerLow,
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.mediumBorderRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: state.inputController,
                    maxLines: 5,
                    minLines: 1,
                    style: context.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: '随手写点什么…',
                      hintStyle: context.textTheme.bodyMedium?.copyWith(
                        color: context.theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.fromLTRB(12, 10, 0, 10),
                    ),
                    onChanged: (v) {
                      state.isComposing.value = v.trim().isNotEmpty;
                    },
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: state.isComposing.value
                      ? Padding(
                          padding:
                              const EdgeInsets.only(right: 4, bottom: 4),
                          child: IconButton.filled(
                            key: const ValueKey('send'),
                            icon:
                                const Icon(Icons.arrow_upward_rounded, size: 20),
                            onPressed: () async {
                              HapticFeedback.selectionClick();
                              await logic.addNote();
                            },
                          ),
                        )
                      : const SizedBox(width: 8, key: ValueKey('empty')),
                ),
              ],
            ),
          ),
        );
      });
    }

    return Stack(
      children: [
        // 重用 DiaryPage 提供的全套分类栏与卡片瀑布流底层逻辑
        const DiaryPage(domain: DiaryDomain.note),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: buildInputBar(),
        ),
      ],
    );
  }
}
