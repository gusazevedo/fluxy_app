// test/core/storage/token_storage_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/storage/token_storage.dart';

class FakeTokenStorage implements TokenStorage {
  String? _a, _r;
  @override
  Future<void> save({required String access, required String refresh}) async {
    _a = access; _r = refresh;
  }
  @override
  Future<String?> readAccess() async => _a;
  @override
  Future<String?> readRefresh() async => _r;
  @override
  Future<void> clear() async { _a = null; _r = null; }
}

void main() {
  test('save then read returns tokens; clear wipes them', () async {
    final TokenStorage s = FakeTokenStorage();
    await s.save(access: 'a1', refresh: 'r1');
    expect(await s.readAccess(), 'a1');
    expect(await s.readRefresh(), 'r1');
    await s.clear();
    expect(await s.readAccess(), isNull);
    expect(await s.readRefresh(), isNull);
  });
}
