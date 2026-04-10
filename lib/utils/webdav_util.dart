import 'package:moodiary/l10n/l10n.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' as flutter;
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';
import 'package:moodiary/common/models/isar/category.dart';
import 'package:moodiary/common/models/isar/diary.dart';
import 'package:moodiary/common/values/webdav.dart';
import 'package:moodiary/persistence/isar.dart';
import 'package:moodiary/persistence/pref.dart';
import 'package:moodiary/persistence/secure_storage.dart';
import 'package:moodiary/utils/aes_util.dart';
import 'package:moodiary/utils/file_util.dart';
import 'package:moodiary/utils/diary_logic_util.dart';
import 'package:moodiary/utils/log_util.dart';
import 'package:moodiary/utils/notice_util.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:moodiary/common/values/pref_keys.dart';

class WebDavUtil {
  RxSet<String> syncingDiaries = <String>{}.obs;

  webdav.Client? _client;

  bool get hasOption => PrefUtil.getValue<bool>(PrefKeys.hasWebDavOption) ?? false;

  Future<List<String>> loadCredentials() async {
    final url = await SecureStorageUtil.getValue('webDavUrl') ?? '';
    final user = await SecureStorageUtil.getValue('webDavUser') ?? '';
    final password = await SecureStorageUtil.getValue('webDavPassword') ?? '';
    return [url, user, password];
  }

  // 通过 GetX 注入，WebDavUtil() 返回已注册的实例
  factory WebDavUtil() => Get.find<WebDavUtil>();
  WebDavUtil.create();

  Future<void> initWebDav() async {
    // 将旧版本 SharedPreferences 中的明文凭据自动迁移到 SecureStorage
    final oldOptions = PrefUtil.getValue<List<String>>(PrefKeys.webDavOption);
    if (oldOptions != null && oldOptions.isNotEmpty) {
      await SecureStorageUtil.setValue('webDavUrl', oldOptions[0]);
      await SecureStorageUtil.setValue('webDavUser', oldOptions[1]);
      await SecureStorageUtil.setValue('webDavPassword', oldOptions[2]);
      await PrefUtil.setValue<bool>(PrefKeys.hasWebDavOption, true);
      await PrefUtil.setValue<List<String>>(PrefKeys.webDavOption, []);
    }

    if (!hasOption) {
      _client = null;
      return;
    }
    final credentials = await loadCredentials();
    if (credentials[0].isEmpty) {
      _client = null;
      return;
    }
    if (_client != null) {
      _client = null;
    }
    // 尝试连接
    try {
      _client = webdav.newClient(
        credentials[0],
        user: credentials[1],
        password: credentials[2],
        debug: false,
      );
    } catch (e) {
      _client = null;
      return;
    }
    _client?.setHeaders({
      'accept-charset': 'utf-8',
      'Content-Type': 'application/json',
    });
  }

  Future<bool> checkConnectivity() async {
    if (_client == null) {
      return false;
    }
    try {
      // 设置超时时间为 5 秒
      await _client?.ping().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Ping operation timed out');
        },
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> initDir() async {
    await _client!.mkdirAll(WebDavOptions.imagePath);
    await _client!.mkdirAll(WebDavOptions.videoPath);
    await _client!.mkdirAll(WebDavOptions.audioPath);
    await _client!.mkdirAll(WebDavOptions.diaryPath);
    await _client!.mkdirAll(WebDavOptions.categoryPath);
    await checkSyncFlag();
  }

  Future<void> checkSyncFlag() async {
    try {
      await _client!.read(WebDavOptions.syncFlagPath);
    } catch (e) {
      await _client!.write(
        WebDavOptions.syncFlagPath,
        utf8.encode(jsonEncode({})),
      );
    }
  }

  Future<void> updateWebDav({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    await SecureStorageUtil.setValue('webDavUrl', baseUrl);
    await SecureStorageUtil.setValue('webDavUser', username);
    await SecureStorageUtil.setValue('webDavPassword', password);
    await PrefUtil.setValue<bool>(PrefKeys.hasWebDavOption, true);
    await initWebDav();
  }

  Future<void> removeWebDavOption() async {
    _client = null;
    await SecureStorageUtil.remove('webDavUrl');
    await SecureStorageUtil.remove('webDavUser');
    await SecureStorageUtil.remove('webDavPassword');
    await PrefUtil.setValue<bool>(PrefKeys.hasWebDavOption, false);
  }

  Future<Map<String, String>> fetchServerSyncData() async {
    if (_client != null) {
      final response = await _client!.read(WebDavOptions.syncFlagPath);
      if (response.isNotEmpty) {
        return Map<String, String>.from(jsonDecode(utf8.decode(response)));
      }
    }
    return {};
  }

  Future<void> updateServerSyncData(Map<String, String> syncData) async {
    if (_client != null) {
      await _client!.write(
        WebDavOptions.syncFlagPath,
        utf8.encode(jsonEncode(syncData)),
      );
    }
  }

  Future<Map<String, String>> fetchLocalSyncState() async {
    final file = File(FileUtil.getLocalSyncStateFilePath());
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        return Map<String, String>.from(jsonDecode(content));
      } catch (e) {
        return {};
      }
    }
    return {};
  }

