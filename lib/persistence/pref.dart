import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:moodiary/common/values/colors.dart';
import 'package:moodiary/common/values/view_mode.dart';
import 'package:moodiary/merge/merge.dart';
import 'package:moodiary/utils/auth_util.dart';
import 'package:moodiary/utils/file_util.dart';
import 'package:moodiary/utils/package_util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moodiary/common/values/pref_keys.dart';

class PrefUtil {
  late final SharedPreferencesWithCache _prefs;

  // ---- 门面：让所有调用者的 PrefUtil.xxx 静态调用继续工作 ----
  static PrefUtil get _i => Get.find<PrefUtil>();

  static const allowList = {
    //应用版本
    PrefKeys.appVersion,
    //首次启动标识
    PrefKeys.firstStart,
    //自动同步
    PrefKeys.autoSync,
    //主题颜色
    PrefKeys.color,
    //主题颜色类型
    PrefKeys.colorType,
    //主题模式
    PrefKeys.themeMode,
    //动态配色
    PrefKeys.dynamicColor,
    //图片质量
    PrefKeys.quality,
    //本地化
    PrefKeys.local,
    //应用锁
    PrefKeys.lock,
    //uuid
    PrefKeys.uuid,
    //字体缩放
    PrefKeys.fontScale,
    //立即锁定
    PrefKeys.lockNow,
    //字体样式
    PrefKeys.fontTheme,
    //和风key
    PrefKeys.qweatherKey,
    // 和风apihost,
    PrefKeys.qweatherApiHost,
    PrefKeys.tencentId,
    PrefKeys.tencentKey,
    PrefKeys.tiandituKey,
    //侧边栏天气
    PrefKeys.getWeather,
    //天气缓存
    PrefKeys.weather,
    //一言缓存
    PrefKeys.hitokoto,
    //图片缓存
    PrefKeys.bingImage,
    //第一次打开的时间
    PrefKeys.startTime,
    //应用文档路径
    PrefKeys.supportPath,
    //缓存路径
    PrefKeys.cachePath,
    //密码
    PrefKeys.password,
    //生物识别支持
    PrefKeys.supportBiometrics,
    //自定义首页名称
    PrefKeys.customTitleName,
    //自定义首页副标题名称
    PrefKeys.customSubTitleName,
    //导航栏激活的 Tab 列表
    PrefKeys.activeTabs,
    //首页视图模式
    PrefKeys.homeViewMode,
    //自动获取天气
    PrefKeys.autoWeather,
    //webdav配置（凭据已迁移至 SecureStorage）
    PrefKeys.webDavOption,
    // webdav是否已配置标志（凭据不存 SharedPreferences）
    PrefKeys.hasWebDavOption,
    // domain 字段持久化迁移标志
    PrefKeys.domainFieldMigrated,
    // 日记展示头图
    PrefKeys.diaryHeader,
    // 首行缩进
    PrefKeys.firstLineIndent,
    // 自动设置分类
    PrefKeys.autoCategory,
    // 展示写作时长
    PrefKeys.showWritingTime,
    // 展示字数统计
    PrefKeys.showWordCount,
    // 自定义字体
    PrefKeys.customFont,
    // 后台隐私保护
    PrefKeys.backendPrivacy,
    // 日记状态改变时同步
    PrefKeys.autoSyncAfterChange,
    // 语言
    PrefKeys.language,
    // webdav加密
    PrefKeys.syncEncryption,
  };

  // ---- 静态门面方法（保持向后兼容） ----
  static Future<void> setValue<T>(String key, T value) => _i._setValue(key, value);
  static T? getValue<T>(String key) => _i._getValue(key);
  static Future<void> removeValue(String key) => _i._removeValue(key);

