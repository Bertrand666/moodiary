import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:latlong2/latlong.dart';
import 'package:moodiary/common/models/isar/category.dart';
import 'package:moodiary/common/models/isar/diary.dart';
import 'package:moodiary/common/models/isar/font.dart';
import 'package:moodiary/common/models/isar/sync_record.dart';
import 'package:moodiary/common/models/map.dart';
import 'package:moodiary/common/values/diary_domain.dart';
import 'package:moodiary/common/values/diary_template.dart';
import 'package:moodiary/common/values/diary_type.dart';
import 'package:moodiary/components/base/text.dart';
import 'package:moodiary/components/quill_embed/audio_embed.dart';
import 'package:moodiary/components/quill_embed/image_embed.dart';
import 'package:moodiary/components/quill_embed/video_embed.dart';
import 'package:moodiary/persistence/pref.dart';
import 'package:moodiary/src/rust/api/jieba.dart';
import 'package:moodiary/utils/file_util.dart';
import 'package:moodiary/utils/webdav_util.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:moodiary/common/values/pref_keys.dart';

class IsarUtil {
  late final Isar _isar;

  static final _schemas = [DiarySchema, CategorySchema, FontSchema];

  // ---- 门面 ----
  static IsarUtil get _i => Get.find<IsarUtil>();

  Future<void> initIsar() async {
    _isar = await Isar.openAsync(
      schemas: _schemas,
      directory: FileUtil.getRealPath('database', ''),
    );
  }

  // ---- 静态门面方法（保持向后兼容） ----
  static Future<void> dataMigration(String path) => _i._dataMigration(path);
  static Future<void> clearIsar() => _i._clearIsar();
  static Map<String, dynamic> getSize() => _i._getSize();
  static Future<void> exportIsar(String dir, String path, String fileName) =>
      _i._exportIsar(dir, path, fileName);
  static Future<void> insertADiary(Diary diary) => _i._insertADiary(diary);
  static Future<List<Diary>> getDiaryByMonth(int year, int month) =>
      _i._getDiaryByMonth(year, month);
  static Future<Diary?> getDiaryByID(int isarId) => _i._getDiaryByID(isarId);
  static Future<List<Diary>> getDiariesByDateRange(DateTime start, DateTime end, {bool all = true}) =>
      _i._getDiariesByDateRange(start, end, all: all);
  static Future<List<Diary>> getAllDiaries({DiaryDomain? domain}) => _i._getAllDiaries(domain: domain);
  static List<Diary> getAllDiariesSync({DiaryDomain? domain}) => _i._getAllDiariesSync(domain: domain);
  static Future<List<Diary>> getAllDiariesSorted() => _i._getAllDiariesSorted();
  static Future<List<List<String>>> getWeatherByDateRange(DateTime start, DateTime end, {DiaryDomain? domain}) =>
      _i._getWeatherByDateRange(start, end, domain: domain);
  static Future<List<double>> getMoodByDateRange(DateTime start, DateTime end, {DiaryDomain? domain}) =>
      _i._getMoodByDateRange(start, end, domain: domain);
  static Future<bool> deleteADiary(int isarId) => _i._deleteADiary(isarId);
  static Future<List<Diary>> getRecycleBinDiaries() => _i._getRecycleBinDiaries();
  static Future<void> updateADiary({Diary? oldDiary, required Diary newDiary}) =>
      _i._updateADiary(oldDiary: oldDiary, newDiary: newDiary);
  static Future<List<Diary>> searchDiaries({required List<String> queryList, DiaryDomain? domain}) =>
      _i._searchDiaries(queryList: queryList, domain: domain);
  static Future<List<Diary>> searchDiariesByTag(String value, {DiaryDomain? domain}) =>
      _i._searchDiariesByTag(value, domain: domain);
  static Future<int> countShowDiary() => _i._countShowDiary();
  static int countAllDiary() => _i._countAllDiary();
  static int countCategories({DiaryDomain? domain}) => _i._countCategories(domain: domain);
  static Category? getCategoryName(String id) => _i._getCategoryName(id);
  static Future<bool> insertACategory(Category category, {DiaryDomain domain = DiaryDomain.normal}) =>
      _i._insertACategory(category, domain: domain);
  static Future<bool> updateACategory(Category category) => _i._updateACategory(category);
  static Future<bool> deleteACategory(String id) => _i._deleteACategory(id);
  static Future<List<String>> getContentList({DiaryDomain? domain}) =>
      _i._getContentList(domain: domain);
  static List<Category> getAllCategory({DiaryDomain domain = DiaryDomain.normal}) =>
      _i._getAllCategory(domain: domain);
  static Future<List<Category>> getAllCategoryAsync({DiaryDomain domain = DiaryDomain.normal}) =>
      _i._getAllCategoryAsync(domain: domain);
  static Future<List<Diary>> getDiaryByTag(String? tagName, int offset, int limit, {DiaryDomain domain = DiaryDomain.normal}) =>
      _i._getDiaryByTag(tagName, offset, limit, domain: domain);
  static Future<List<Diary>> getDiaryByDay(DateTime time) => _i._getDiaryByDay(time);
  static Future<List<Diary>> getDiary(int offset, int limit) => _i._getDiary(offset, limit);
  static Future<void> migrateDomainField() => _i._migrateDomainField();
  static Future<List<DiaryMapItem>> getAllMapItem() => _i._getAllMapItem();
  static Future<void> addSyncRecord(SyncRecord record) => _i._addSyncRecord(record);
  static Future<List<SyncRecord>> getSyncRecords() => _i._getSyncRecords();
  static Future<void> deleteSyncRecord(int id) => _i._deleteSyncRecord(id);
  static Future<List<Font>> getAllFonts() => _i._getAllFonts();
  static Future<void> insertAFont(Font font) => _i._insertAFont(font);
  static Future<Font?> getFontByFontFamily(String fontFamily) => _i._getFontByFontFamily(fontFamily);
  static Future<bool> deleteFont(int id) => _i._deleteFont(id);

