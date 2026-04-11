import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:moodiary/common/values/diary_domain.dart';
import 'package:moodiary/common/values/border.dart';
import 'package:moodiary/components/search_card/search_card_view.dart';
import 'package:moodiary/l10n/l10n.dart';

import 'search_sheet_logic.dart';

class SearchSheetComponent extends StatelessWidget {
  final DiaryDomain domain;

  const SearchSheetComponent({super.key, required this.domain});

  @override
  Widget build(BuildContext context) {
    final logicTag = 'search_sheet_${domain.value}';
    final logic = Get.put(SearchSheetLogic(domain: domain), tag: logicTag);
    final state = Bind.find<SearchSheetLogic>(tag: logicTag).state;

    return GetBuilder<SearchSheetLogic>(
      tag: logicTag,
      assignId: true,
      builder: (_) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                maxLines: 1,
                controller: logic.textEditingController,
                focusNode: logic.focusNode,
                decoration: InputDecoration(
                  fillColor: context.theme.colorScheme.secondaryContainer,
                  border: const UnderlineInputBorder(
                    borderRadius: AppBorderRadius.smallBorderRadius,
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  labelText: context.l10n.diarySearch,
                  suffixIcon: IconButton(
                    onPressed: () async {
                      await logic.doSearch();
                    },
                    icon: const Icon(Icons.search),
                  ),
                ),
              ),
            ),

            Obx(() {
              Widget child;
              if (state.isSearching.value && state.searchList.isEmpty) {
                child = const Center(
                  key: ValueKey('loading'),
                  child: CircularProgressIndicator(),
                );
              } else if (state.searchList.isEmpty) {
                child = Center(
                  key: const ValueKey('empty'),
                  child: FaIcon(
                    FontAwesomeIcons.boxOpen,
                    color: context.theme.colorScheme.onSurface,
                    size: 56,
                  ),
                );
              } else {
                child = Stack(
                  children: [
                    Positioned.fill(
                      child: ListView.separated(
                        itemCount: state.searchList.length,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        itemBuilder: (context, index) {
                          return SearchCardComponent(
                            diary: state.searchList[index],
                            queryList: state.queryList,
                          );
                        },
                        separatorBuilder: (_, _) => const Gap(8.0),
                      ),
                    ),
                    if (state.isSearching.value && state.searchList.isNotEmpty)
                      Positioned.fill(
                        child: Container(
                          color: context.theme.colorScheme.surfaceContainer
                              .withValues(alpha: 0.8),
                          child: const Center(
                            key: ValueKey('loading2'),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                  ],
                );
              }

              return Expanded(
                child: AnimatedSwitcher(
                  duration: Durations.short3,
                  child: child,
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Obx(() {
                return Text(
                  context.l10n.diarySearchResult(state.totalCount.value),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