  // ---- 实例方法（真正的实现） ----
  Future<String?> initPref() async {
    _prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: allowList,
      ),
    );
    // 首次启动
    final firstStart = _prefs.getBool(PrefKeys.firstStart) ?? true;
    await _prefs.setBool(PrefKeys.firstStart, firstStart);

    // 获取当前应用版本
    final packageInfo = await PackageUtil.getPackageInfo();
    final currentVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    final appVersion = _prefs.getString(PrefKeys.appVersion);

    // 如果是首次启动或版本不一致
    if (kDebugMode ||
        firstStart ||
        appVersion == null ||
        appVersion != currentVersion) {
      await _prefs.setString(PrefKeys.appVersion, currentVersion);
      await _setDefaultValues();
    }
    
    return appVersion;
  }

  // 设置默认值的方法
  Future<void> _setDefaultValues() async {
    await _prefs.setBool(PrefKeys.autoSync, _prefs.getBool(PrefKeys.autoSync) ?? false);

    /// 支持相关，每次都重新获取
    await _prefs.setBool(
      PrefKeys.supportBiometrics,
      await AuthUtil.canCheckBiometrics(),
    );

    await _prefs.setInt(
      PrefKeys.colorType,
      _prefs.getInt(PrefKeys.colorType) ?? AppColorType.common.value,
    );
    await _prefs.setInt(PrefKeys.themeMode, _prefs.getInt(PrefKeys.themeMode) ?? 0);
    await _prefs.setBool(
      PrefKeys.dynamicColor,
      _prefs.getBool(PrefKeys.dynamicColor) ?? true,
    );
    await _prefs.setInt(PrefKeys.quality, _prefs.getInt(PrefKeys.quality) ?? 2);
    await _prefs.setBool(PrefKeys.local, _prefs.getBool(PrefKeys.local) ?? false);
    await _prefs.setBool(PrefKeys.lock, _prefs.getBool(PrefKeys.lock) ?? false);
    await _prefs.setDouble(PrefKeys.fontScale, _prefs.getDouble(PrefKeys.fontScale) ?? 1.0);
    await _prefs.setBool(PrefKeys.lockNow, _prefs.getBool(PrefKeys.lockNow) ?? false);
    await _prefs.setInt(PrefKeys.fontTheme, _prefs.getInt(PrefKeys.fontTheme) ?? 0);

    /// 支持相关，重新获取
    await _prefs.setString(
      PrefKeys.supportPath,
      (await getApplicationSupportDirectory()).path,
    );
    await _prefs.setString(
      PrefKeys.cachePath,
      (await getApplicationCacheDirectory()).path,
    );

    await _prefs.setBool(PrefKeys.getWeather, _prefs.getBool(PrefKeys.getWeather) ?? false);
    await _prefs.setInt(
      PrefKeys.startTime,
      _prefs.getInt(PrefKeys.startTime) ?? DateTime.now().millisecondsSinceEpoch,
    );
    await _prefs.setString(
      PrefKeys.customTitleName,
      _prefs.getString(PrefKeys.customTitleName) ?? '',
    );
    await _prefs.setString(
      PrefKeys.customSubTitleName,
      _prefs.getString(PrefKeys.customSubTitleName) ?? '',
    );
    await _prefs.setStringList(
      PrefKeys.activeTabs,
      _prefs.getStringList(PrefKeys.activeTabs) ??
          ['diary', 'memoir', 'calendar', 'media', 'setting'],
    );
    await _prefs.setInt(
      PrefKeys.homeViewMode,
      _prefs.getInt(PrefKeys.homeViewMode) ?? ViewModeType.list.number,
    );
    await _prefs.setBool(PrefKeys.autoWeather, _prefs.getBool(PrefKeys.autoWeather) ?? false);
    await _prefs.setBool(
      PrefKeys.hasWebDavOption,
      _prefs.getBool(PrefKeys.hasWebDavOption) ?? false,
    );
    await _prefs.setBool(PrefKeys.diaryHeader, _prefs.getBool(PrefKeys.diaryHeader) ?? true);
    await _prefs.setBool(
      PrefKeys.firstLineIndent,
      _prefs.getBool(PrefKeys.firstLineIndent) ?? false,
    );
    await _prefs.setBool(
      PrefKeys.autoCategory,
      _prefs.getBool(PrefKeys.autoCategory) ?? false,
    );
    await _prefs.setBool(
      PrefKeys.showWritingTime,
      _prefs.getBool(PrefKeys.showWritingTime) ?? true,
    );
    await _prefs.setBool(
      PrefKeys.showWordCount,
      _prefs.getBool(PrefKeys.showWordCount) ?? true,
    );
    await _prefs.setString(PrefKeys.customFont, _prefs.getString(PrefKeys.customFont) ?? '');
    await _prefs.setBool(
      PrefKeys.backendPrivacy,
      _prefs.getBool(PrefKeys.backendPrivacy) ?? true,
    );
    await _prefs.setBool(
      PrefKeys.autoSyncAfterChange,
      _prefs.getBool(PrefKeys.autoSyncAfterChange) ?? false,
    );
    await _prefs.setString(
      PrefKeys.language,
      _prefs.getString(PrefKeys.language) ?? 'system',
    );
    await _prefs.setBool(
      PrefKeys.syncEncryption,
      _prefs.getBool(PrefKeys.syncEncryption) ?? false,
    );
  }

  Future<void> _setValue<T>(String key, T value) async {
    if (T == int) {
      await _prefs.setInt(key, value as int);
    } else if (T == bool) {
      await _prefs.setBool(key, value as bool);
    } else if (T == double) {
      await _prefs.setDouble(key, value as double);
    } else if (T == String) {
      await _prefs.setString(key, value as String);
    } else if (T == List<String>) {
      await _prefs.setStringList(key, value as List<String>);
    } else {
      throw ArgumentError('Unsupported type: $T');
    }
  }

  T? _getValue<T>(String key) {
    if (T == int) {
      return _prefs.getInt(key) as T?;
    } else if (T == bool) {
      return _prefs.getBool(key) as T?;
    } else if (T == double) {
      return _prefs.getDouble(key) as T?;
    } else if (T == String) {
      return _prefs.getString(key) as T?;
    } else if (T == List<String>) {
      return _prefs.getStringList(key) as T?;
    } else {
      throw ArgumentError('Unsupported type: $T');
    }
  }

  Future<void> _removeValue(String key) async {
    await _prefs.remove(key);
  }
}