  Future<void> updateLocalSyncState(Map<String, String> state) async {
    final file = File(FileUtil.getLocalSyncStateFilePath());
    await file.writeAsString(jsonEncode(state));
  }

  //删除某一篇日记，将webdav中sync.json的对应日记id的value设置为delete
  Future<void> deleteSingleDiary(Diary diary) async {
    final serverSyncData = await fetchServerSyncData();
    if (!serverSyncData.containsKey(diary.id)) {
      return;
    }
    serverSyncData[diary.id] = 'delete';
    await updateServerSyncData(serverSyncData);

    // 更新本地同步状态
    final localSyncData = await fetchLocalSyncState();
    localSyncData[diary.id] = 'delete';
    await updateLocalSyncState(localSyncData);
    // 删除日记json
    await _client!.remove('${WebDavOptions.diaryPath}/${diary.id}.json');
    await _client!.remove('${WebDavOptions.diaryPath}/${diary.id}.bin');
    // 遍历删除日记资源文件
    await _deleteFiles(
      diary.imageName,
      '${WebDavOptions.imagePath}/${diary.id}',
      'image',
    );
    await _deleteFiles(
      diary.audioName,
      '${WebDavOptions.audioPath}/${diary.id}',
      'audio',
    );
    await _deleteFiles(
      diary.videoName,
      '${WebDavOptions.videoPath}/${diary.id}',
      'video',
    );
    await _deleteFiles(
      diary.videoName
          .map(FileUtil.videoNameToThumbnailName)
          .toList(),
      '${WebDavOptions.videoPath}/${diary.id}',
      'thumbnail',
    );
    // 删除对应目录
    await _client!.remove('${WebDavOptions.imagePath}/${diary.id}');
    await _client!.remove('${WebDavOptions.audioPath}/${diary.id}');
    await _client!.remove('${WebDavOptions.videoPath}/${diary.id}');
  }

  Future<void> _deleteDiary(Diary diary) async {
    // 删除文件的通用方法
    Future<void> deleteFiles(List<String> names, String folder) async {
      final tasks = names
          .map(
            (name) => FileUtil.deleteFile(FileUtil.getRealPath(folder, name)),
          )
          .toList();
      await Future.wait(tasks);
    }

    // 删除日记和关联文件
    if (await IsarUtil.deleteADiary(diary.isarId)) {
      // 并行删除图片、音频、视频及其缩略图
      await Future.wait([
        deleteFiles(diary.imageName, 'image'),
        deleteFiles(diary.audioName, 'audio'),
        deleteFiles(diary.videoName, 'video'),
        deleteFiles(diary.videoName, 'thumbnail'), // 视频缩略图
      ]);
    }
  }

