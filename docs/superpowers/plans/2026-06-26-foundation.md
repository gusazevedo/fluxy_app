# Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up Fluxy's architectural skeleton — a running dark-themed Flutter app with a typed networking layer (dio + automatic JWT refresh), a `Money` value type, a sealed error model, secure token storage, theme tokens, and an auth-guarded `go_router` bottom-nav shell with placeholder screens.

**Architecture:** Layered `presentation → domain → data`; Riverpod for DI/state; dio for HTTP; go_router for navigation. This plan builds only the cross-cutting `core/` + `app/` infrastructure — feature screens arrive in later plans (design system, then auth, etc.). Source specs: `spec/00-architecture-and-conventions.md`, `spec/01-design-system.md` (tokens only).

**Tech Stack:** Flutter (Dart `^3.12.1`), `flutter_riverpod` + `riverpod_annotation`, `dio`, `go_router`, `freezed`, `flutter_secure_storage`, `intl`, `google_fonts`; dev: `build_runner`, `riverpod_generator`, `freezed`, `json_serializable`, `mocktail`.

## Global Constraints

- Dart SDK floor: `^3.12.1`.
- Money is **integer cents**, never `double`. Display `R$ 3.240,00` via `NumberFormat.currency(locale: 'pt_BR', symbol: r'R$')`.
- Currency `BRL`, locale `pt_BR`. All user-facing copy is **pt-BR**.
- Theme is **dark-only**. Fonts: **Oswald** (UI) + **Fjalla One** (money amounts).
- API base URL default: `https://3rgdjd69sa.execute-api.us-east-1.amazonaws.com`, overridable via `--dart-define=FLUXY_BASE_URL=...`.
- Only `data/*_api` touches `dio`; only repositories touch `*_api`; UI never imports dio. Repositories **throw `Failure`**; controllers expose `AsyncValue`.
- `/auth/*` (except `change-password`) are public — no token attach, no refresh. `/auth/refresh` rotates **both** tokens.
- TDD: failing test first. Commit after each green task.

## Color/token reference (from `spec/01-design-system.md`, used in Task 7)

`bgScreen #0F1115` · `surface #181B21` · `surfaceRaised #1C2027` · `sheet #15181E` · `border #272B33` · `primary #3FD68C` · `primaryPressed #239D61` · `onPrimary #07120C` · `expense #F0635A` · `textPrimary #E8EAED` · `textMuted #8B919B` · `textHint #6B7079`.

---

## File Structure (this plan)

- Create `lib/core/config/env.dart` — `AppConfig` (base URL, currency, locale from dart-defines).
- Create `lib/core/money/money.dart` — `Money` value type + BRL formatting.
- Create `lib/core/time/api_date.dart` — `YYYY-MM-DD` ⇄ `DateTime`, pt-BR display.
- Create `lib/core/error/failure.dart` — sealed `Failure`.
- Create `lib/core/network/api_exception.dart` — `DioException`/response → `Failure`.
- Create `lib/core/storage/token_storage.dart` — `TokenStorage` interface + secure impl.
- Create `lib/core/network/dio_client.dart` — configured `Dio` factory + providers.
- Create `lib/core/network/auth_interceptor.dart` — attach token + single-flight 401 refresh.
- Create `lib/core/theme/tokens.dart` — `AppColors`, `AppRadii`, `AppSpacing`.
- Create `lib/core/theme/app_theme.dart` — `buildDarkTheme()` + `AppText` styles.
- Create `lib/core/session/session_status.dart` — minimal `SessionStatus` + `sessionStatusProvider` (foundation stub; spec 02 replaces with real auth).
- Create `lib/app/router.dart` — `GoRouter` + redirect.
- Create `lib/app/shell.dart` — bottom-nav scaffold + FAB.
- Create `lib/app/placeholder_screens.dart` — login + 4 tab placeholders.
- Create `lib/app/app.dart` — `FluxyApp` (`MaterialApp.router`).
- Rewrite `lib/main.dart` — `runApp(ProviderScope(child: FluxyApp()))`.
- Tests under `test/core/...` and `test/app/...`.

---

