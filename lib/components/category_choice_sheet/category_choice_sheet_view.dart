import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moodiary/common/values/diary_domain.dart';
import 'package:moodiary/components/base/loading.dart';
import 'package:moodiary/l10n/l10n.dart';

import 'category_choice_sheet_logic.dart';
import 'category_choice_sheet_state.dart';

class CategoryChoiceSheetComponent extends StatelessWidget {
  final DiaryDomain domain;

  const CategoryChoiceSheetComponent({super.key, required this.domain});

  @override
  Widget build(BuildContext context) {
    final logicTag = 'category_choice_${domain.value}';
    final CategoryChoiceSheetLogic logic = Get.put(
      CategoryChoiceSheetLogic(domain: domain),
      tag: logicTag,
    );
    final CategoryChoiceSheetState state = Bind.find<CategoryChoiceSheetLogic>(
      tag: logicTag,
    ).state;

    return GetBuilder<CategoryChoiceSheetLogic>(
      tag: logicTag,
      assignId: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Obx(() {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: !state.isFetching.value
                    ? Wrap(
                        spacing: 4.0,
                        runSpacing: 4.0,
                        alignment: WrapAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.l10n.categoryAllCategory,
                                style: context.textTheme.titleMedium,
                              ),
                              Text(
                                state.categoryList.length.toString(),
                                style: context.textTheme.titleMedium,
                              ),
                            ],
                          ),
                          ActionChip(
                            label: Text(context.l10n.categoryAll),
                            onPressed: () {
                              logic.selectCategory(categoryId: null);
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                            backgroundColor:
                                context.theme.colorScheme.tertiaryContainer,
                          ),
                          ...List.generate(state.categoryList.value.length, (
                            index,
                          ) {
                            return ActionChip(
                              label: Text(
                                state.categoryList.value[index].categoryName,
                              ),
                              onPressed: () {
                                logic.selectCategory(
                                  categoryId:
                                      state.categoryList.value[index].id,
                                );
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.zero,
                              backgroundColor:
                                  context.theme.colorScheme.secondaryContainer,
                            );
                          }),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                logic.toCategoryManage(context);
                              },
                              child: Text(
                                context.l10n.settingFunctionCategoryManage,
                              ),
                            ),
                          ),
                        ],
                      )
                    : const MoodiaryLoading(),
              );
            }),
          ),
        );
      },
    );
  }
}
