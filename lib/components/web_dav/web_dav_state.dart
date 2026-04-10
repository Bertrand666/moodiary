import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moodiary/common/values/webdav.dart';
import 'package:moodiary/persistence/pref.dart';
import 'package:moodiary/utils/webdav_util.dart';
import 'package:moodiary/common/values/pref_keys.dart';

class WebDavState {
  final formKey = GlobalKey<FormState>();

  RxBool hasOption = WebDavUtil().hasOption.obs;

  Rx<WebDavConnectivityStatus> connectivityStatus =
      WebDavConnectivityStatus.connecting.obs;

  RxBool autoSync = PrefUtil.getValue<bool>(PrefKeys.autoSync)!.obs;

  RxBool autoSyncAfterChange =
      PrefUtil.getValue<bool>(PrefKeys.autoSyncAfterChange)!.obs;

  RxBool syncEncryption = PrefUtil.getValue<bool>(PrefKeys.syncEncryption)!.obs;
  RxBool hasUserKey = false.obs;

  WebDavState();
}
