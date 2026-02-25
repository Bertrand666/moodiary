import 'package:get/get.dart';
import 'package:moodiary/common/models/isar/category.dart';
import 'package:moodiary/common/values/diary_domain.dart';

class CategoryManagerState {
  DiaryDomain domain = DiaryDomain.normal;

  late RxList<Category> categoryList = <Category>[].obs;

  RxBool isFetching = true.obs;

  CategoryManagerState();
}