  // ---- 传入 compute() 的方法必须保持 static ----
  static void mergeToV2_4_8(String dir) {
    final isar = Isar.open(schemas: _schemas, directory: dir);
    final countDiary = isar.diarys.where().count();
    for (var i = 0; i < countDiary; i += 50) {
      final diaries = isar.diarys.where().findAll(offset: i, limit: 50);
      isar.write((isar) {
        isar.diarys.putAll(diaries);
      });
    }
    isar.close();
  }

  static void mergeToV2_6_0(String dir) {
    final isar = Isar.open(schemas: _schemas, directory: dir);
    final countDiary = isar.diarys.where().count();

    for (var i = 0; i < countDiary; i += 50) {
      final diaries = isar.diarys.where().findAll(offset: i, limit: 50);

      isar.write((isar) {
        // 公共quillController
        final quillController = QuillController.basic();

        for (final diary in diaries) {
          // 更新字段类型和修改时间
          diary.type = DiaryType.richText.value;
          diary.lastModified = diary.time; // 设置最后修改时间
          // 遍历资源文件，将资源文件插入到富文本中
          quillController.document = Document.fromJson(
            jsonDecode(diary.content),
          );

          for (final image in diary.imageName) {
            insertNewImage(imageName: image, quillController: quillController);
          }
          for (final video in diary.videoName) {
            insertNewVideo(videoName: video, quillController: quillController);
          }
          for (final audio in diary.audioName) {
            insertAudio(audioName: audio, quillController: quillController);
          }

          // 更新富文本内容
          diary.content = jsonEncode(
            quillController.document.toDelta().toJson(),
          );

          // 保存更新后的日记
          isar.diarys.put(diary);

          // 清理quillController
          quillController.clear();
        }
      });
    }

    isar.close();
  }

  static void fixV2_6_3(String dir) {
    final isar = Isar.open(schemas: _schemas, directory: dir);
    final countDiary = isar.diarys.where().count();
    for (var i = 0; i < countDiary; i += 50) {
      final diaries = isar.diarys.where().findAll(offset: i, limit: 50);
      isar.write((isar) {
        for (final diary in diaries) {
          final id = diary.categoryId;
          if (id != null && isar.categorys.where().idEqualTo(id).isEmpty()) {
            isar.categorys.put(
              Category()
                ..id = id
                ..categoryName = '已修复${const Uuid().v4().substring(0, 4)}',
            );
          }
        }
      });
    }
    isar.close();
  }