  Future<void> syncDiary(
    List<Diary> localDiaries, {
    flutter.VoidCallback? onUpload,
    flutter.VoidCallback? onDownload,
    flutter.VoidCallback? onComplete,
  }) async {
    final serverSyncData = await fetchServerSyncData();
    final Map<String, String> updatedServerSyncData = {...serverSyncData};
    
    final localSyncData = await fetchLocalSyncState();
    final Map<String, String> updatedLocalSyncData = {...localSyncData};
    final bool isFirstSync = localSyncData.isEmpty;

    // 本地日记的 ID -> Diary 映射
    final Map<String, Diary> localDiaryMap = {
      for (final diary in localDiaries) diary.id: diary,
    };
    
    // 取出所有涉及到的 ID 并集
    final Set<String> allIds = {}
      ..addAll(serverSyncData.keys)
      ..addAll(localDiaryMap.keys);

    for (final diaryId in allIds) {
      if (syncingDiaries.contains(diaryId)) continue;
      
      final serverTimestamp = serverSyncData[diaryId];
      final localDiary = localDiaryMap[diaryId];
      final localTimestamp = localDiary?.lastModified.toIso8601String();
      final lastSyncTimestamp = localSyncData[diaryId];

      syncingDiaries.add(diaryId);

      // 情境 A：只有云端存在这个 ID，且状态是 delete
      if (serverTimestamp == 'delete') {
        if (localDiary != null) {
          // 本地存在，说明云端删除了，本地也应删除
          await _deleteDiary(localDiary);
          await DiaryLogicUtil.refreshAllDomains();
        }
        updatedLocalSyncData[diaryId] = 'delete';
        syncingDiaries.remove(diaryId);
        continue;
      }
      
      // 没有任何修改的情况（都和上一次同步一样）
      if (!isFirstSync && serverTimestamp == lastSyncTimestamp && localTimestamp == lastSyncTimestamp) {
        syncingDiaries.remove(diaryId);
        continue;
      }

      // 情境 B：本地不存在（被删或尚未下载），但服务器存在且已被他人修改或新增
      if (localTimestamp == null && serverTimestamp != null) {
        // 如果服务器有这篇新日记，下载它
        try {
          final updatedDiary = await _downloadDiary(diaryId);
          await IsarUtil.insertADiary(updatedDiary);
          updatedLocalSyncData[diaryId] = serverTimestamp;
        } catch (e) {
          updatedServerSyncData.remove(diaryId);
        }
        onDownload?.call();
        syncingDiaries.remove(diaryId);
        continue;
      }

      // 兼容老版本的首次比对：如果没有 local_sync_state，回退到普通时间戳比较
      if (isFirstSync) {
        if (serverTimestamp != null && localTimestamp != null && serverTimestamp.compareTo(localTimestamp) > 0) {
          // 服务器较新，更新本地
          try {
            final newDiary = await _downloadDiary(diaryId);
            await IsarUtil.updateADiary(oldDiary: localDiary, newDiary: newDiary);
            updatedLocalSyncData[diaryId] = serverTimestamp;
          } catch (e) {
            updatedServerSyncData.remove(diaryId);
          }
          onDownload?.call();
        } else if (serverTimestamp == null || (localTimestamp != null && serverTimestamp.compareTo(localTimestamp) < 0)) {
          // 本地较新，更新服务器
          await _uploadDiary(localDiary!);
          updatedServerSyncData[diaryId] = localTimestamp!;
          updatedLocalSyncData[diaryId] = localTimestamp!;
          onUpload?.call();
        } else {
          // 完全一致
          updatedLocalSyncData[diaryId] = localTimestamp!;
        }
        syncingDiaries.remove(diaryId);
        continue;
      }

      // 增量防冲突检测：
      // 情境 1：仅服务器更新
      if (serverTimestamp != null && serverTimestamp != lastSyncTimestamp && localTimestamp == lastSyncTimestamp) {
        try {
          final newDiary = await _downloadDiary(diaryId);
          await IsarUtil.updateADiary(oldDiary: localDiary, newDiary: newDiary);
          updatedLocalSyncData[diaryId] = serverTimestamp;
        } catch (e) {
          updatedServerSyncData.remove(diaryId);
        }
        onDownload?.call();
      }
      // 情境 2：仅本地更新 (或服务器被意外清除)
      else if (localTimestamp != null && localTimestamp != lastSyncTimestamp && (serverTimestamp == lastSyncTimestamp || serverTimestamp == null)) {
        await _uploadDiary(localDiary!);
        updatedServerSyncData[diaryId] = localTimestamp;
        updatedLocalSyncData[diaryId] = localTimestamp;
        onUpload?.call();
      }
      // 情境 3：冲突发生！(本地更新了，服务器也独立更新了)
      else if (serverTimestamp != null && localTimestamp != null && serverTimestamp != lastSyncTimestamp && localTimestamp != lastSyncTimestamp) {
        // ---- 发生冲突，执行分叉 Fork ----
        // 1. 本地记录作为副本处理
        final clonedDiary = localDiary!.clone();
        final newId = const Uuid().v7();
        clonedDiary.id = newId;
        // 注意：因为 Isar 默认根据 id 去重和关联，如果不修改本地存储名称可能存在文件共用问题，
        // 由于克隆方法暂时共享附件名称，我们重点在标题增加提示：
        clonedDiary.title = '${clonedDiary.title} (冲突副本-${localDiary.id.substring(0, 4)})';
        await IsarUtil.insertADiary(clonedDiary);
        
        // 分叉出来的副本立刻上传
        await _uploadDiary(clonedDiary);
        updatedServerSyncData[newId] = clonedDiary.lastModified.toIso8601String();
        updatedLocalSyncData[newId] = clonedDiary.lastModified.toIso8601String();
        onUpload?.call();
        
        // 2. 原始 ID 日记从云端安全下载
        try {
          final newDiary = await _downloadDiary(diaryId);
          await IsarUtil.updateADiary(oldDiary: localDiary, newDiary: newDiary);
          updatedLocalSyncData[diaryId] = serverTimestamp;
        } catch (e) {
          updatedServerSyncData.remove(diaryId);
        }
        onDownload?.call();
      }

      syncingDiaries.remove(diaryId);
    }

    // 更新双端同步文件
    await updateServerSyncData(updatedServerSyncData);
    await updateLocalSyncState(updatedLocalSyncData);
    
    // 刷新界面
    await DiaryLogicUtil.refreshAllDomains();
    onComplete?.call();
  }