## Task 1: Project setup — dependencies, fonts, AppConfig

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/config/env.dart`
- Test: `test/core/config/env_test.dart`

**Interfaces:**
- Produces: `AppConfig { static String get baseUrl; static String get currencyCode; static String get locale; }`

- [ ] **Step 1: Add dependencies**

Run:
```bash
cd /Users/gustavo/www/native/fluxy_app
flutter pub add flutter_riverpod riverpod_annotation dio go_router freezed_annotation json_annotation flutter_secure_storage intl google_fonts
flutter pub add dev:build_runner dev:riverpod_generator dev:freezed dev:json_serializable dev:mocktail
```
Expected: `pubspec.yaml` updated, `flutter pub get` succeeds.

- [ ] **Step 2: Write the failing test**

```dart
// test/core/config/env_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/config/env.dart';

void main() {
  test('AppConfig exposes BRL/pt_BR defaults and the AWS base URL', () {
    expect(AppConfig.currencyCode, 'BRL');
    expect(AppConfig.locale, 'pt_BR');
    expect(AppConfig.baseUrl,
        'https://3rgdjd69sa.execute-api.us-east-1.amazonaws.com');
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/core/config/env_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '.../env.dart'`.

- [ ] **Step 4: Implement AppConfig**

```dart
// lib/core/config/env.dart
class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'FLUXY_BASE_URL',
    defaultValue: 'https://3rgdjd69sa.execute-api.us-east-1.amazonaws.com',
  );
  static const String currencyCode =
      String.fromEnvironment('FLUXY_CURRENCY', defaultValue: 'BRL');
  static const String locale =
      String.fromEnvironment('FLUXY_LOCALE', defaultValue: 'pt_BR');
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/core/config/env_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/config/env.dart test/core/config/env_test.dart
git commit -m "chore: add dependencies and AppConfig"
```

---

## Task 2: Money value type

**Files:**
- Create: `lib/core/money/money.dart`
- Test: `test/core/money/money_test.dart`

**Interfaces:**
- Produces: `Money { final int cents; const Money(this.cents); factory Money.fromMajor(num major); double get major; bool get isNegative; String format(); String formatSigned(bool isExpense); }`

- [ ] **Step 1: Write the failing test**

```dart
// test/core/money/money_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/money/money.dart';

void main() {
  test('fromMajor rounds to integer cents', () {
    expect(Money.fromMajor(32.405).cents, 3241);
    expect(Money.fromMajor(3240).cents, 324000);
  });

  test('format renders BRL pt-BR', () {
    expect(Money(324000).format(), 'R\$ 3.240,00');
    expect(Money(34000).format(), 'R\$ 340,00');
  });

  test('formatSigned applies + for income and - for expense', () {
    expect(Money(510000).formatSigned(false), '+R\$ 5.100,00');
    expect(Money(120000).formatSigned(true), '-R\$ 1.200,00');
  });

  test('isNegative reflects sign', () {
    expect(Money(-100).isNegative, true);
    expect(Money(100).isNegative, false);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/money/money_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement Money**

```dart
// lib/core/money/money.dart
import 'package:intl/intl.dart';
import '../config/env.dart';

class Money {
  final int cents;
  const Money(this.cents);

  factory Money.fromMajor(num major) => Money((major * 100).round());

  double get major => cents / 100;
  bool get isNegative => cents < 0;

  static final NumberFormat _fmt = NumberFormat.currency(
    locale: AppConfig.locale,
    symbol: r'R$',
    decimalDigits: 2,
  );

  /// Absolute, symbol-prefixed: `R$ 3.240,00`.
  String format() => _fmt.format(major.abs());

  /// `+R$ 5.100,00` (income) or `-R$ 1.200,00` (expense).
  String formatSigned(bool isExpense) => '${isExpense ? '-' : '+'}${format()}';

  @override
  bool operator ==(Object other) => other is Money && other.cents == cents;
  @override
  int get hashCode => cents.hashCode;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/money/money_test.dart`
Expected: PASS. (`NumberFormat.currency` for `pt_BR` needs no extra init.)

- [ ] **Step 5: Commit**

```bash
git add lib/core/money/money.dart test/core/money/money_test.dart
git commit -m "feat: add Money value type with BRL formatting"
```

---

## Task 3: Sealed Failure + ApiException mapping

**Files:**
- Create: `lib/core/error/failure.dart`
- Create: `lib/core/network/api_exception.dart`
- Test: `test/core/network/api_exception_test.dart`

**Interfaces:**
- Produces: `sealed class Failure { final String message; }` with subtypes `NetworkFailure, UnauthorizedFailure, ForbiddenFailure, NotFoundFailure, ValidationFailure, ConflictFailure, ServerFailure, UnknownFailure`.
- Produces: `Failure failureFromDio(DioException e)`.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/network/api_exception_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/core/network/api_exception.dart';

DioException _http(int status, {dynamic body}) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      response: Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: status,
        data: body,
      ),
      type: DioExceptionType.badResponse,
    );

void main() {
  test('timeout -> NetworkFailure', () {
    final f = failureFromDio(DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.connectionTimeout,
    ));
    expect(f, isA<NetworkFailure>());
  });

  test('401 -> UnauthorizedFailure', () {
    expect(failureFromDio(_http(401)), isA<UnauthorizedFailure>());
  });

  test('422 -> ValidationFailure with extracted message', () {
    final f = failureFromDio(_http(422, body: {'message': 'E-mail inválido'}));
    expect(f, isA<ValidationFailure>());
    expect(f.message, 'E-mail inválido');
  });

  test('500 -> ServerFailure', () {
    expect(failureFromDio(_http(500)), isA<ServerFailure>());
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/network/api_exception_test.dart`
Expected: FAIL — files do not exist.

- [ ] **Step 3: Implement Failure**

```dart
// lib/core/error/failure.dart
sealed class Failure {
  final String message;
  final Map<String, List<String>> fields;
  const Failure(this.message, {this.fields = const {}});
}

class NetworkFailure extends Failure {
  const NetworkFailure([String m = 'Sem conexão. Verifique sua internet.']) : super(m);
}
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([String m = 'Sua sessão expirou.']) : super(m);
}
class ForbiddenFailure extends Failure {
  const ForbiddenFailure([String m = 'Acesso negado.']) : super(m);
}
class NotFoundFailure extends Failure {
  const NotFoundFailure([String m = 'Não encontrado.']) : super(m);
}
class ValidationFailure extends Failure {
  const ValidationFailure(String m, {Map<String, List<String>> fields = const {}})
      : super(m, fields: fields);
}
class ConflictFailure extends Failure {
  const ConflictFailure([String m = 'Conflito.']) : super(m);
}
class ServerFailure extends Failure {
  const ServerFailure([String m = 'Algo deu errado. Tente novamente.']) : super(m);
}
class UnknownFailure extends Failure {
  const UnknownFailure([String m = 'Erro inesperado.']) : super(m);
}
```

- [ ] **Step 4: Implement the mapping**

```dart
// lib/core/network/api_exception.dart
import 'package:dio/dio.dart';
import '../error/failure.dart';

String _extractMessage(dynamic body, String fallback) {
  if (body is Map) {
    for (final k in ['message', 'error', 'detail']) {
      final v = body[k];
      if (v is String && v.isNotEmpty) return v;
    }
  }
  return fallback;
}

Map<String, List<String>> _extractFields(dynamic body) {
  if (body is Map && body['errors'] is Map) {
    return (body['errors'] as Map).map((k, v) => MapEntry(
          k.toString(),
          (v is List) ? v.map((e) => e.toString()).toList() : [v.toString()],
        ));
  }
  return const {};
}

Failure failureFromDio(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    default:
      break;
  }
  final status = e.response?.statusCode;
  final body = e.response?.data;
  switch (status) {
    case 400:
    case 422:
      return ValidationFailure(_extractMessage(body, 'Dados inválidos.'),
          fields: _extractFields(body));
    case 401:
      return UnauthorizedFailure(_extractMessage(body, 'Sua sessão expirou.'));
    case 403:
      return ForbiddenFailure(_extractMessage(body, 'Acesso negado.'));
    case 404:
      return NotFoundFailure(_extractMessage(body, 'Não encontrado.'));
    case 409:
      return ConflictFailure(_extractMessage(body, 'Conflito.'));
    default:
      if (status != null && status >= 500) {
        return ServerFailure(_extractMessage(body, 'Algo deu errado. Tente novamente.'));
      }
      return UnknownFailure(_extractMessage(body, 'Erro inesperado.'));
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/core/network/api_exception_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/error/failure.dart lib/core/network/api_exception.dart test/core/network/api_exception_test.dart
git commit -m "feat: add sealed Failure model and dio error mapping"
```

---

## Task 4: ApiDate helpers

**Files:**
- Create: `lib/core/time/api_date.dart`
- Test: `test/core/time/api_date_test.dart`

**Interfaces:**
- Produces: `String apiDateToString(DateTime d);` (→ `YYYY-MM-DD`), `DateTime parseApiDate(String s);`, `bool isFuture(DateTime d);`

- [ ] **Step 1: Write the failing test**

```dart
// test/core/time/api_date_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/time/api_date.dart';

void main() {
  test('formats to YYYY-MM-DD zero-padded', () {
    expect(apiDateToString(DateTime(2026, 6, 5)), '2026-06-05');
  });
  test('parses YYYY-MM-DD', () {
    final d = parseApiDate('2026-06-21');
    expect([d.year, d.month, d.day], [2026, 6, 21]);
  });
  test('isFuture true only after today', () {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    expect(isFuture(tomorrow), true);
    expect(isFuture(DateTime.now()), false);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/time/api_date_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement**

```dart
// lib/core/time/api_date.dart
String _2(int n) => n.toString().padLeft(2, '0');

String apiDateToString(DateTime d) => '${d.year}-${_2(d.month)}-${_2(d.day)}';

DateTime parseApiDate(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

bool isFuture(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  return day.isAfter(today);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/time/api_date_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/time/api_date.dart test/core/time/api_date_test.dart
git commit -m "feat: add API date helpers"
```

---

## Task 5: TokenStorage

**Files:**
- Create: `lib/core/storage/token_storage.dart`
- Test: `test/core/storage/token_storage_test.dart`

**Interfaces:**
- Produces: `abstract class TokenStorage { Future<void> save({required String access, required String refresh}); Future<String?> readAccess(); Future<String?> readRefresh(); Future<void> clear(); }`
- Produces: `class SecureTokenStorage implements TokenStorage` (backed by `FlutterSecureStorage`), and `tokenStorageProvider`.

- [ ] **Step 1: Write the failing test (in-memory fake implements the same interface)**

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/storage/token_storage_test.dart`
Expected: FAIL — `TokenStorage` not defined.

- [ ] **Step 3: Implement**

```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/storage/token_storage_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/storage/token_storage.dart test/core/storage/token_storage_test.dart
git commit -m "feat: add secure TokenStorage"
```

---

## Task 6: Dio client + AuthInterceptor (single-flight 401 refresh)

**Files:**
- Create: `lib/core/network/dio_client.dart`
- Create: `lib/core/network/auth_interceptor.dart`
- Test: `test/core/network/auth_interceptor_test.dart`

**Interfaces:**
- Consumes: `TokenStorage` (Task 5), `AppConfig` (Task 1).
- Produces: `AuthInterceptor(TokenStorage storage, {required Future<bool> Function() onRefresh, required void Function() onSessionExpired})`.
- Produces: `Dio buildDio(TokenStorage storage, AuthInterceptor interceptor);`, `dioProvider`.

> The refresh CALL itself lives in the auth feature (later plan). The interceptor takes an injected `onRefresh` callback returning success, so the foundation stays decoupled. For now `dioProvider` wires `onRefresh: () async => false` (no auth feature yet); spec 02 replaces it.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/network/auth_interceptor_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/network/auth_interceptor.dart';
import 'package:fluxy_app/core/storage/token_storage.dart';

class _Mem implements TokenStorage {
  String? a = 'access-1', r = 'refresh-1';
  @override Future<void> save({required String access, required String refresh}) async { a = access; r = refresh; }
  @override Future<String?> readAccess() async => a;
  @override Future<String?> readRefresh() async => r;
  @override Future<void> clear() async { a = null; r = null; }
}

void main() {
  test('onRequest attaches bearer token for non-auth routes', () async {
    final i = AuthInterceptor(_Mem(), onRefresh: () async => false, onSessionExpired: () {});
    final opts = RequestOptions(path: '/transactions');
    final handler = RequestInterceptorHandler();
    await i.onRequest(opts, handler);
    expect(opts.headers['Authorization'], 'Bearer access-1');
  });

  test('onRequest does NOT attach token for public /auth/login', () async {
    final i = AuthInterceptor(_Mem(), onRefresh: () async => false, onSessionExpired: () {});
    final opts = RequestOptions(path: '/auth/login');
    await i.onRequest(opts, RequestInterceptorHandler());
    expect(opts.headers.containsKey('Authorization'), false);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/network/auth_interceptor_test.dart`
Expected: FAIL — `AuthInterceptor` not defined.

- [ ] **Step 3: Implement the interceptor**

```dart
// lib/core/network/auth_interceptor.dart
import 'dart:async';
import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

bool _isPublicAuthRoute(String path) {
  // /auth/* are public EXCEPT change-password.
  if (!path.contains('/auth/')) return false;
  return !path.contains('/auth/change-password');
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._storage, {
    required Future<bool> Function() onRefresh,
    required void Function() onSessionExpired,
  })  : _onRefresh = onRefresh,
        _onSessionExpired = onSessionExpired;

  final TokenStorage _storage;
  final Future<bool> Function() _onRefresh;
  final void Function() _onSessionExpired;

  // Single-flight: concurrent 401s await one refresh.
  Future<bool>? _refreshing;

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_isPublicAuthRoute(options.path)) {
      final token = await _storage.readAccess();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final is401 = err.response?.statusCode == 401;
    final isAuthRoute = _isPublicAuthRoute(err.requestOptions.path);
    final alreadyRetried = err.requestOptions.extra['__retried'] == true;

    if (!is401 || isAuthRoute || alreadyRetried) {
      return handler.next(err);
    }

    final ok = await (_refreshing ??= _onRefresh().whenComplete(() {
      _refreshing = null;
    }));

    if (!ok) {
      _onSessionExpired();
      return handler.next(err);
    }

    // Retry the original request once with the new token.
    final token = await _storage.readAccess();
    final opts = err.requestOptions
      ..extra['__retried'] = true
      ..headers['Authorization'] = 'Bearer $token';
    try {
      final dio = Dio(BaseOptions(baseUrl: opts.baseUrl));
      final res = await dio.fetch(opts);
      return handler.resolve(res);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}
```

- [ ] **Step 4: Implement the dio factory**

```dart
// lib/core/network/dio_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

Dio buildDio(TokenStorage storage, AuthInterceptor interceptor) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    contentType: 'application/json',
    headers: {'Accept': 'application/json'},
  ));
  dio.interceptors.add(interceptor);
  return dio;
}

/// Foundation wiring: real /auth/refresh is injected by the auth feature (spec 02).
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final interceptor = AuthInterceptor(
    storage,
    onRefresh: () async => false, // replaced in spec 02
    onSessionExpired: () {},       // replaced in spec 02
  );
  return buildDio(storage, interceptor);
});
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/core/network/auth_interceptor_test.dart`
Expected: PASS (both cases).

- [ ] **Step 6: Commit**

```bash
git add lib/core/network/dio_client.dart lib/core/network/auth_interceptor.dart test/core/network/auth_interceptor_test.dart
git commit -m "feat: add dio client and auth interceptor with single-flight refresh"
```

---

## Task 7: Theme tokens + dark ThemeData + AppText

**Files:**
- Create: `lib/core/theme/tokens.dart`
- Create: `lib/core/theme/app_theme.dart`
- Test: `test/core/theme/app_theme_test.dart`

**Interfaces:**
- Produces: `AppColors` (static `Color` consts), `AppRadii`, `AppSpacing`.
- Produces: `ThemeData buildDarkTheme();`, `class AppText { static TextStyle get titleScreen; get displayAmount; get body; get label; ... }`.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/theme/app_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/theme/app_theme.dart';
import 'package:fluxy_app/core/theme/tokens.dart';

void main() {
  test('dark theme uses brand tokens', () {
    final t = buildDarkTheme();
    expect(t.brightness, Brightness.dark);
    expect(t.colorScheme.primary, AppColors.primary);
    expect(t.scaffoldBackgroundColor, AppColors.bgScreen);
  });

  test('AppColors expose exact design hex values', () {
    expect(AppColors.primary, const Color(0xFF3FD68C));
    expect(AppColors.expense, const Color(0xFFF0635A));
    expect(AppColors.surface, const Color(0xFF181B21));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/theme/app_theme_test.dart`
Expected: FAIL — files do not exist.

- [ ] **Step 3: Implement tokens**

```dart
// lib/core/theme/tokens.dart
import 'package:flutter/material.dart';

class AppColors {
  static const bgScreen = Color(0xFF0F1115);
  static const surface = Color(0xFF181B21);
  static const surfaceRaised = Color(0xFF1C2027);
  static const sheet = Color(0xFF15181E);
  static const border = Color(0xFF272B33);
  static const timelineLine = Color(0xFF2E2E2E);
  static const nodeFill = Color(0xFF1F1F1F);
  static const primary = Color(0xFF3FD68C);
  static const primaryPressed = Color(0xFF239D61);
  static const onPrimary = Color(0xFF07120C);
  static const expense = Color(0xFFF0635A);
  static const onExpense = Color(0xFF1A0605);
  static const textPrimary = Color(0xFFE8EAED);
  static const textMuted = Color(0xFF8B919B);
  static const textHint = Color(0xFF6B7079);
}

class AppRadii {
  static const input = 13.0;
  static const card = 20.0;
  static const button = 16.0;
  static const sheet = 28.0;
  static const fab = 20.0;
}

class AppSpacing {
  static const screenH = 28.0;
  static const homeH = 22.0;
  static const md = 16.0;
  static const lg = 24.0;
}
```

- [ ] **Step 4: Implement theme + AppText**

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

class AppText {
  static TextStyle get displayAmount => GoogleFonts.fjallaOne(
      fontSize: 34, color: AppColors.primary, letterSpacing: -1);
  static TextStyle get amountMd =>
      GoogleFonts.fjallaOne(fontSize: 18, letterSpacing: -0.3);
  static TextStyle get amountSm => GoogleFonts.fjallaOne(fontSize: 15);
  static TextStyle get titleScreen => GoogleFonts.oswald(
      fontSize: 28, fontWeight: FontWeight.w700,
      color: AppColors.textPrimary, letterSpacing: -0.6);
  static TextStyle get titleSection => GoogleFonts.oswald(
      fontSize: 20, fontWeight: FontWeight.w700,
      color: AppColors.textPrimary, letterSpacing: -0.4);
  static TextStyle get titleList => GoogleFonts.oswald(
      fontSize: 16, fontWeight: FontWeight.w700,
      color: AppColors.textPrimary, letterSpacing: -0.3);
  static TextStyle get dateAnchor => GoogleFonts.oswald(
      fontSize: 14, fontWeight: FontWeight.w700,
      color: AppColors.textPrimary, letterSpacing: 0.3);
  static TextStyle get body =>
      GoogleFonts.oswald(fontSize: 15, color: AppColors.textMuted);
  static TextStyle get bodyStrong => GoogleFonts.oswald(
      fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static TextStyle get label =>
      GoogleFonts.oswald(fontSize: 13, color: AppColors.textMuted);
  static TextStyle get caption =>
      GoogleFonts.oswald(fontSize: 12.5, color: AppColors.textMuted);
  static TextStyle get hint =>
      GoogleFonts.oswald(fontSize: 11.5, color: AppColors.textHint);
}

ThemeData buildDarkTheme() {
  final scheme = const ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    surface: AppColors.surface,
    error: AppColors.expense,
  ).copyWith(surfaceTint: Colors.transparent);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bgScreen,
    textTheme: GoogleFonts.oswaldTextTheme(ThemeData.dark().textTheme)
        .apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary),
  );
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/core/theme/app_theme_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/theme/tokens.dart lib/core/theme/app_theme.dart test/core/theme/app_theme_test.dart
git commit -m "feat: add design tokens and dark theme"
```

---

## Task 8: Session stub + router + shell + placeholders

**Files:**
- Create: `lib/core/session/session_status.dart`
- Create: `lib/app/placeholder_screens.dart`
- Create: `lib/app/shell.dart`
- Create: `lib/app/router.dart`
- Test: `test/app/router_test.dart`

**Interfaces:**
- Consumes: `AppColors`/`AppText` (Task 7).
- Produces: `enum SessionStatus { unknown, unauthenticated, unverified, authenticated }`, `sessionStatusProvider` (StateProvider, default `unauthenticated`).
- Produces: `GoRouter buildRouter(Ref ref);`, `routerProvider`.

> The redirect logic is the deliverable here; spec 02 swaps `sessionStatusProvider` for the real auth controller without changing the router.

- [ ] **Step 1: Write the failing test**

```dart
// test/app/router_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/app/router.dart';
import 'package:fluxy_app/core/session/session_status.dart';

void main() {
  testWidgets('unauthenticated lands on /login', (tester) async {
    final container = ProviderContainer(overrides: [
      sessionStatusProvider.overrideWith((ref) => SessionStatus.unauthenticated),
    ]);
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
  });

  testWidgets('authenticated lands on / (Início)', (tester) async {
    final container = ProviderContainer(overrides: [
      sessionStatusProvider.overrideWith((ref) => SessionStatus.authenticated),
    ]);
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/app/router_test.dart`
Expected: FAIL — files do not exist.

- [ ] **Step 3: Implement the session stub**

```dart
// lib/core/session/session_status.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SessionStatus { unknown, unauthenticated, unverified, authenticated }

/// Foundation stub — replaced by the real auth controller in spec 02.
final sessionStatusProvider =
    StateProvider<SessionStatus>((ref) => SessionStatus.unauthenticated);
```

- [ ] **Step 4: Implement placeholder screens**

```dart
// lib/app/placeholder_screens.dart
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) =>
      Center(child: Text(title, style: AppText.titleScreen));
}

class LoginPlaceholder extends StatelessWidget {
  const LoginPlaceholder({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: PlaceholderScreen('Login (spec 02)'));
}
```

- [ ] **Step 5: Implement the shell**

```dart
// lib/app/shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/tokens.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  static const _tabs = ['/', '/transactions', '/categories', '/account'];

  int _indexFor(String location) {
    final i = _tabs.indexWhere((t) => t == '/' ? location == '/' : location.startsWith(t));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return Scaffold(
      body: child,
      floatingActionButton: (location == '/' || location.startsWith('/transactions'))
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () {/* Nova transação sheet — spec 04 */},
              child: const Icon(Icons.add, color: AppColors.onPrimary),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexFor(location),
        onDestinationSelected: (i) => context.go(_tabs[i]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.swap_vert), label: 'Transações'),
          NavigationDestination(icon: Icon(Icons.category_outlined), label: 'Categorias'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Conta'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Implement the router**

```dart
// lib/app/router.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/session/session_status.dart';
import 'placeholder_screens.dart';
import 'shell.dart';

const _publicRoutes = {
  '/login', '/register', '/forgot-password', '/reset-password', '/verify-email',
};

GoRouter buildRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final status = ref.read(sessionStatusProvider);
      final path = state.uri.path;
      final isPublic = _publicRoutes.contains(path);
      switch (status) {
        case SessionStatus.unknown:
          return null;
        case SessionStatus.unauthenticated:
          return isPublic ? null : '/login';
        case SessionStatus.unverified:
          return path == '/verify-email' ? null : '/verify-email';
        case SessionStatus.authenticated:
          return isPublic ? '/' : null;
      }
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPlaceholder()),
      GoRoute(path: '/register', builder: (_, __) => const Scaffold(body: PlaceholderScreen('Cadastro'))),
      GoRoute(path: '/forgot-password', builder: (_, __) => const Scaffold(body: PlaceholderScreen('Recuperar senha'))),
      GoRoute(path: '/reset-password', builder: (_, __) => const Scaffold(body: PlaceholderScreen('Nova senha'))),
      GoRoute(path: '/verify-email', builder: (_, __) => const Scaffold(body: PlaceholderScreen('Verificar e-mail'))),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const PlaceholderScreen('Início')),
          GoRoute(path: '/transactions', builder: (_, __) => const PlaceholderScreen('Transações')),
          GoRoute(path: '/categories', builder: (_, __) => const PlaceholderScreen('Categorias')),
          GoRoute(path: '/account', builder: (_, __) => const PlaceholderScreen('Conta')),
        ],
      ),
    ],
  );
}

final routerProvider = Provider<GoRouter>((ref) => buildRouter(ref));
```

- [ ] **Step 7: Run test to verify it passes**

Run: `flutter test test/app/router_test.dart`
Expected: PASS (both cases).

- [ ] **Step 8: Commit**

```bash
git add lib/core/session/session_status.dart lib/app/placeholder_screens.dart lib/app/shell.dart lib/app/router.dart test/app/router_test.dart
git commit -m "feat: add session stub, auth-guarded router and bottom-nav shell"
```

---

## Task 9: App bootstrap — wire MaterialApp.router and run

**Files:**
- Create: `lib/app/app.dart`
- Modify: `lib/main.dart` (replace the counter demo)
- Modify: `test/widget_test.dart` (replace the default counter test)
- Test: `test/app/app_smoke_test.dart`

**Interfaces:**
- Consumes: `routerProvider` (Task 8), `buildDarkTheme()` (Task 7).
- Produces: `class FluxyApp extends ConsumerWidget`.

- [ ] **Step 1: Write the failing smoke test**

```dart
// test/app/app_smoke_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/app/app.dart';

void main() {
  testWidgets('FluxyApp boots into the login placeholder (unauthenticated)', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FluxyApp()));
    await tester.pumpAndSettle();
    expect(find.text('Login (spec 02)'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/app/app_smoke_test.dart`
Expected: FAIL — `app.dart` does not exist.

- [ ] **Step 3: Implement FluxyApp**

```dart
// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class FluxyApp extends ConsumerWidget {
  const FluxyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Fluxy',
      debugShowCheckedModeBanner: false,
      theme: buildDarkTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.dark,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
```

- [ ] **Step 4: Replace main.dart**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';

void main() {
  runApp(const ProviderScope(child: FluxyApp()));
}
```

- [ ] **Step 5: Replace the default counter widget test**

```dart
// test/widget_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/app/app.dart';

void main() {
  testWidgets('app renders without throwing', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FluxyApp()));
    await tester.pumpAndSettle();
  });
}
```

- [ ] **Step 6: Run the full suite + analyzer**

Run: `flutter test && flutter analyze`
Expected: all tests PASS; analyzer reports **No issues found**.

- [ ] **Step 7: Run the app (manual smoke)**

Run: `flutter run` (or `flutter run -d <device>`)
Expected: dark login placeholder appears (not the counter demo). Temporarily set `sessionStatusProvider` default to `authenticated` to verify the bottom-nav shell renders the four tabs, then revert.

- [ ] **Step 8: Commit**

```bash
git add lib/app/app.dart lib/main.dart test/app/app_smoke_test.dart test/widget_test.dart
git commit -m "feat: wire FluxyApp bootstrap with dark theme and router"
```

---

## Self-Review

**Spec coverage (`spec/00`):** §2 deps → T1; §3 structure → T1–T9 (folders created as files land); §4 Money → T2; §5 Failure → T3; §6 networking/auth → T6; §7 routing/shell → T8; §8 theming → T7; §9 localization (BRL/pt-BR) → T2 (money) + AppConfig T1; §10 testing → every task is TDD; §11 config → T1; §12 acceptance → T2 (Money fmt), T3 (Failure mapping), T5 (TokenStorage), T8 (router redirect), T7 (dark theme), T9 (boots, analyzer clean). Design tokens (`spec/01` §1) → T7. **No gaps for the foundation milestone.** (Full design-system components, real auth/refresh, and feature screens are explicitly out of scope — next plans.)

**Placeholder scan:** no "TBD/TODO/implement later"; the `LoginPlaceholder`/`PlaceholderScreen` widgets are intentional, named stubs the next plans replace, each labeled with the owning spec.

**Type consistency:** `TokenStorage` interface (T5) is consumed unchanged by `AuthInterceptor` (T6) and `dioProvider`; `SessionStatus`/`sessionStatusProvider` (T8) consumed by `buildRouter` and overridden in tests; `AppColors`/`AppText`/`buildDarkTheme()` (T7) consumed by shell (T8) and app (T9); `failureFromDio` (T3) name reused consistently. `routerProvider` (T8) consumed by `FluxyApp` (T9).

---

## Notes for subsequent plans (not part of this plan)

- **Design System plan** builds the real `core/widgets/` components from `spec/01` (PrimaryButton 3D, AppTextField, TransactionTimeline, OtpCodeInput, SegmentedToggle, Fab, BottomSheetScaffold, async views) with widget/golden tests.
- **Auth plan (`spec/02`)** replaces `sessionStatusProvider` with the real `authControllerProvider`, and injects the real `/auth/refresh` + `onSessionExpired` into `dioProvider` (the interceptor's `onRefresh`/`onSessionExpired` seams already exist from T6).
