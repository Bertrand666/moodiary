import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moodiary/common/models/isar/category.dart';
import 'package:moodiary/common/values/diary_domain.dart';
import 'package:moodiary/pages/edit/edit_logic.dart';
import 'package:moodiary/pages/home/diary/diary_logic.dart';
import 'package:moodiary/persistence/isar.dart';
import 'package:moodiary/utils/notice_util.dart';

import 'category_add_state.dart';

class CategoryAddLogic extends GetxController {
  final CategoryAddState state = CategoryAddState();
  late final EditLogic editLogic = Bind.find<EditLogic>();
  late final DiaryDomain domain = DiaryDomain.fromValue(
    editLogic.state.currentDiary.domain,
  );

  @override
  void onReady() {
    getCategory();
    super.onReady();
  }

  void getCategory() {
    state.categoryList.value = IsarUtil.getAllCategory(domain: domain);
  }

  Future<void> addCategory({required String text}) async {
    if (text.isNotEmpty) {
      final res = await IsarUtil.insertACategory(
        Category()..categoryName = text,
        domain: domain,
      );
      if (res == false) {
        toast.info(message: '已经存在同名分类，已自动重命名');
      }
      getCategory();
      if (Bind.isRegistered<DiaryLogic>(tag: domain.logicTag)) {
        await Bind.find<DiaryLogic>(tag: domain.logicTag).updateCategory();
      }
    }
  }

  void selectCategory(int index, BuildContext context) {
    Navigator.pop(context);
    editLogic.selectCategory(state.categoryList.value[index].id);
    editLogic.update(['CategoryName']);
  }

  void cancelCategory(BuildContext context) {
    Navigator.pop(context);
    editLogic.selectCategory(null);
    editLogic.update(['CategoryName']);
  }
}