  Future<void> uploadSingleDiary(
    Diary diary, {
    flutter.VoidCallback? onUpload,
    flutter.VoidCallback? onComplete,
  }) async {
    if (syncingDiaries.contains(diary.id)) {
      return; // 避免重复上传
    }

    syncingDiaries.add(diary.id);
    try {
      // 上传日记到服务器
      await _uploadDiary(diary); // 上传日记的实现

      // 更新服务器同步数据
      final serverSyncData = await fetchServerSyncData();
      final lastModifiedStr = diary.lastModified.toIso8601String();
      serverSyncData[diary.id] = lastModifiedStr;
      await updateServerSyncData(serverSyncData);

      // 更新本地同步状态
      final localSyncData = await fetchLocalSyncState();
      localSyncData[diary.id] = lastModifiedStr;
      await updateLocalSyncState(localSyncData);

      onUpload?.call();
    } catch (e) {
      logger.d('Failed to upload diary: $e');
      toast.error(message: Get.context!.l10n.webdavUploadFail);
    } finally {
      syncingDiaries.remove(diary.id);
      onComplete?.call(); // 调用完成回调
    }
  }

  Future<void> updateSingleDiary({
    required Diary oldDiary,
    required Diary newDiary,
    flutter.VoidCallback? onUpload,
    flutter.VoidCallback? onComplete,
  }) async {
    if (syncingDiaries.contains(newDiary.id)) {
      return; // 避免重复上传
    }
    syncingDiaries.add(newDiary.id);
    try {
      // 遍历删除日记资源文件
      final needToDeleteImage = oldDiary.imageName
          .where((element) => !newDiary.imageName.contains(element))
          .toList();
      final needToDeleteAudio = oldDiary.audioName
          .where((element) => !newDiary.audioName.contains(element))
          .toList();
      final needToDeleteVideo = oldDiary.videoName
          .where((element) => !newDiary.videoName.contains(element))
          .toList();
      final needToDeleteThumbnail = needToDeleteVideo
          .map(FileUtil.videoNameToThumbnailName)
          .toList();
      await _deleteFiles(
        needToDeleteImage,
        '${WebDavOptions.imagePath}/${newDiary.id}',
        'image',
      );
      await _deleteFiles(
        needToDeleteAudio,
        '${WebDavOptions.audioPath}/${newDiary.id}',
        'audio',
      );
      await _deleteFiles(
        needToDeleteVideo,
        '${WebDavOptions.videoPath}/${newDiary.id}',
        'video',
      );
      await _deleteFiles(
        needToDeleteThumbnail,
        '${WebDavOptions.videoPath}/${newDiary.id}',
        'thumbnail',
      );
      // 上传日记到服务器
      await _uploadDiary(newDiary); // 上传日记的实现
      // 更新服务器同步数据
      final serverSyncData = await fetchServerSyncData();
      serverSyncData[newDiary.id] = newDiary.lastModified.toIso8601String();
      await updateServerSyncData(serverSyncData);
      onUpload?.call();
    } catch (e) {
      logger.d('Failed to upload diary: $e');
      toast.error(message: Get.context!.l10n.webdavUpdateFail);
    } finally {
      syncingDiaries.remove(newDiary.id);
      onComplete?.call(); // 调用完成回调
    }
  }

