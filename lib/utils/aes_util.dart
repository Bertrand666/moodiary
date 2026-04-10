import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:moodiary/persistence/pref.dart';
import 'package:moodiary/src/rust/api/aes.dart';
import 'package:moodiary/common/values/pref_keys.dart';

class AesUtil {
  /// 生成密钥
  static Future<Uint8List> deriveKey({
    required String salt,
    required String userKey,
  }) async {
    return await AesEncryption.deriveKey(salt: salt, userKey: userKey);
  }

  /// 加密数据
  static Future<Uint8List> encrypt({
    required Uint8List key,
    required String data,
  }) async {
    final keyBytes = key;
    final dataBytes = utf8.encode(data);
    final encrypted = await AesEncryption.encrypt(
      key: keyBytes,
      data: dataBytes,
    );

    return encrypted;
  }

  /// 解密数据
  static Future<String> decrypt({
    required Uint8List key,
    required Uint8List encryptedData,
  }) async {
    final keyBytes = key;
    final encryptedBytes = encryptedData;
    final decrypted = await AesEncryption.decrypt(
      key: keyBytes,
      encryptedData: encryptedBytes,
    );
    return utf8.decode(decrypted);
  }

  /// HMAC-SHA256 替代不安全的 MD5
  static String _hmacSha256(String key, String message) {
    final hmac = Hmac(sha256, utf8.encode(key));
    return hmac.convert(utf8.encode(message)).toString();
  }

  /// 基于时间窗口加密
  static Future<Uint8List> encryptWithTimeWindow({
    required String data,
    required Duration validDuration,
  }) async {
    final timeSlot = _currentTimeSlot(validDuration);
    final deviceId = PrefUtil.getValue<String>(PrefKeys.uuid) ?? 'default-device';
    final dynamicKey = _hmacSha256(deviceId, timeSlot.toString());
    final salt = _dailySalt();

    final aesKey = await deriveKey(salt: salt, userKey: dynamicKey);
    return await encrypt(key: aesKey, data: data);
  }

  /// 基于时间窗口解密
  static Future<String?> decryptWithTimeWindow({
    required Uint8List encryptedData,
    required Duration validDuration,
    int toleranceSlots = 1,
  }) async {
    final currentSlot = _currentTimeSlot(validDuration);
    final deviceId = PrefUtil.getValue<String>(PrefKeys.uuid) ?? 'default-device';
    final salt = _dailySalt();

    for (int offset = 0; offset <= toleranceSlots; offset++) {
      for (final slot in [currentSlot - offset, currentSlot + offset]) {
        final dynamicKey = _hmacSha256(deviceId, slot.toString());
        final aesKey = await deriveKey(salt: salt, userKey: dynamicKey);
        try {
          final result = await decrypt(
            key: aesKey,
            encryptedData: encryptedData,
          );
          return result;
        } catch (_) {
          continue;
        }
      }
    }

    return null;
  }

  static int _currentTimeSlot(Duration duration) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return now ~/ duration.inMilliseconds;
  }

  /// 使用 HMAC-SHA256 + 设备 UUID 生成不可预测的 daily salt
  static String _dailySalt() {
    final date = DateTime.now();
    final dateStr = '${date.year}-${date.month}-${date.day}';
    final deviceId = PrefUtil.getValue<String>(PrefKeys.uuid) ?? 'default-device';
    return _hmacSha256(deviceId, dateStr);
  }
}
