import 'package:moodiary/l10n/l10n.dart';
import 'package:get/get.dart';
import 'package:moodiary/common/models/isar/category.dart';
import 'package:moodiary/common/values/diary_domain.dart';
import 'package:moodiary/pages/home/diary/diary_logic.dart';
import 'package:moodiary/persistence/isar.dart';
import 'package:moodiary/utils/notice_util.dart';

import 'category_manager_state.dart';

class CategoryManagerLogic extends GetxController {
  final CategoryManagerState state = CategoryManagerState();

  DiaryLogic? get diaryLogic =>
      Bind.isRegistered<DiaryLogic>(tag: state.domain.logicTag)
      ? Bind.find<DiaryLogic>(tag: state.domain.logicTag)
      : null;

  void _resolveDomain() {
    final argument = Get.arguments;
    if (argument is DiaryDomain) {
      state.domain = argument;
    } else {
      state.domain = DiaryDomain.normal;
    }
  }

  @override
  void onReady() async {
    _resolveDomain();
    await getCategory();
    super.onReady();
  }

  Future<void> getCategory() async {
    state.isFetching.value = true;
    state.categoryList.value = await IsarUtil.getAllCategoryAsync(
      domain: state.domain,
    );
    state.isFetching.value = false;
  }

  Future<void> addCategory({required String text}) async {
    if (text.isNotEmpty) {
      if (await IsarUtil.insertACategory(
        Category()..categoryName = text,
        domain: state.domain,
      )) {
        await getCategory();
        await diaryLogic?.updateCategory();
      } else {
        await getCategory();
        await diaryLogic?.updateCategory();
        toast.info(message: Get.context!.l10n.categoryNameExist);
      }
    } else {
      toast.info(message: Get.context!.l10n.categoryNameCannotBeEmpty);
    }
  }

  Future<void> editCategory(String categoryId, {required String text}) async {
    if (text.isNotEmpty) {
      await IsarUtil.updateACategory(
        Category()
          ..id = categoryId
          ..domain = state.domain.value
          ..categoryName = text,
      );
      await getCategory();
      await diaryLogic?.updateCategory();
    } else {
      toast.info(message: Get.context!.l10n.categoryNameCannotBeEmpty);
    }
  }

  Future<void> deleteCategory(String id) async {
    if (await IsarUtil.deleteACategory(id)) {
      toast.success(message: Get.context!.l10n.categoryDeleteSuccess);
      await getCategory();
      await diaryLogic?.updateCategory();
    } else {
      toast.error(message: Get.context!.l10n.categoryDeleteFailNotEmpty);
    }
  }
}