  Future<bool> _checkShouldEncrypt() async {
    return PrefUtil.getValue<bool>(PrefKeys.syncEncryption) == true &&
        (await SecureStorageUtil.getValue('userKey')) != null;
  }

  Future<void> _uploadDiary(Diary diary) async {
    Uint8List diaryData;
    String diaryPath;
    // 检查有没有开启加密
    final shouldEncrypt = await _checkShouldEncrypt();
    if (shouldEncrypt) {
      // 尝试获取用户密钥
      final userKey = await SecureStorageUtil.getValue('userKey');
      // 生成加密密钥, 用日记 ID 和用户密钥生成
      final key = await AesUtil.deriveKey(salt: diary.id, userKey: userKey!);
      // 加密日记内容
      diaryPath = '${WebDavOptions.diaryPath}/${diary.id}.bin';
      diaryData = await AesUtil.encrypt(
        key: key,
        data: jsonEncode(diary.toJson()),
      );
    } else {
      diaryPath = '${WebDavOptions.diaryPath}/${diary.id}.json';
      diaryData = utf8.encode(jsonEncode(diary.toJson()));
    }

    // 检查并上传分类
    if (diary.categoryId != null) {
      final categoryName = IsarUtil.getCategoryName(
        diary.categoryId!,
      )?.categoryName;
      if (categoryName != null) {
        await _uploadCategory(diary.categoryId!, categoryName);
      }
    }
    try {
      _client!.setHeaders({
        'accept-charset': 'utf-8',
        'Content-Type': shouldEncrypt
            ? 'application/octet-stream'
            : 'application/json',
      });
      await _client!.write(diaryPath, diaryData);
      logger.d('Diary  uploaded: $diaryPath');
    } catch (e) {
      logger.d('Failed to upload diary : $e');
      rethrow;
    }

    // 上传资源文件，目标路径是资源文件夹下的日记id
    await _uploadFiles(
      diary.imageName,
      '${WebDavOptions.imagePath}/${diary.id}',
      'image',
    );
    await _uploadFiles(
      diary.audioName,
      '${WebDavOptions.audioPath}/${diary.id}',
      'audio',
    );
    await _uploadFiles(
      diary.videoName,
      '${WebDavOptions.videoPath}/${diary.id}',
      'video',
    );
    await _uploadFiles(
      diary.videoName,
      '${WebDavOptions.videoPath}/${diary.id}',
      'thumbnail',
    );
  }

  Future<void> _uploadFiles(
    List<String> fileNames,
    String resourcePath,
    String type,
  ) async {
    await _client!.mkdirAll(resourcePath);
    final existingFiles = await _client!.readDir(resourcePath);

    for (var fileName in fileNames) {
      final filePath = FileUtil.getRealPath(type, fileName);
      fileName = type == 'thumbnail'
          ? FileUtil.videoNameToThumbnailName(fileName)
          : fileName;
      if (existingFiles.any((file) => file.name == fileName)) {
        logger.d('$type file already exists: $fileName');
        continue;
      }
      try {
        final fileBytes = await File(filePath).readAsBytes();
        _client!.setHeaders({
          'accept-charset': 'utf-8',
          'Content-Type': 'application/octet-stream',
        });
        await _client!.write('$resourcePath/$fileName', fileBytes);
        logger.d('$type file uploaded: $fileName');
      } catch (e) {
        logger.d('Failed to upload $type file: $fileName, Error: $e');
        rethrow;
      }
    }
  }

  Future<void> _deleteFiles(
    List<String> fileNames,
    String resourcePath,
    String type,
  ) async {
    for (final fileName in fileNames) {
      try {
        await _client!.remove('$resourcePath/$fileName');
        logger.d('$type file deleted: $fileName');
      } catch (e) {
        logger.d('Failed to delete $type file: $fileName, Error: $e');
        rethrow;
      }
    }
  }