  static Future<void> mergeToV2_7_3(Map<String, dynamic> parma) async {
    final isar = Isar.open(schemas: _schemas, directory: parma['database']!);

    await isar.writeAsync((isar) {
      isar.fonts.clear();
      isar.fonts.putAll(parma['fonts']);
    });
  }

  // ---- 静态辅助方法（不依赖实例状态） ----
  static void insertNewImage({
    required String imageName,
    required QuillController quillController,
  }) {
    final imageBlock = ImageBlockEmbed.fromName(imageName);
    final index = quillController.selection.baseOffset;
    final length = quillController.selection.extentOffset - index;
    quillController.replaceText(
      index,
      length,
      imageBlock,
      TextSelection.collapsed(offset: index + 1),
    );
  }

  static void insertNewVideo({
    required String videoName,
    required QuillController quillController,
  }) {
    final videoBlock = VideoBlockEmbed.fromName(videoName);
    final index = quillController.selection.baseOffset;
    final length = quillController.selection.extentOffset - index;
    quillController.replaceText(
      index,
      length,
      videoBlock,
      TextSelection.collapsed(offset: index + 1),
    );
  }

  static void insertAudio({
    required String audioName,
    required QuillController quillController,
  }) {
    final audioBlock = AudioBlockEmbed.fromName(audioName);
    final index = quillController.selection.baseOffset;
    final length = quillController.selection.extentOffset - index;
    quillController.replaceText(
      index,
      length,
      audioBlock,
      TextSelection.collapsed(offset: index + 1),
    );
  }

  // ---- 私有辅助方法（域/domain 逻辑） ----
  bool _isMemoirDiary(Diary diary) {
    return DiaryTemplateConst.hasMemoirTag(diary.tags);
  }

  bool _matchDiaryDomain(Diary diary, DiaryDomain? domain) {
    if (domain == null) return true;
    // note domain 只匹配自身，不混入 normal/memoir
    if (diary.domain == DiaryDomain.note.value) {
      return domain == DiaryDomain.note;
    }
    final isMemoir = _isMemoirDiary(diary);
    if (domain == DiaryDomain.note) return false;
    return domain == DiaryDomain.memoir ? isMemoir : !isMemoir;
  }

  Diary _hydrateDiaryDomain(Diary diary) {
    // note domain 不参与旧版推断逻辑
    if (diary.domain == DiaryDomain.note.value) return diary;
    if (diary.domain == DiaryDomain.normal.value) {
      final inferredIsMemoir = _isMemoirDiary(diary);
      if (inferredIsMemoir) {
        diary.domain = DiaryDomain.memoir.value;
      }
    }
    return diary;
  }

  bool _isMemoirCategory(Category category) {
    return category.id.startsWith('memoir_') ||
        category.domain == DiaryDomain.memoir.value;
  }

  bool _matchCategoryDomain(Category category, DiaryDomain domain) {
    final isMemoir = _isMemoirCategory(category);
    return domain == DiaryDomain.memoir ? isMemoir : !isMemoir;
  }

  Category _hydrateCategoryDomain(Category category) {
    if (category.domain == DiaryDomain.normal.value &&
        category.id.startsWith('memoir_')) {
      category.domain = DiaryDomain.memoir.value;
    }
    return category;
  }

  void _normalizeDiaryDomainTag(Diary diary) {
    final hasMemoirTag = DiaryTemplateConst.hasMemoirTag(diary.tags);
    final domain = hasMemoirTag
        ? DiaryDomain.memoir
        : DiaryDomain.fromValue(diary.domain);
    diary.domain = domain.value;
    if (domain == DiaryDomain.memoir) {
      diary.tags.removeWhere(
        (tag) => tag == DiaryTemplateConst.legacyMemoirTag,
      );
      if (!diary.tags.contains(DiaryTemplateConst.memoirTag)) {
        diary.tags.add(DiaryTemplateConst.memoirTag);
      }
    } else {
      diary.tags.removeWhere(
        (tag) =>
            tag == DiaryTemplateConst.memoirTag ||
            tag == DiaryTemplateConst.legacyMemoirTag,
      );
    }
  }

