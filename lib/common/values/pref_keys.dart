/// 所有 SharedPreferences key 的类型安全常量
///
/// 使用示例：
/// ```dart
/// PrefUtil.getValue<bool>(PrefKeys.autoSync)
/// PrefUtil.setValue<bool>(PrefKeys.lock, true)
/// ```
class PrefKeys {
  const PrefKeys._();

  /// 应用版本
  static const String appVersion = 'appVersion';

  /// 首次启动标识
  static const String firstStart = 'firstStart';

  /// 自动同步
  static const String autoSync = 'autoSync';

  /// 主题颜色（int，-1 = 动态）
  static const String color = 'color';

  /// 主题颜色类型
  static const String colorType = 'colorType';

  /// 主题模式（0=system, 1=light, 2=dark）
  static const String themeMode = 'themeMode';

  /// 动态配色
  static const String dynamicColor = 'dynamicColor';

  /// 图片压缩质量（1~3）
  static const String quality = 'quality';

  /// 本地化
  static const String local = 'local';

  /// 应用锁开关
  static const String lock = 'lock';

  /// 设备 UUID
  static const String uuid = 'uuid';

  /// 字体缩放比例
  static const String fontScale = 'fontScale';

  /// 立即锁定
  static const String lockNow = 'lockNow';

  /// 字体样式
  static const String fontTheme = 'fontTheme';

  /// 和风天气 Key
  static const String qweatherKey = 'qweatherKey';

  /// 和风天气 API Host
  static const String qweatherApiHost = 'qweatherApiHost';

  /// 腾讯云 SecretId
  static const String tencentId = 'tencentId';

  /// 腾讯云 SecretKey
  static const String tencentKey = 'tencentKey';

  /// 天地图 API Key
  static const String tiandituKey = 'tiandituKey';

  /// 侧边栏自动获取天气
  static const String getWeather = 'getWeather';

  /// 天气缓存
  static const String weather = 'weather';

  /// 一言缓存
  static const String hitokoto = 'hitokoto';

  /// Bing 背景图缓存
  static const String bingImage = 'bingImage';

  /// 应用首次打开时间（毫秒时间戳）
  static const String startTime = 'startTime';

  /// 应用文档存储路径
  static const String supportPath = 'supportPath';

  /// 缓存路径
  static const String cachePath = 'cachePath';

  /// （废弃）旧版密码（已迁移至 SecureStorage）
  @Deprecated('已迁移至 SecureStorage，key: lockPassword')
  static const String password = 'password';

  /// 设备是否支持生物识别
  static const String supportBiometrics = 'supportBiometrics';

  /// 自定义首页标题名称
  static const String customTitleName = 'customTitleName';

  /// 首页视图模式
  static const String homeViewMode = 'homeViewMode';

  /// 自动获取天气
  static const String autoWeather = 'autoWeather';

  /// （废弃）旧版 WebDAV 配置（凭据已迁移至 SecureStorage）
  @Deprecated('凭据已迁移至 SecureStorage')
  static const String webDavOption = 'webDavOption';

  /// WebDAV 是否已配置（凭据不存 SharedPreferences）
  static const String hasWebDavOption = 'hasWebDavOption';

  /// Domain 字段持久化迁移标志
  static const String domainFieldMigrated = 'domainFieldMigrated';

  /// 日记展示头图
  static const String diaryHeader = 'diaryHeader';

  /// 首行缩进
  static const String firstLineIndent = 'firstLineIndent';

  /// 自动设置分类
  static const String autoCategory = 'autoCategory';

  /// 展示写作时长
  static const String showWritingTime = 'showWritingTime';

  /// 展示字数统计
  static const String showWordCount = 'showWordCount';

  /// 自定义字体路径
  static const String customFont = 'customFont';

  /// 后台隐私保护（切换到后台时模糊截图）
  static const String backendPrivacy = 'backendPrivacy';

  /// 日记状态改变时同步
  static const String autoSyncAfterChange = 'autoSyncAfterChange';

  /// 界面语言
  static const String language = 'language';

  /// WebDAV 同步加密
  static const String syncEncryption = 'syncEncryption';
}
