import 'package:get/get.dart';
import 'package:moodiary/persistence/pref.dart';
import 'package:moodiary/common/values/pref_keys.dart';

class LockState {
  late RxString password;

  late RxString realPassword;

  //锁定类型，是立即锁定导致，还是启动锁定导致
  late String? lockType;

  bool get supportBiometrics =>
      PrefUtil.getValue<bool>(PrefKeys.supportBiometrics) ?? false;

  RxBool isCheck = false.obs;

  LockState() {
    password = ''.obs;
    realPassword = ''.obs;
    lockType = Get.arguments;

    ///Initialize variables
  }
}