  // ---- 实例方法（真正的实现） ----
  Future<void> _dataMigration(String path) async {
    final oldIsar = await Isar.openAsync(
      schemas: _schemas,
      directory: path,
      name: 'old',
    );
    final List<Diary> oldDiaryList = await oldIsar.diarys
        .where()
        .findAllAsync();
    final List<Category> oldCategoryList = await oldIsar.categorys
        .where()
        .findAllAsync();
    final List<Font> oldFontList = await oldIsar.fonts.where().findAllAsync();

    await _isar.writeAsync((isar) {
      isar.clear();
      isar.diarys.putAll(oldDiaryList);
      isar.categorys.putAll(oldCategoryList);
      isar.fonts.putAll(oldFontList);
    });
    oldIsar.close(deleteFromDisk: true);
  }

  Future<void> _clearIsar() async {
    await _isar.writeAsync((isar) {
      isar.clear();
    });
  }

  Map<String, dynamic> _getSize() {
    return FileUtil.bytesToUnits(_isar.diarys.getSize(includeIndexes: true));
  }

  Future<void> _exportIsar(
    String dir,
    String path,
    String fileName,
  ) async {
    final isar = Isar.open(schemas: _schemas, directory: join(dir, 'database'));
    try {
      isar.copyToFile(join(path, fileName));
    } finally {
      isar.close();
    }
  }

  Future<void> _insertADiary(Diary diary) async {
    _normalizeDiaryDomainTag(diary);
    await _isar.writeAsync((isar) {
      isar.diarys.put(diary);
    });
  }

  Future<List<Diary>> _getDiaryByMonth(int year, int month) async {
    final diaries = await _isar.diarys
        .where()
        .showEqualTo(true)
        .yMEqualTo('${year.toString()}/${month.toString()}')
        .sortByTimeDesc()
        .findAllAsync();
    return diaries.map(_hydrateDiaryDomain).toList();
  }

  Future<Diary?> _getDiaryByID(int isarId) async {
    final diary = await _isar.diarys.getAsync(isarId);
    if (diary == null) return null;
    return _hydrateDiaryDomain(diary);
  }

  Future<List<Diary>> _getDiariesByDateRange(
    DateTime start,
    DateTime end, {
    bool all = true,
  }) async {
    final diaries = await _isar.diarys
        .where()
        .timeBetween(start, end)
        .showEqualTo(all)
        .findAllAsync();
    return diaries.map(_hydrateDiaryDomain).toList();
  }

  Future<List<Diary>> _getAllDiaries({DiaryDomain? domain}) async {
    final diaries = await _isar.diarys.where().findAllAsync();
    final filtered = diaries.where((diary) => _matchDiaryDomain(diary, domain));
    return filtered.map(_hydrateDiaryDomain).toList();
  }

  List<Diary> _getAllDiariesSync({DiaryDomain? domain}) {
    final diaries = _isar.diarys.where().findAll();
    final filtered = diaries.where((diary) => _matchDiaryDomain(diary, domain));
    return filtered.map(_hydrateDiaryDomain).toList();
  }

  Future<List<Diary>> _getAllDiariesSorted() async {
    final diaries = await _isar.diarys
        .where()
        .showEqualTo(true)
        .sortByTimeDesc()
        .findAllAsync();
    return diaries.map(_hydrateDiaryDomain).toList();
  }

  Future<List<List<String>>> _getWeatherByDateRange(
    DateTime start,
    DateTime end, {
    DiaryDomain? domain,
  }) async {
    final diaries = await _isar.diarys
        .where()
        .showEqualTo(true)
        .timeBetween(start, end)
        .sortByTime()
        .findAllAsync();

    final weatherByDay = <String, List<String>>{};
    for (final diary in diaries) {
      if (!_matchDiaryDomain(diary, domain)) continue;
      weatherByDay.putIfAbsent(diary.yMd, () => diary.weather);
    }
    return weatherByDay.values.toList();
  }

