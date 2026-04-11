import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moodiary/common/models/isar/diary.dart';
import 'package:moodiary/common/values/border.dart';
import 'package:moodiary/common/values/diary_domain.dart';
import 'package:moodiary/common/values/diary_type.dart';
import 'package:moodiary/components/base/image.dart';
import 'package:moodiary/components/base/text.dart';
import 'package:moodiary/components/diary_card/basic_card_logic.dart';
import 'package:moodiary/utils/file_util.dart';

class DemoUnifiedCard extends StatelessWidget with BasicCardLogic {
  const DemoUnifiedCard({super.key, required this.diary, this.onTap});

  final Diary diary;
  final VoidCallback? onTap;

  // 根据类型返回徽标
  Widget _buildDomainBadge(BuildContext context, DiaryDomain domain) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (domain) {
      case DiaryDomain.memoir:
        bgColor = context.theme.colorScheme.tertiaryContainer;
        textColor = context.theme.colorScheme.onTertiaryContainer;
        label = '回忆录';
        icon = FontAwesomeIcons.bookOpen;
        break;
      case DiaryDomain.note:
        bgColor = context.theme.colorScheme.secondaryContainer;
        textColor = context.theme.colorScheme.onSecondaryContainer;
        label = '随手记';
        icon = FontAwesomeIcons.penToSquare;
        break;
      case DiaryDomain.normal:
      default:
        bgColor = context.theme.colorScheme.primaryContainer;
        textColor = context.theme.colorScheme.onPrimaryContainer;
        label = '日记';
        icon = FontAwesomeIcons.book;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          FaIcon(icon, size: 10, color: textColor),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // 标签区
  Widget _buildTags(BuildContext context) {
    // 过滤掉与分类重复的标签
    final filteredTags = diary.tags.where((tag) => tag != '回忆录' && tag != '随手记' && tag != '日记').toList();
    if (filteredTags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: filteredTags.map((tag) {
          return Text(
            '#$tag',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          );
        }).toList(),
      ),
    );
  }

  // 图片区 (紧凑缩略图)
  Widget _buildImages(BuildContext context) {
    if (diary.imageName.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 8.0,
          children: List.generate(diary.imageName.length, (index) {
            return SizedBox(
              width: 80,
              height: 80,
              child: MoodiaryImage(
                imagePath: FileUtil.getRealPath('image', diary.imageName[index]),
                borderRadius: AppBorderRadius.smallBorderRadius,
                showBorder: true,
                size: 80,
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final domain = DiaryDomain.fromValue(diary.domain);

    return Card.filled(
      margin: EdgeInsets.zero,
      color: context.theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.mediumBorderRadius,
        side: BorderSide(
          color: context.theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: AppBorderRadius.mediumBorderRadius,
        onTap: onTap ?? () => toDiary(diary),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部：标题 
              if (diary.title.isNotEmpty) ...[
                Text(
                  diary.title.trim(),
                  style: context.textTheme.titleLarge?.copyWith(
                    color: context.theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              
              // 正文内容优先
              if (diary.contentText.isNotEmpty)
                Text(
                  diary.contentText.trim().removeLineBreaks(),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: context.theme.colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
              
              _buildImages(context),
              _buildTags(context),

              const SizedBox(height: 12),
              
              // 底部：具体时间、领域标签、情绪天气
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 具体时间，使用常规格式
                  Expanded(
                    child: Text(
                      DateFormat.yMMMMEEEEd().add_Hms().format(diary.time),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FaIcon(
                    DiaryType.fromValue(diary.type).icon,
                    size: 10,
                    color: context.theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  _buildDomainBadge(context, domain),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