  Future<Diary> _downloadDiary(String diaryId) async {
    // 下载日记 JSON 数据
    final normalDiaryPath = '${WebDavOptions.diaryPath}/$diaryId.json';
    final encryptedDiaryPath = '${WebDavOptions.diaryPath}/$diaryId.bin';
    late Diary diary;
    try {
      // 先尝试普通 JSON 格式
      try {
        final diaryData = await _client!.read(normalDiaryPath);
        diary = await flutter.compute(
          Diary.fromJson,
          jsonDecode(utf8.decode(diaryData)) as Map<String, dynamic>,
        );
        logger.d('Diary JSON downloaded: $normalDiaryPath');
      } catch (e) {
        logger.d('Failed to download normal JSON: $e');
        // 再尝试二进制格式
        try {
          final encryptedDiaryData = await _client!.read(encryptedDiaryPath);
          // 解密日记内容
          final userKey = await SecureStorageUtil.getValue('userKey');
          final shouldEncrypt = await _checkShouldEncrypt();
          if (!shouldEncrypt) {
            throw Exception('User key not found or encryption not enabled');
          }
          final key = await AesUtil.deriveKey(salt: diaryId, userKey: userKey!);
          final decryptedData = await AesUtil.decrypt(
            key: key,
            encryptedData: Uint8List.fromList(encryptedDiaryData),
          );
          diary = await flutter.compute(
            Diary.fromJson,
            jsonDecode(decryptedData) as Map<String, dynamic>,
          );
          logger.d('Diary binary downloaded: $encryptedDiaryPath');
        } catch (e) {
          logger.d('Failed to download binary diary: $e');
          // 两种方式都失败，抛出最终异常
          rethrow;
        }
      }
    } catch (e) {
      throw Exception('Failed to download diary: $e');
    }

    // 同步分类
    if (diary.categoryId != null) {
      try {
        final category = await _downloadCategory(diary.categoryId!);
        await IsarUtil.updateACategory(
          Category()
            ..id = category['id']!
            ..domain = diary.domain
            ..categoryName = category['name']!,
        );
      } catch (e) {
        logger.d('Failed to sync category for diary: $diaryId, Error: $e');
      }
    }

    // 下载资源文件
    diary.imageName = await _downloadFiles(
      diary.imageName,
      '${WebDavOptions.imagePath}/$diaryId',
      'image',
    );
    diary.audioName = await _downloadFiles(
      diary.audioName,
      '${WebDavOptions.audioPath}/$diaryId',
      'audio',
    );
    diary.videoName = await _downloadFiles(
      diary.videoName,
      '${WebDavOptions.videoPath}/$diaryId',
      'video',
    );
    // 下载视频缩略图
    await _downloadFiles(
      diary.videoName,
      '${WebDavOptions.videoPath}/$diaryId',
      'thumbnail',
    );
    return diary;
  }

  Future<List<String>> _downloadFiles(
    List<String> fileNames,
    String resourcePath,
    String type,
  ) async {
    final localFileNames = <String>[];

    for (final fileName in fileNames) {
      final serverFilePath = type == 'thumbnail'
          ? '$resourcePath/${FileUtil.videoNameToThumbnailName(fileName)}'
          : '$resourcePath/$fileName';
      final localFilePath = FileUtil.getRealPath(type, fileName);

      try {
        final fileBytes = await _client!.read(serverFilePath);
        final file = File(localFilePath);
        await file.writeAsBytes(fileBytes);
        localFileNames.add(fileName);
        logger.d('$type file downloaded: $fileName');
      } catch (e) {
        logger.d('Failed to download $type file: $fileName, Error: $e');
      }
    }

    return localFileNames;
  }

  Future<void> _uploadCategory(String categoryId, String categoryName) async {
    final categoryPath = '${WebDavOptions.categoryPath}/$categoryId.json';
    final categoryData = jsonEncode({'id': categoryId, 'name': categoryName});

    try {
      _client!.setHeaders({
        'accept-charset': 'utf-8',
        'Content-Type': 'application/json',
      });
      await _client!.write(categoryPath, utf8.encode(categoryData));
      logger.d('Category uploaded: $categoryPath');
    } catch (e) {
      logger.d('Failed to upload category: $e');
      rethrow;
    }
  }

  Future<Map<String, String>> _downloadCategory(String categoryId) async {
    final categoryPath = '${WebDavOptions.categoryPath}/$categoryId.json';

    try {
      final categoryData = await _client!.read(categoryPath);
      final categoryMap =
          jsonDecode(utf8.decode(categoryData)) as Map<String, dynamic>;
      final categoryName = categoryMap['name'] as String;
      logger.d('Category downloaded: $categoryPath');
      return {'id': categoryId, 'name': categoryName};
    } catch (e) {
      logger.d('Failed to download category: $e');
      throw Exception('Category not found: $categoryId');
    }
  }
}