  Future<List<double>> _getMoodByDateRange(
    DateTime start,
    DateTime end, {
    DiaryDomain? domain,
  }) async {
    final diaries = await _isar.diarys
        .where()
        .showEqualTo(true)
        .timeBetween(start, end)
        .sortByTime()
        .findAllAsync();

    final moodByDay = <String, double>{};
    for (final diary in diaries) {
      if (!_matchDiaryDomain(diary, domain)) continue;
      moodByDay.putIfAbsent(diary.yMd, () => diary.mood);
    }
    return moodByDay.values.toList();
  }

  Future<bool> _deleteADiary(int isarId) async {
    return await _isar.writeAsync((isar) {
      return isar.diarys.delete(isarId);
    });
  }

  Future<List<Diary>> _getRecycleBinDiaries() async {
    final diaries = await _isar.diarys
        .where()
        .showEqualTo(false)
        .sortByTimeDesc()
        .findAllAsync();
    return diaries.map(_hydrateDiaryDomain).toList();
  }

  Future<void> _updateADiary({
    Diary? oldDiary,
    required Diary newDiary,
  }) async {
    _normalizeDiaryDomainTag(newDiary);
    newDiary.lastModified = DateTime.now();
    await _isar.writeAsync((isar) {
      isar.diarys.put(newDiary);
    });
    if (oldDiary != null) {
      await FileUtil.cleanUpOldMediaFiles(oldDiary, newDiary);
      if (WebDavUtil().hasOption &&
          PrefUtil.getValue<bool>(PrefKeys.autoSyncAfterChange) == true) {
        unawaited(
          WebDavUtil().updateSingleDiary(
            oldDiary: oldDiary,
            newDiary: newDiary,
          ),
        );
      }
    } else {
      if (WebDavUtil().hasOption &&
          PrefUtil.getValue<bool>(PrefKeys.autoSyncAfterChange) == true) {
        unawaited(WebDavUtil().uploadSingleDiary(newDiary));
      }
    }
  }

  Future<List<Diary>> _searchDiaries({
    required List<String> queryList,
    DiaryDomain? domain,
  }) async {
    if (queryList.isEmpty) return [];

    final HashSet<Diary> results = HashSet(
      equals: (a, b) {
        return a.isarId == b.isarId;
      },
      hashCode: (e) {
        return e.isarId;
      },
    );

    for (final word in queryList) {
      final matches = await _isar.diarys
          .where()
          .showEqualTo(true)
          .tokenizerElementMatches(word, caseSensitive: false)
          .or()
          .titleContains(word, caseSensitive: false)
          .or()
          .tagsElementContains(word, caseSensitive: false)
          .findAllAsync();
      results.addAll(matches);
    }

    final List<Diary> sortedResults =
        results
            .where((diary) => _matchDiaryDomain(diary, domain))
            .map(_hydrateDiaryDomain)
            .toList()
          ..sort((a, b) => b.time.compareTo(a.time));

    return sortedResults;
  }

  Future<List<Diary>> _searchDiariesByTag(
    String value, {
    DiaryDomain? domain,
  }) async {
    final diaries = await _isar.diarys
        .where()
        .showEqualTo(true)
        .tagsElementContains(value)
        .findAllAsync();
    return diaries
        .where((diary) => _matchDiaryDomain(diary, domain))
        .map(_hydrateDiaryDomain)
        .toList();
  }

  Future<int> _countShowDiary() async {
    return await _isar.diarys.where().showEqualTo(true).countAsync();
  }

  int _countAllDiary() {
    return _isar.diarys.count();
  }

  int _countCategories({DiaryDomain? domain}) {
    if (domain == null) return _isar.categorys.count();
    return _isar.categorys
        .where()
        .findAll()
        .where((category) => _matchCategoryDomain(category, domain))
        .length;
  }

  Category? _getCategoryName(String id) {
    return _isar.categorys.get(id);
  }

