import 'package:get/get.dart';
import 'package:moodiary/common/models/isar/diary.dart';
import 'package:moodiary/common/values/diary_domain.dart';

class DiaryTabViewState {
  late DiaryDomain domain;

  RxList<Diary> diaryList = <Diary>[].obs;

  RxBool isFetching = true.obs;

  //首次加载的个数
  int initLen = 30;

  //分页的个数
  int pageLen = 20;
  late String? tagName;

  DiaryTabViewState();
}
