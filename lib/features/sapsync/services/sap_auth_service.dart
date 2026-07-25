import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SapAuthService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _keyUserId = 'sap_user_id';
  static const String _keyPassword = 'sap_password';
  static const String _keyTermYear = 'sap_term_year';
  static const String _keySessionKey = 'sap_session_key';
  static const String _keyThreshold = 'sap_threshold';

  Future<void> saveCredentials(String userId, String password) async {
    await _secureStorage.write(key: _keyUserId, value: userId);
    await _secureStorage.write(key: _keyPassword, value: password);
  }

  Future<void> saveSessionInfo(String termYear, String sessionKey) async {
    await _secureStorage.write(key: _keyTermYear, value: termYear);
    await _secureStorage.write(key: _keySessionKey, value: sessionKey);
  }

  Future<Map<String, String>?> getSessionInfo() async {
    final termYear = await _secureStorage.read(key: _keyTermYear);
    final sessionKey = await _secureStorage.read(key: _keySessionKey);
    if (termYear != null && sessionKey != null) {
      return {'termYear': termYear, 'sessionKey': sessionKey};
    }
    return null;
  }

  Future<void> saveThreshold(double threshold) async {
    await _secureStorage.write(key: _keyThreshold, value: threshold.toString());
  }

  Future<double> getThreshold() async {
    final val = await _secureStorage.read(key: _keyThreshold);
    if (val != null) {
      return double.tryParse(val) ?? 75.0;
    }
    return 75.0;
  }

  Future<bool> hasCredentials() async {
    final userId = await _secureStorage.read(key: _keyUserId);
    final password = await _secureStorage.read(key: _keyPassword);
    return userId != null && userId.isNotEmpty && password != null && password.isNotEmpty;
  }

  Future<Map<String, String>?> getCredentials() async {
    final userId = await _secureStorage.read(key: _keyUserId);
    final password = await _secureStorage.read(key: _keyPassword);

    if (userId != null && password != null) {
      return {'userId': userId, 'password': password};
    }
    return null;
  }

  Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _keyUserId);
    await _secureStorage.delete(key: _keyPassword);
    await _secureStorage.delete(key: _keyTermYear);
    await _secureStorage.delete(key: _keySessionKey);
    await _secureStorage.delete(key: _keyThreshold);
  }
}