  Future<bool> _insertACategory(
    Category category, {
    DiaryDomain domain = DiaryDomain.normal,
  }) async {
    return await _isar.writeAsync((isar) {
      Category? existingCategory;
      for (final element in isar.categorys.where().findAll()) {
        if (element.categoryName == category.categoryName &&
            _matchCategoryDomain(element, domain)) {
          existingCategory = element;
          break;
        }
      }
      if (existingCategory != null) {
        category.categoryName =
            '${category.categoryName}_${const Uuid().v4().substring(0, 4)}';
      }
      category.id = domain == DiaryDomain.memoir
          ? 'memoir_${const Uuid().v7()}'
          : const Uuid().v7();
      category.domain = domain.value;
      isar.categorys.put(category);
      return existingCategory == null;
    });
  }

  Future<bool> _updateACategory(Category category) async {
    return await _isar.writeAsync((isar) {
      final domain = _isMemoirCategory(category)
          ? DiaryDomain.memoir
          : DiaryDomain.normal;
      category.domain = domain.value;
      String? oldCategoryId;
      if (domain == DiaryDomain.memoir && !category.id.startsWith('memoir_')) {
        oldCategoryId = category.id;
        category.id = 'memoir_${category.id}';
      }
      Category? existingCategory;
      for (final element in isar.categorys.where().findAll()) {
        if (element.id != category.id &&
            element.categoryName == category.categoryName &&
            _matchCategoryDomain(element, domain)) {
          existingCategory = element;
          break;
        }
      }
      if (existingCategory != null && existingCategory.id != category.id) {
        category.categoryName =
            '${category.categoryName}_${const Uuid().v4().substring(0, 4)}';
      }
      isar.categorys.put(category);
      if (oldCategoryId != null) {
        final diaries = isar.diarys
            .where()
            .categoryIdEqualTo(oldCategoryId)
            .findAll();
        for (final diary in diaries) {
          diary.categoryId = category.id;
          _normalizeDiaryDomainTag(diary);
        }
        if (diaries.isNotEmpty) {
          isar.diarys.putAll(diaries);
        }
        isar.categorys.delete(oldCategoryId);
      }
      return existingCategory == null;
    });
  }

  Future<bool> _deleteACategory(String id) async {
    return await _isar.writeAsync((isar) {
      if (isar.diarys.where().categoryIdEqualTo(id).isEmpty()) {
        return isar.categorys.delete(id);
      } else {
        return false;
      }
    });
  }

  Future<List<String>> _getContentList({DiaryDomain? domain}) async {
    final diaries = await _isar.diarys.where().showEqualTo(true).findAllAsync();
    return diaries
        .where((diary) => _matchDiaryDomain(diary, domain))
        .map((diary) => diary.contentText)
        .toList();
  }

