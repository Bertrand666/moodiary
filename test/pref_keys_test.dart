import 'package:flutter_test/flutter_test.dart';
import 'package:moodiary/common/values/pref_keys.dart';
import 'package:moodiary/persistence/pref.dart';

void main() {
  group('PrefKeys validation', () {
    test('all expected PrefKeys should exist in PrefUtil.allowList', () {
      final expectedKeys = [
        PrefKeys.appVersion,
        PrefKeys.firstStart,
        PrefKeys.autoSync,
        PrefKeys.color,
        PrefKeys.colorType,
        PrefKeys.themeMode,
        PrefKeys.dynamicColor,
        PrefKeys.quality,
        PrefKeys.local,
        PrefKeys.lock,
        PrefKeys.uuid,
        PrefKeys.fontScale,
        PrefKeys.lockNow,
        PrefKeys.fontTheme,
        PrefKeys.qweatherKey,
        PrefKeys.qweatherApiHost,
        PrefKeys.tencentId,
        PrefKeys.tencentKey,
        PrefKeys.tiandituKey,
        PrefKeys.getWeather,
        PrefKeys.weather,
        PrefKeys.hitokoto,
        PrefKeys.bingImage,
        PrefKeys.startTime,
        PrefKeys.supportPath,
        PrefKeys.cachePath,
        // Using string directly for deprecated keys to avoid warnings, though they should be in allowList if supported
        'password', 
        PrefKeys.supportBiometrics,
        PrefKeys.customTitleName,
        PrefKeys.homeViewMode,
        PrefKeys.autoWeather,
        'webDavOption',
        PrefKeys.hasWebDavOption,
        PrefKeys.domainFieldMigrated,
        PrefKeys.diaryHeader,
        PrefKeys.firstLineIndent,
        PrefKeys.autoCategory,
        PrefKeys.showWritingTime,
        PrefKeys.showWordCount,
        PrefKeys.customFont,
        PrefKeys.backendPrivacy,
        PrefKeys.autoSyncAfterChange,
        PrefKeys.language,
        PrefKeys.syncEncryption,
      ];

      for (final key in expectedKeys) {
        expect(
          PrefUtil.allowList.contains(key),
          isTrue,
          reason: 'Key "$key" is missing from PrefUtil.allowList',
        );
      }
    });

    test('allowList should not contain unexpected keys', () {
      final expectedKeys = {
        PrefKeys.appVersion,
        PrefKeys.firstStart,
        PrefKeys.autoSync,
        PrefKeys.color,
        PrefKeys.colorType,
        PrefKeys.themeMode,
        PrefKeys.dynamicColor,
        PrefKeys.quality,
        PrefKeys.local,
        PrefKeys.lock,
        PrefKeys.uuid,
        PrefKeys.fontScale,
        PrefKeys.lockNow,
        PrefKeys.fontTheme,
        PrefKeys.qweatherKey,
        PrefKeys.qweatherApiHost,
        PrefKeys.tencentId,
        PrefKeys.tencentKey,
        PrefKeys.tiandituKey,
        PrefKeys.getWeather,
        PrefKeys.weather,
        PrefKeys.hitokoto,
        PrefKeys.bingImage,
        PrefKeys.startTime,
        PrefKeys.supportPath,
        PrefKeys.cachePath,
        'password',
        PrefKeys.supportBiometrics,
        PrefKeys.customTitleName,
        PrefKeys.homeViewMode,
        PrefKeys.autoWeather,
        'webDavOption',
        PrefKeys.hasWebDavOption,
        PrefKeys.domainFieldMigrated,
        PrefKeys.diaryHeader,
        PrefKeys.firstLineIndent,
        PrefKeys.autoCategory,
        PrefKeys.showWritingTime,
        PrefKeys.showWordCount,
        PrefKeys.customFont,
        PrefKeys.backendPrivacy,
        PrefKeys.autoSyncAfterChange,
        PrefKeys.language,
        PrefKeys.syncEncryption,
      };

      for (final key in PrefUtil.allowList) {
        expect(
          expectedKeys.contains(key),
          isTrue,
          reason: 'Found unexpected key "$key" in PrefUtil.allowList',
        );
      }
    });
  });
}
