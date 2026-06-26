// lib/core/storage/token_storage.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStorage {
  Future<void> save({required String access, required String refresh});
  Future<String?> readAccess();
  Future<String?> readRefresh();
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
      : _s = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _s;
  static const _kAccess = 'fluxy.access';
  static const _kRefresh = 'fluxy.refresh';

  @override
  Future<void> save({required String access, required String refresh}) async {
    await _s.write(key: _kAccess, value: access);
    await _s.write(key: _kRefresh, value: refresh);
  }
  @override
  Future<String?> readAccess() => _s.read(key: _kAccess);
  @override
  Future<String?> readRefresh() => _s.read(key: _kRefresh);
  @override
  Future<void> clear() async {
    await _s.delete(key: _kAccess);
    await _s.delete(key: _kRefresh);
  }
}

final tokenStorageProvider =
    Provider<TokenStorage>((ref) => SecureTokenStorage());