  List<Category> _getAllCategory({
    DiaryDomain domain = DiaryDomain.normal,
  }) {
    final list = _isar.categorys
        .where()
        .domainEqualTo(domain.value)
        .findAll()
        .map(_hydrateCategoryDomain)
        .toList();
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  Future<List<Category>> _getAllCategoryAsync({
    DiaryDomain domain = DiaryDomain.normal,
  }) async {
    final list = await _isar.categorys
        .where()
        .domainEqualTo(domain.value)
        .findAllAsync();
    final result = list.map(_hydrateCategoryDomain).toList();
    result.sort((a, b) => a.id.compareTo(b.id));
    return result;
  }

  Future<List<Diary>> _getDiaryByTag(
    String? tagName,
    int offset,
    int limit, {
    DiaryDomain domain = DiaryDomain.normal,
  }) async {
    final List<Diary> raw;
    if (tagName != null) {
      raw = await _isar.diarys
          .where()
          .showEqualTo(true)
          .tagsElementEqualTo(tagName)
          .findAllAsync();
    } else {
      raw = await _isar.diarys.where().showEqualTo(true).findAllAsync();
    }

    final filtered =
        raw
            .where((diary) {
              return _matchDiaryDomain(diary, domain);
            })
            .map(_hydrateDiaryDomain)
            .toList()
          ..sort((a, b) => b.time.compareTo(a.time));

    final safeOffset = offset.clamp(0, filtered.length);
    final end = (safeOffset + limit).clamp(0, filtered.length);
    return filtered.sublist(safeOffset, end);
  }

  Future<List<Diary>> _getDiaryByDay(DateTime time) async {
    final diaries = await _isar.diarys
        .where()
        .showEqualTo(true)
        .yMdEqualTo(
          '${time.year.toString()}/${time.month.toString()}/${time.day.toString()}',
        )
        .sortByTimeDesc()
        .findAllAsync();
    return diaries.map(_hydrateDiaryDomain).toList();
  }

  Future<List<Diary>> _getDiary(int offset, int limit) async {
    final diaries = await _isar.diarys.where().findAllAsync(
      offset: offset,
      limit: limit,
    );
    return diaries.map(_hydrateDiaryDomain).toList();
  }

  /// v2.7.4 版本变更
  Future<void> mergeToV2_7_4(String dir) async {
    final countDiary = _isar.diarys.where().count();
    for (var i = 0; i < countDiary; i += 50) {
      final diaries = await _isar.diarys.where().findAllAsync(
        offset: i,
        limit: 50,
      );
      for (final diary in diaries) {
        final newContent = diary.contentText.removeLineBreaks();
        diary.tokenizer = await JiebaRs.cutAll(text: newContent);
        final keywords = await JiebaRs.extractKeywordsTfidf(
          text: newContent,
          topK: BigInt.from(5),
          allowedPos: [],
        );
        final sortByWeight = keywords
          ..sort((a, b) => b.weight.compareTo(a.weight));
        final sortedKeywords = sortByWeight.map((e) => e.keyword).toList();
        diary.keywords = sortedKeywords;
        diary.contentText = newContent;
        await _isar.writeAsync((isar) {
          isar.diarys.put(diary);
        });
      }
    }
  }

  Future<void> _migrateDomainField() async {
    final diaryCount = _isar.diarys.where().count();
    for (var i = 0; i < diaryCount; i += 50) {
      final batch = await _isar.diarys.where().findAllAsync(
        offset: i,
        limit: 50,
      );
      await _isar.writeAsync((isar) {
        for (final diary in batch) {
          final isMemoir = _isMemoirDiary(diary);
          diary.domain = (isMemoir ? DiaryDomain.memoir : DiaryDomain.normal).value;
          isar.diarys.put(diary);
        }
      });
    }
    final categoryCount = _isar.categorys.count();
    for (var i = 0; i < categoryCount; i += 50) {
      final batch = _isar.categorys.where().findAll(offset: i, limit: 50);
      await _isar.writeAsync((isar) {
        for (final category in batch) {
          final isMemoir = _isMemoirCategory(category);
          category.domain = (isMemoir ? DiaryDomain.memoir : DiaryDomain.normal).value;
          isar.categorys.put(category);
        }
      });
    }
  }

  Future<List<DiaryMapItem>> _getAllMapItem() async {
    final List<DiaryMapItem> res = [];
    final diaries = await _isar.diarys
        .where()
        .showEqualTo(true)
        .positionIsNotEmpty()
        .findAllAsync();
    for (final diary in diaries) {
      res.add(
        DiaryMapItem(
          LatLng(
            double.parse(diary.position[0]),
            double.parse(diary.position[1]),
          ),
          diary.isarId,
          diary.imageName.isEmpty ? '' : diary.imageName.first,
        ),
      );
    }
    return res;
  }

  Future<void> _addSyncRecord(SyncRecord record) async {
    await _isar.writeAsync((isar) {
      isar.syncRecords.put(record);
    });
  }

  Future<List<SyncRecord>> _getSyncRecords() async {
    return await _isar.syncRecords.where().findAllAsync();
  }

  Future<void> _deleteSyncRecord(int id) async {
    await _isar.writeAsync((isar) {
      isar.syncRecords.delete(id);
    });
  }

  Future<List<Font>> _getAllFonts() async {
    return await _isar.fonts.where().findAllAsync();
  }

  Future<void> _insertAFont(Font font) async {
    await _isar.writeAsync((isar) {
      isar.fonts.put(font);
    });
  }

  Future<Font?> _getFontByFontFamily(String fontFamily) async {
    return await _isar.fonts
        .where()
        .fontFamilyEqualTo(fontFamily)
        .findFirstAsync();
  }

  Future<bool> _deleteFont(int id) async {
    return await _isar.writeAsync((isar) {
      return isar.fonts.delete(id);
    });
  }
}
