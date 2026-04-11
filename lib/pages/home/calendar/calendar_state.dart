import 'package:get/get.dart';
import 'package:moodiary/common/models/isar/diary.dart';
import 'package:moodiary/common/values/diary_domain.dart';

class CalendarState {
  late Rx<DateTime> currentMonth = DateTime.now().obs;

  //当前月份的日记
  late RxList<Diary> currentMonthDiaryList = <Diary>[].obs;

  late RxBool isFetching = true.obs;

  /// 当前筛选的 domain，null 表示全部
  Rx<DiaryDomain?> domainFilter = Rx<DiaryDomain?>(null);

  /// 筛选后的列表
  List<Diary> get filteredList {
    final filter = domainFilter.value;
    if (filter == null) return currentMonthDiaryList;
    return currentMonthDiaryList
        .where((d) => d.domain == filter.value)
        .toList();
  }

  late RxBool isControllerScrolling = false.obs;

  double velocityThreshold = 800;

  bool isUp = false;

  CalendarState();
}
