# Authentication — Part 1: Engine & Session — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the non-visual auth **engine** — domain models, the data layer (`AuthApi` + `AuthRepository`), the `AuthController` that owns `AuthState`, and the wiring that connects all of it to the foundation seams (the dio refresh interceptor, the router redirect, cold-start session restore) — so the app boots, restores a persisted session, and gates navigation by real auth state.

**Architecture:** Layered `presentation → domain → data` inside `lib/features/auth/`; only `AuthApi` touches `dio`, only `AuthRepository` touches `TokenStorage` and maps `DioException → Failure`. The `AuthController` (a hand-written Riverpod v3 `Notifier`, matching the foundation's hand-written-provider style) holds `AuthState`. The two foundation seams that `core/` left as stubs (the `dioProvider` refresh/expiry callbacks and the `sessionStatusProvider`) are filled **at the app composition root** (`main.dart`) via `ProviderScope` overrides, so `core/` never imports `features/` and the dependency rule holds. This is **Part 1 of 2**; Part 2 builds the five pt-BR screens (Login/Cadastro/Verificar e-mail/Recuperar senha/Nova senha) on top of this engine.

**Tech Stack:** Flutter (Dart `^3.12.1`), `flutter_riverpod` v3, `dio`, `freezed` + `json_serializable` (codegen — **this feature establishes the codegen pipeline**), `go_router`, `flutter_secure_storage`, `mocktail` + `flutter_test`.

## Global Constraints

- **Pin a STABLE `freezed`** before first codegen: change `freezed: ^3.2.6-dev.1` → `freezed: ^3.2.5` (latest stable; the current pin is a pre-release *above* stable). All other codegen deps are already current (`freezed_annotation 3.1.0`, `json_serializable 6.14.0`).
- **Layering:** `presentation → domain → data`. Only `*_api.dart` imports `dio`; only `*_repository.dart` imports `TokenStorage`/`Failure` mapping. `core/` must NOT import `features/` — feature-specific wiring lives in `lib/main.dart` (the app composition root) or `lib/app/`.
- **Tokens only in `flutter_secure_storage`** (via the existing `TokenStorage`); never logged, never in prefs.
- **Errors:** repositories catch `DioException`, convert via `failureFromDio` (`lib/core/network/api_exception.dart`), and **throw `Failure`** (`lib/core/error/failure.dart`). No raw exception/JSON text surfaces. Friendly pt-BR messages where the spec names them.
- **Money:** N/A in this part (no amounts).
- **API base URL** is already configured on the shared `dio` (`AppConfig.baseUrl`). `/auth/*` except `/auth/change-password` are public (the interceptor already handles this).
- **OTP codes:** `verify-email` and `reset-password` send `{token: <code-as-string>}` (decided in spec 02 §3).
- Commit the generated `*.freezed.dart` / `*.g.dart` files (no codegen step runs in CI). TDD: failing test first, minimal code, green, commit per task.

## Existing foundation interfaces (consume these — do not re-implement)

- `lib/core/storage/token_storage.dart` — `abstract class TokenStorage { Future<void> save({required String access, required String refresh}); Future<String?> readAccess(); Future<String?> readRefresh(); Future<void> clear(); }` and `tokenStorageProvider`.
- `lib/core/network/dio_client.dart` — `Dio buildDio(TokenStorage, AuthInterceptor)` and `final dioProvider` (currently builds the interceptor with **stub** `onRefresh: () async => false` / `onSessionExpired: () {}` — Part 1 overrides this provider at the composition root).
- `lib/core/network/auth_interceptor.dart` — `AuthInterceptor(this._storage, {required this._onRefresh /* Future<bool> Function() */, required this._onSessionExpired /* void Function() */})`. Caller-facing arg names are `onRefresh` / `onSessionExpired`. Single-flight 401 refresh; `/auth/*` (except change-password) are public; a throwing `onRefresh` is caught → treated as failure → `onSessionExpired`.
- `lib/core/network/api_exception.dart` — `Failure failureFromDio(DioException e)`.
- `lib/core/error/failure.dart` — `sealed class Failure { String message; Map<String,List<String>> fields; }` with `NetworkFailure`, `UnauthorizedFailure`, `ValidationFailure`, `ConflictFailure`, `ServerFailure`, `UnknownFailure`, etc.
- `lib/core/session/session_status.dart` — `enum SessionStatus { unknown, unauthenticated, unverified, authenticated }` and `final sessionStatusProvider` (a stub `Provider<SessionStatus>` returning `unauthenticated`). **Leave this file unchanged**; Part 1 overrides the provider at the composition root.
- `lib/app/router.dart` — `GoRouter buildRouter(Ref ref)` (reads `sessionStatusProvider`, redirects by status; public routes `/login /register /forgot-password /reset-password /verify-email`) and `final routerProvider`.
- `lib/core/config/env.dart` — `AppConfig.baseUrl`.

## API surface used (spec 02 §2)

| Method/Path | Body | Success |
|---|---|---|
| `POST /auth/register` | `{email, firstName, lastName, password}` | `201 {message}` |
| `POST /auth/verify-email` | `{token}` (OTP code) | `200 {message}` |
| `POST /auth/verify-email/resend` | `{email}` | `200 {message}` |
| `POST /auth/login` | `{email, password}` | `200 {accessToken, refreshToken, tokenType, expiresIn}` |
| `POST /auth/refresh` | `{refreshToken}` | `200 {…rotated tokens…}` |
| `POST /auth/logout` | `{refreshToken}` | `200 {message}` |
| `POST /auth/forgot-password` | `{email}` | `200 {message}` (always 200) |
| `POST /auth/reset-password` | `{token, password}` (OTP code) | `200 {message}` |
| `GET /me` | — (auth) | `200 {id, email, firstName, lastName, emailVerified, createdAt}` |

> `expiresIn` is documented as a **string** — parse defensively (accept string or number).

---

## File Structure (this plan)

- Modify: `pubspec.yaml` (pin `freezed: ^3.2.5`), `pubspec.lock`.
- Create `lib/features/auth/domain/`: `auth_tokens.dart` (+ generated), `auth_user.dart` (+ generated), `auth_state.dart` (+ generated), `register_input.dart`.
- Create `lib/features/auth/data/`: `auth_api.dart`, `auth_repository.dart`.
- Create `lib/features/auth/presentation/`: `auth_controller.dart` (the `AuthController` notifier + `authControllerProvider` + `sessionStatusFromAuth` mapper).
- Modify `lib/app/router.dart` (add `/splash` route, splash redirect for `unknown`, `refreshListenable`).
- Modify `lib/main.dart` (compose real `dioProvider` + `sessionStatusProvider` via `ProviderScope` overrides; add a `SplashScreen`).
- Tests under `test/features/auth/` and `test/app/`.

---

## Task 1: Codegen pipeline + domain models

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/features/auth/domain/auth_tokens.dart`, `lib/features/auth/domain/auth_user.dart`, `lib/features/auth/domain/auth_state.dart`, `lib/features/auth/domain/register_input.dart` (+ generated `*.freezed.dart` / `*.g.dart`)
- Test: `test/features/auth/domain/auth_models_test.dart`

**Interfaces:**
- Produces: `AuthTokens({required String accessToken, required String refreshToken, @Default('Bearer') String tokenType, String? expiresIn})` + `AuthTokens.fromJson`.
- Produces: `AuthUser({required String id, required String email, required String firstName, required String lastName, required bool emailVerified, required DateTime createdAt})` + `AuthUser.fromJson`.
- Produces: `sealed AuthState` with `AuthState.unknown()` → `AuthUnknown`, `AuthState.unauthenticated()` → `AuthUnauthenticated`, `AuthState.authenticated(AuthUser user)` → `AuthAuthenticated`.
- Produces: `RegisterInput({required String email, required String firstName, required String lastName, required String password})` (plain class, no codegen).

- [ ] **Step 1: Pin stable freezed**

In `pubspec.yaml` (dev_dependencies), change:
```yaml
  freezed: ^3.2.6-dev.1
```
to:
```yaml
  freezed: ^3.2.5
```
Run: `flutter pub get`
Expected: resolves without error; `freezed 3.2.5` in `pubspec.lock`.

- [ ] **Step 2: Write the failing test**

```dart
// test/features/auth/domain/auth_models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/features/auth/domain/auth_state.dart';
import 'package:fluxy_app/features/auth/domain/auth_tokens.dart';
import 'package:fluxy_app/features/auth/domain/auth_user.dart';

void main() {
  test('AuthTokens.fromJson parses fields and defaults tokenType', () {
    final t = AuthTokens.fromJson(const {
      'accessToken': 'a',
      'refreshToken': 'r',
      'expiresIn': '3600',
    });
    expect(t.accessToken, 'a');
    expect(t.refreshToken, 'r');
    expect(t.tokenType, 'Bearer'); // default applied when absent
    expect(t.expiresIn, '3600');
  });

  test('AuthTokens.fromJson coerces a numeric expiresIn to String', () {
    final t = AuthTokens.fromJson(const {
      'accessToken': 'a',
      'refreshToken': 'r',
      'tokenType': 'Bearer',
      'expiresIn': 3600, // API may send a number
    });
    expect(t.expiresIn, '3600');
  });

  test('AuthUser.fromJson parses emailVerified and createdAt', () {
    final u = AuthUser.fromJson(const {
      'id': 'u1',
      'email': 'a@b.co',
      'firstName': 'Marina',
      'lastName': 'Costa',
      'emailVerified': false,
      'createdAt': '2026-01-02T03:04:05.000Z',
    });
    expect(u.emailVerified, false);
    expect(u.createdAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
  });

  test('AuthState is a sealed union with three cases', () {
    const user = AuthUser(
      id: 'u1', email: 'a@b.co', firstName: 'M', lastName: 'C',
      emailVerified: true, createdAt: null,
    );
    String label(AuthState s) => switch (s) {
          AuthUnknown() => 'unknown',
          AuthUnauthenticated() => 'unauthenticated',
          AuthAuthenticated(:final user) => 'auth:${user.email}',
        };
    expect(label(const AuthState.unknown()), 'unknown');
    expect(label(const AuthState.unauthenticated()), 'unauthenticated');
    expect(label(const AuthState.authenticated(user)), 'auth:a@b.co');
  });
}
```

> NOTE: the `AuthState` test constructs an `AuthUser` with `createdAt: null`. To keep that valid, the test passes `createdAt: null` — but `createdAt` is non-nullable. Replace that line with a real date: `createdAt: DateTime.utc(2026, 1, 1)`. (Use a real `DateTime`, not `null`.)

- [ ] **Step 3: Run it — expect FAIL**

Run: `flutter test test/features/auth/domain/auth_models_test.dart`
Expected: FAIL — domain files don't exist / not generated.

- [ ] **Step 4: Create the domain models**

```dart
// lib/features/auth/domain/auth_tokens.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_tokens.freezed.dart';
part 'auth_tokens.g.dart';

String? _expiresInFromJson(Object? v) => v?.toString();

@freezed
abstract class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    required String accessToken,
    required String refreshToken,
    @Default('Bearer') String tokenType,
    @JsonKey(fromJson: _expiresInFromJson) String? expiresIn,
  }) = _AuthTokens;

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);
}
```

```dart
// lib/features/auth/domain/auth_user.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';
part 'auth_user.g.dart';

@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String id,
    required String email,
    required String firstName,
    required String lastName,
    required bool emailVerified,
    required DateTime createdAt,
  }) = _AuthUser;

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      _$AuthUserFromJson(json);
}
```

```dart
// lib/features/auth/domain/auth_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'auth_user.dart';

part 'auth_state.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.unknown() = AuthUnknown;
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  const factory AuthState.authenticated(AuthUser user) = AuthAuthenticated;
}
```

```dart
// lib/features/auth/domain/register_input.dart
class RegisterInput {
  const RegisterInput({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.password,
  });
  final String email;
  final String firstName;
  final String lastName;
  final String password;
}
```

- [ ] **Step 5: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: generates `auth_tokens.freezed.dart`, `auth_tokens.g.dart`, `auth_user.freezed.dart`, `auth_user.g.dart`, `auth_state.freezed.dart`. No errors.
If build_runner reports a version conflict, STOP and report it — do not hand-edit generated files.

- [ ] **Step 6: Run the test — expect PASS**

Run: `flutter test test/features/auth/domain/auth_models_test.dart`
Expected: PASS (4 tests). Then `flutter analyze` → "No issues found!".

- [ ] **Step 7: Commit (including generated files)**

```bash
git add pubspec.yaml pubspec.lock lib/features/auth/domain test/features/auth/domain/auth_models_test.dart
git commit -m "feat(auth): domain models + codegen pipeline (pin stable freezed)"
```

---

## Task 2: AuthApi (data layer)

**Files:**
- Create: `lib/features/auth/data/auth_api.dart`
- Test: `test/features/auth/data/auth_api_test.dart`

**Interfaces:**
- Consumes: `dioProvider` (`Dio`), `AuthTokens`, `AuthUser`.
- Produces: `class AuthApi { AuthApi(Dio); Future<void> register({required String email, required String firstName, required String lastName, required String password}); Future<void> verifyEmail(String code); Future<void> resendVerification(String email); Future<AuthTokens> login(String email, String password); Future<AuthTokens> refresh(String refreshToken); Future<void> logout(String refreshToken); Future<void> forgotPassword(String email); Future<void> resetPassword(String code, String password); Future<AuthUser> me(); }` and `final authApiProvider`.
- AuthApi performs raw `dio` calls and parses success bodies into domain models. It does **not** catch errors (the repository does).

- [ ] **Step 1: Write the failing test**

```dart
// test/features/auth/data/auth_api_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/features/auth/data/auth_api.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

Response<dynamic> _resp(String path, dynamic data, [int code = 200]) => Response(
      requestOptions: RequestOptions(path: path),
      statusCode: code,
      data: data,
    );

void main() {
  late _MockDio dio;
  late AuthApi api;

  setUp(() {
    dio = _MockDio();
    api = AuthApi(dio);
  });

  test('login posts credentials and parses tokens', () async {
    when(() => dio.post('/auth/login', data: any(named: 'data'))).thenAnswer(
      (_) async => _resp('/auth/login', {
        'accessToken': 'acc',
        'refreshToken': 'ref',
        'tokenType': 'Bearer',
        'expiresIn': '3600',
      }),
    );

    final tokens = await api.login('a@b.co', 'secret123');

    expect(tokens.accessToken, 'acc');
    expect(tokens.refreshToken, 'ref');
    verify(() => dio.post('/auth/login',
        data: {'email': 'a@b.co', 'password': 'secret123'})).called(1);
  });

  test('verifyEmail posts the code under the {token} key', () async {
    when(() => dio.post('/auth/verify-email', data: any(named: 'data')))
        .thenAnswer((_) async => _resp('/auth/verify-email', {'message': 'ok'}));

    await api.verifyEmail('123456');

    verify(() => dio.post('/auth/verify-email', data: {'token': '123456'}))
        .called(1);
  });

  test('resetPassword posts token + password', () async {
    when(() => dio.post('/auth/reset-password', data: any(named: 'data')))
        .thenAnswer((_) async => _resp('/auth/reset-password', {'message': 'ok'}));

    await api.resetPassword('123456', 'newpass12');

    verify(() => dio.post('/auth/reset-password',
        data: {'token': '123456', 'password': 'newpass12'})).called(1);
  });

  test('refresh posts the refresh token and parses rotated tokens', () async {
    when(() => dio.post('/auth/refresh', data: any(named: 'data'))).thenAnswer(
      (_) async => _resp('/auth/refresh',
          {'accessToken': 'a2', 'refreshToken': 'r2', 'tokenType': 'Bearer'}),
    );

    final tokens = await api.refresh('r1');

    expect(tokens.accessToken, 'a2');
    expect(tokens.refreshToken, 'r2');
    verify(() => dio.post('/auth/refresh', data: {'refreshToken': 'r1'}))
        .called(1);
  });

  test('me() GETs /me and parses the user', () async {
    when(() => dio.get('/me')).thenAnswer((_) async => _resp('/me', {
          'id': 'u1',
          'email': 'a@b.co',
          'firstName': 'Marina',
          'lastName': 'Costa',
          'emailVerified': true,
          'createdAt': '2026-01-02T03:04:05.000Z',
        }));

    final user = await api.me();

    expect(user.id, 'u1');
    expect(user.emailVerified, true);
    verify(() => dio.get('/me')).called(1);
  });
}
```

- [ ] **Step 2: Run it — expect FAIL**

Run: `flutter test test/features/auth/data/auth_api_test.dart`
Expected: FAIL — `auth_api.dart` not found.

- [ ] **Step 3: Implement**

```dart
// lib/features/auth/data/auth_api.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/auth_tokens.dart';
import '../domain/auth_user.dart';

class AuthApi {
  AuthApi(this._dio);
  final Dio _dio;

  Future<void> register({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) =>
      _dio.post('/auth/register', data: {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'password': password,
      });

  Future<void> verifyEmail(String code) =>
      _dio.post('/auth/verify-email', data: {'token': code});

  Future<void> resendVerification(String email) =>
      _dio.post('/auth/verify-email/resend', data: {'email': email});

  Future<AuthTokens> login(String email, String password) async {
    final res =
        await _dio.post('/auth/login', data: {'email': email, 'password': password});
    return AuthTokens.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    final res =
        await _dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
    return AuthTokens.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> logout(String refreshToken) =>
      _dio.post('/auth/logout', data: {'refreshToken': refreshToken});

  Future<void> forgotPassword(String email) =>
      _dio.post('/auth/forgot-password', data: {'email': email});

  Future<void> resetPassword(String code, String password) =>
      _dio.post('/auth/reset-password', data: {'token': code, 'password': password});

  Future<AuthUser> me() async {
    final res = await _dio.get('/me');
    return AuthUser.fromJson(res.data as Map<String, dynamic>);
  }
}

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(dioProvider)));
```

- [ ] **Step 4: Run it — expect PASS**

Run: `flutter test test/features/auth/data/auth_api_test.dart`
Expected: PASS (5 tests). `flutter analyze` clean.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/data/auth_api.dart test/features/auth/data/auth_api_test.dart
git commit -m "feat(auth): AuthApi dio wrapper"
```

---

## Task 3: AuthRepository (persistence + Failure mapping)

**Files:**
- Create: `lib/features/auth/data/auth_repository.dart`
- Test: `test/features/auth/data/auth_repository_test.dart`

**Interfaces:**
- Consumes: `AuthApi` (Task 2), `TokenStorage` (`tokenStorageProvider`), `failureFromDio`, `Failure` subtypes, `RegisterInput`, `AuthTokens`, `AuthUser`.
- Produces: `class AuthRepository { AuthRepository(AuthApi, TokenStorage); Future<void> register(RegisterInput); Future<void> verifyEmail(String code); Future<void> resendVerification(String email); Future<void> login(String email, String password); Future<void> refresh(); Future<void> logout(); Future<void> forgotPassword(String email); Future<void> resetPassword(String code, String password); Future<AuthUser> me(); }` and `final authRepositoryProvider`.
- Behaviour: `login` persists both tokens; `refresh` reads the stored refresh token, calls the API, persists the **rotated** pair (throws `UnauthorizedFailure` if there is no stored refresh token); `logout` best-effort calls the API then **always** clears storage; every method maps `DioException → Failure` via `failureFromDio`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/auth/data/auth_repository_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/core/storage/token_storage.dart';
import 'package:fluxy_app/features/auth/data/auth_api.dart';
import 'package:fluxy_app/features/auth/data/auth_repository.dart';
import 'package:fluxy_app/features/auth/domain/auth_tokens.dart';
import 'package:fluxy_app/features/auth/domain/register_input.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements AuthApi {}

class _FakeStorage implements TokenStorage {
  String? access;
  String? refresh;
  int clears = 0;
  @override
  Future<void> save({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
  }
  @override
  Future<String?> readAccess() async => access;
  @override
  Future<String?> readRefresh() async => refresh;
  @override
  Future<void> clear() async {
    clears++;
    access = null;
    refresh = null;
  }
}

DioException _dioErr(int code) => DioException(
      requestOptions: RequestOptions(path: '/auth/login'),
      response: Response(
          requestOptions: RequestOptions(path: '/auth/login'), statusCode: code),
      type: DioExceptionType.badResponse,
    );

void main() {
  late _MockApi api;
  late _FakeStorage storage;
  late AuthRepository repo;

  setUp(() {
    api = _MockApi();
    storage = _FakeStorage();
    repo = AuthRepository(api, storage);
  });

  test('login persists both tokens', () async {
    when(() => api.login('a@b.co', 'secret123')).thenAnswer((_) async =>
        const AuthTokens(accessToken: 'acc', refreshToken: 'ref'));

    await repo.login('a@b.co', 'secret123');

    expect(storage.access, 'acc');
    expect(storage.refresh, 'ref');
  });

  test('login maps a 401 DioException to a Failure', () async {
    when(() => api.login(any(), any())).thenThrow(_dioErr(401));

    expect(() => repo.login('a@b.co', 'x'), throwsA(isA<Failure>()));
  });

  test('refresh reads stored refresh, persists the rotated pair', () async {
    storage.refresh = 'r1';
    when(() => api.refresh('r1')).thenAnswer(
        (_) async => const AuthTokens(accessToken: 'a2', refreshToken: 'r2'));

    await repo.refresh();

    expect(storage.access, 'a2');
    expect(storage.refresh, 'r2');
  });

  test('refresh without a stored token throws UnauthorizedFailure', () async {
    expect(() => repo.refresh(), throwsA(isA<UnauthorizedFailure>()));
  });

  test('logout clears storage even when the API call fails', () async {
    storage.refresh = 'r1';
    when(() => api.logout(any())).thenThrow(_dioErr(500));

    await repo.logout();

    expect(storage.clears, 1);
    expect(storage.refresh, isNull);
  });

  test('verifyEmail delegates the code to the API', () async {
    when(() => api.verifyEmail('123456')).thenAnswer((_) async {});
    await repo.verifyEmail('123456');
    verify(() => api.verifyEmail('123456')).called(1);
  });
}
```

- [ ] **Step 2: Run it — expect FAIL**

Run: `flutter test test/features/auth/data/auth_repository_test.dart`
Expected: FAIL — `auth_repository.dart` not found.

- [ ] **Step 3: Implement**

```dart
// lib/features/auth/data/auth_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_user.dart';
import '../domain/register_input.dart';
import 'auth_api.dart';

class AuthRepository {
  AuthRepository(this._api, this._storage);
  final AuthApi _api;
  final TokenStorage _storage;

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on DioException catch (e) {
      throw failureFromDio(e);
    }
  }

  Future<void> register(RegisterInput input) => _guard(() => _api.register(
        email: input.email,
        firstName: input.firstName,
        lastName: input.lastName,
        password: input.password,
      ));

  Future<void> verifyEmail(String code) => _guard(() => _api.verifyEmail(code));

  Future<void> resendVerification(String email) =>
      _guard(() => _api.resendVerification(email));

  Future<void> login(String email, String password) => _guard(() async {
        final tokens = await _api.login(email, password);
        await _storage.save(
            access: tokens.accessToken, refresh: tokens.refreshToken);
      });

  Future<void> refresh() => _guard(() async {
        final current = await _storage.readRefresh();
        if (current == null) {
          throw const UnauthorizedFailure();
        }
        final tokens = await _api.refresh(current);
        await _storage.save(
            access: tokens.accessToken, refresh: tokens.refreshToken);
      });

  Future<void> forgotPassword(String email) =>
      _guard(() => _api.forgotPassword(email));

  Future<void> resetPassword(String code, String password) =>
      _guard(() => _api.resetPassword(code, password));

  Future<AuthUser> me() => _guard(() => _api.me());

  /// Best-effort server logout, then ALWAYS clear local tokens.
  Future<void> logout() async {
    final current = await _storage.readRefresh();
    if (current != null) {
      try {
        await _api.logout(current);
      } catch (_) {
        // ignore — local clear is what matters
      }
    }
    await _storage.clear();
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
      ref.watch(authApiProvider), ref.watch(tokenStorageProvider)),
);
```

> Note: the `if (current == null) throw const UnauthorizedFailure()` is thrown **inside** `_guard`, whose `try` only catches `DioException`, so the `Failure` propagates unwrapped. Correct.

- [ ] **Step 4: Run it — expect PASS**

Run: `flutter test test/features/auth/data/auth_repository_test.dart`
Expected: PASS (6 tests). `flutter analyze` clean.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/data/auth_repository.dart test/features/auth/data/auth_repository_test.dart
git commit -m "feat(auth): AuthRepository with token persistence + Failure mapping"
```

---

## Task 4: AuthController + session-status mapping

**Files:**
- Create: `lib/features/auth/presentation/auth_controller.dart`
- Test: `test/features/auth/presentation/auth_controller_test.dart`

**Interfaces:**
- Consumes: `authRepositoryProvider`, `tokenStorageProvider`, `AuthState`/`AuthUser`, `Failure`, `RegisterInput`, `SessionStatus`.
- Produces: `class AuthController extends Notifier<AuthState>` with `AuthState build()` (returns `AuthState.unknown()` and schedules `bootstrap()`), `Future<void> bootstrap()`, `Future<void> refreshUser()`, `Future<void> login(String email, String password)`, `Future<void> register(RegisterInput)`, `Future<void> logout()`, `void onSessionExpired()`. Plus `final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new)`.
- Produces: `SessionStatus sessionStatusFromAuth(AuthState s)` — `unknown→unknown`, `unauthenticated→unauthenticated`, `authenticated(user)→ user.emailVerified ? authenticated : unverified`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/auth/presentation/auth_controller_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/core/session/session_status.dart';
import 'package:fluxy_app/core/storage/token_storage.dart';
import 'package:fluxy_app/features/auth/data/auth_repository.dart';
import 'package:fluxy_app/features/auth/domain/auth_state.dart';
import 'package:fluxy_app/features/auth/domain/auth_user.dart';
import 'package:fluxy_app/features/auth/presentation/auth_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}

class _FakeStorage implements TokenStorage {
  String? access;
  String? refresh;
  @override
  Future<void> save({required String access, required String refresh}) async {}
  @override
  Future<String?> readAccess() async => access;
  @override
  Future<String?> readRefresh() async => refresh;
  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

AuthUser _user({bool verified = true}) => AuthUser(
      id: 'u1', email: 'a@b.co', firstName: 'M', lastName: 'C',
      emailVerified: verified, createdAt: DateTime.utc(2026, 1, 1),
    );

ProviderContainer _container(_MockRepo repo, _FakeStorage storage) {
  final c = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(repo),
    tokenStorageProvider.overrideWithValue(storage),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('no stored token → unauthenticated', () async {
    final repo = _MockRepo();
    final c = _container(repo, _FakeStorage());

    expect(c.read(authControllerProvider), const AuthState.unknown());
    await c.read(authControllerProvider.notifier).bootstrap();
    expect(c.read(authControllerProvider), const AuthState.unauthenticated());
  });

  test('stored token + me() success → authenticated', () async {
    final repo = _MockRepo();
    when(() => repo.me()).thenAnswer((_) async => _user());
    final storage = _FakeStorage()..access = 'acc';
    final c = _container(repo, storage);

    await c.read(authControllerProvider.notifier).bootstrap();
    expect(c.read(authControllerProvider), AuthState.authenticated(_user()));
  });

  test('stored token + me() Failure → unauthenticated', () async {
    final repo = _MockRepo();
    when(() => repo.me()).thenThrow(const UnauthorizedFailure());
    final storage = _FakeStorage()..access = 'acc';
    final c = _container(repo, storage);

    await c.read(authControllerProvider.notifier).bootstrap();
    expect(c.read(authControllerProvider), const AuthState.unauthenticated());
  });

  test('login then refreshUser → authenticated', () async {
    final repo = _MockRepo();
    when(() => repo.login(any(), any())).thenAnswer((_) async {});
    when(() => repo.me()).thenAnswer((_) async => _user());
    final c = _container(repo, _FakeStorage());

    await c.read(authControllerProvider.notifier).login('a@b.co', 'secret123');
    expect(c.read(authControllerProvider), AuthState.authenticated(_user()));
  });

  test('onSessionExpired → unauthenticated', () async {
    final repo = _MockRepo();
    when(() => repo.me()).thenAnswer((_) async => _user());
    final storage = _FakeStorage()..access = 'acc';
    final c = _container(repo, storage);
    await c.read(authControllerProvider.notifier).bootstrap();

    c.read(authControllerProvider.notifier).onSessionExpired();
    expect(c.read(authControllerProvider), const AuthState.unauthenticated());
  });

  test('sessionStatusFromAuth maps the three cases (incl. unverified)', () {
    expect(sessionStatusFromAuth(const AuthState.unknown()),
        SessionStatus.unknown);
    expect(sessionStatusFromAuth(const AuthState.unauthenticated()),
        SessionStatus.unauthenticated);
    expect(sessionStatusFromAuth(AuthState.authenticated(_user(verified: true))),
        SessionStatus.authenticated);
    expect(sessionStatusFromAuth(AuthState.authenticated(_user(verified: false))),
        SessionStatus.unverified);
  });
}
```

- [ ] **Step 2: Run it — expect FAIL**

Run: `flutter test test/features/auth/presentation/auth_controller_test.dart`
Expected: FAIL — `auth_controller.dart` not found.

- [ ] **Step 3: Implement**

```dart
// lib/features/auth/presentation/auth_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/failure.dart';
import '../../../core/session/session_status.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';
import '../domain/register_input.dart';

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Cold-start session restore runs asynchronously; paint as Unknown first.
    Future.microtask(bootstrap);
    return const AuthState.unknown();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);
  TokenStorage get _storage => ref.read(tokenStorageProvider);

  Future<void> bootstrap() async {
    final access = await _storage.readAccess();
    final refresh = await _storage.readRefresh();
    if (access == null && refresh == null) {
      state = const AuthState.unauthenticated();
      return;
    }
    await refreshUser();
  }

  /// Loads the current user; a Failure (e.g. refresh exhausted) → signed out.
  Future<void> refreshUser() async {
    try {
      final user = await _repo.me();
      state = AuthState.authenticated(user);
    } on Failure {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    await _repo.login(email, password);
    await refreshUser();
  }

  Future<void> register(RegisterInput input) => _repo.register(input);

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState.unauthenticated();
  }

  /// Invoked by the AuthInterceptor when a refresh ultimately fails.
  void onSessionExpired() {
    // Fire-and-forget local clear; flip state immediately so the router reacts.
    _storage.clear();
    state = const AuthState.unauthenticated();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

SessionStatus sessionStatusFromAuth(AuthState s) => switch (s) {
      AuthUnknown() => SessionStatus.unknown,
      AuthUnauthenticated() => SessionStatus.unauthenticated,
      AuthAuthenticated(:final user) =>
        user.emailVerified ? SessionStatus.authenticated : SessionStatus.unverified,
    };
```

- [ ] **Step 4: Run it — expect PASS**

Run: `flutter test test/features/auth/presentation/auth_controller_test.dart`
Expected: PASS (6 tests). `flutter analyze` clean.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/auth_controller.dart test/features/auth/presentation/auth_controller_test.dart
git commit -m "feat(auth): AuthController + session-status mapping"
```

---

## Task 5: Wire foundation seams (dio refresh, router, splash)

**Files:**
- Modify: `lib/app/router.dart` (add `/splash` route + redirect for `unknown` + `refreshListenable`)
- Modify: `lib/main.dart` (compose real `dioProvider` + `sessionStatusProvider` via `ProviderScope` overrides; add `SplashScreen`)
- Test: `test/app/auth_routing_test.dart` (new — full-stack redirect via the real controller)
- Leave UNCHANGED: `lib/core/session/session_status.dart`, `lib/core/network/dio_client.dart`, `lib/core/network/auth_interceptor.dart`, and the existing `test/app/router_test.dart` (its constant `sessionStatusProvider` overrides keep passing).

**Interfaces:**
- Consumes: `authControllerProvider`, `authRepositoryProvider`, `sessionStatusFromAuth`, `sessionStatusProvider`, `dioProvider`, `buildDio`, `AuthInterceptor`, `tokenStorageProvider`, `routerProvider`.
- Produces: a booted app whose router shows a splash while `AuthState == Unknown`, then redirects to `/login` / shell / `/verify-email`; 401s drive a real `/auth/refresh`; a failed refresh forces sign-out.

- [ ] **Step 1: Write the failing test**

```dart
// test/app/auth_routing_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/app/router.dart';
import 'package:fluxy_app/core/session/session_status.dart';
import 'package:fluxy_app/core/storage/token_storage.dart';
import 'package:fluxy_app/features/auth/data/auth_repository.dart';
import 'package:fluxy_app/features/auth/domain/auth_user.dart';
import 'package:fluxy_app/features/auth/presentation/auth_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}

class _FakeStorage implements TokenStorage {
  String? access;
  String? refresh;
  @override
  Future<void> save({required String access, required String refresh}) async {}
  @override
  Future<String?> readAccess() async => access;
  @override
  Future<String?> readRefresh() async => refresh;
  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

AuthUser _user({bool verified = true}) => AuthUser(
      id: 'u1', email: 'a@b.co', firstName: 'M', lastName: 'C',
      emailVerified: verified, createdAt: DateTime.utc(2026, 1, 1),
    );

// Mirror the main.dart composition: derive sessionStatus from the real controller.
List<Override> _overrides(_MockRepo repo, _FakeStorage storage) => [
      authRepositoryProvider.overrideWithValue(repo),
      tokenStorageProvider.overrideWithValue(storage),
      sessionStatusProvider.overrideWith(
          (ref) => sessionStatusFromAuth(ref.watch(authControllerProvider))),
    ];

Future<String> _bootAndPath(WidgetTester tester, ProviderContainer c) async {
  final router = c.read(routerProvider);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
  return router.routerDelegate.currentConfiguration.uri.path;
}

void main() {
  testWidgets('no token → boots through splash to /login', (tester) async {
    final repo = _MockRepo();
    final c = ProviderContainer(overrides: _overrides(repo, _FakeStorage()));
    addTearDown(c.dispose);
    expect(await _bootAndPath(tester, c), '/login');
  });

  testWidgets('valid token + verified user → shell at /', (tester) async {
    final repo = _MockRepo();
    when(() => repo.me()).thenAnswer((_) async => _user());
    final c = ProviderContainer(
        overrides: _overrides(repo, _FakeStorage()..access = 'acc'));
    addTearDown(c.dispose);
    expect(await _bootAndPath(tester, c), '/');
  });

  testWidgets('valid token + unverified user → /verify-email', (tester) async {
    final repo = _MockRepo();
    when(() => repo.me()).thenAnswer((_) async => _user(verified: false));
    final c = ProviderContainer(
        overrides: _overrides(repo, _FakeStorage()..access = 'acc'));
    addTearDown(c.dispose);
    expect(await _bootAndPath(tester, c), '/verify-email');
  });
}
```

- [ ] **Step 2: Run it — expect FAIL**

Run: `flutter test test/app/auth_routing_test.dart`
Expected: FAIL — the router has no `/splash` route and `unknown` doesn't redirect there, so cold-start lands on `/` (or the assertions otherwise mismatch).

- [ ] **Step 3: Add the splash route + refreshListenable to the router**

Edit `lib/app/router.dart`. Change the `unknown` case and add the `/splash` route + a `refreshListenable` bridged from `sessionStatusProvider`:

```dart
// lib/app/router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/session/session_status.dart';
import '../core/widgets/widgets.dart';
import '../core/theme/tokens.dart';
import 'placeholder_screens.dart';
import 'shell.dart';

const _publicRoutes = {
  '/login', '/register', '/forgot-password', '/reset-password', '/verify-email',
};

GoRouter buildRouter(Ref ref, {Listenable? refreshListenable}) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final status = ref.read(sessionStatusProvider);
      final path = state.uri.path;
      final isPublic = _publicRoutes.contains(path);
      switch (status) {
        case SessionStatus.unknown:
          return path == '/splash' ? null : '/splash';
        case SessionStatus.unauthenticated:
          return isPublic ? null : '/login';
        case SessionStatus.unverified:
          return path == '/verify-email' ? null : '/verify-email';
        case SessionStatus.authenticated:
          return (isPublic || path == '/splash') ? '/' : null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginPlaceholder()),
      GoRoute(path: '/register', builder: (_, _) => Scaffold(body: PlaceholderScreen('Cadastro'))),
      GoRoute(path: '/forgot-password', builder: (_, _) => Scaffold(body: PlaceholderScreen('Recuperar senha'))),
      GoRoute(path: '/reset-password', builder: (_, _) => Scaffold(body: PlaceholderScreen('Nova senha'))),
      GoRoute(path: '/verify-email', builder: (_, _) => Scaffold(body: PlaceholderScreen('Verificar e-mail'))),
      ShellRoute(
        builder: (_, _, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const PlaceholderScreen('Início')),
          GoRoute(path: '/transactions', builder: (_, _) => const PlaceholderScreen('Transações')),
          GoRoute(path: '/categories', builder: (_, _) => const PlaceholderScreen('Categorias')),
          GoRoute(path: '/account', builder: (_, _) => const PlaceholderScreen('Conta')),
        ],
      ),
    ],
  );
}

/// Bridges a Riverpod provider change into a [Listenable] for go_router.
class _ProviderRefresh extends ChangeNotifier {
  _ProviderRefresh(Ref ref) {
    ref.listen(sessionStatusProvider, (_, _) => notifyListeners());
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: AppColors.bgScreen,
        body: Center(child: FluxyLogo(size: 64)),
      );
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _ProviderRefresh(ref);
  ref.onDispose(refresh.dispose);
  return buildRouter(ref, refreshListenable: refresh);
});
```

> The existing `test/app/router_test.dart` overrides `sessionStatusProvider` with a constant, so `_ProviderRefresh`'s listener never fires there and those tests keep passing. `FluxyLogo`, `AppColors` come from the merged design system.

- [ ] **Step 4: Run the routing test — expect it to progress, then wire main.dart**

Run: `flutter test test/app/auth_routing_test.dart`
Expected: the `no token → /login` and the redirect cases now pass (the test supplies its own `sessionStatusProvider` override). If a case still fails because `bootstrap()`'s microtask hasn't settled, the `pumpAndSettle()` + `refreshListenable` should resolve it; confirm all three pass.

- [ ] **Step 5: Compose the real seams in main.dart**

Replace `lib/main.dart` with the composition root that overrides the two stub providers with real implementations (this is the ONLY place `core` stubs meet `features`):

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/network/auth_interceptor.dart';
import 'core/network/dio_client.dart';
import 'core/session/session_status.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        // Real session status, derived from the auth controller.
        sessionStatusProvider.overrideWith(
            (ref) => sessionStatusFromAuth(ref.watch(authControllerProvider))),
        // Real dio whose interceptor refreshes via the repository and
        // signals the controller on terminal session expiry.
        dioProvider.overrideWith((ref) {
          final storage = ref.watch(tokenStorageProvider);
          final interceptor = AuthInterceptor(
            storage,
            onRefresh: () async {
              try {
                await ref.read(authRepositoryProvider).refresh();
                return true;
              } catch (_) {
                return false;
              }
            },
            onSessionExpired: () =>
                ref.read(authControllerProvider.notifier).onSessionExpired(),
          );
          return buildDio(storage, interceptor);
        }),
      ],
      child: const FluxyApp(),
    ),
  );
}
```

> `dioProvider`'s override reads `authRepositoryProvider` lazily inside the `onRefresh` closure, so there is no construction cycle even though the repository ultimately watches `dioProvider` (by the time a 401 fires, `dioProvider` is already built and cached). `/auth/refresh` is a public route, so the refresh request does not re-enter the 401 path.

- [ ] **Step 6: Full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: ALL tests pass (existing `router_test.dart` green, new `auth_routing_test.dart` green, all auth unit tests green, design-system + foundation suites untouched); analyzer "No issues found!".

- [ ] **Step 7: Commit**

```bash
git add lib/app/router.dart lib/main.dart test/app/auth_routing_test.dart
git commit -m "feat(auth): wire dio refresh, session status, splash + router refresh"
```

---

## Self-Review

**Spec coverage (spec 02 §4–§6, §9, §10 + acceptance 1–6, 10 — the engine subset):**
- Domain models `AuthTokens`/`AuthUser`/`AuthState` (§4) → T1.
- `AuthApi` thin dio wrapper, one method per endpoint (§5) → T2.
- `AuthRepository` (login persists, refresh rotates, logout best-effort+clear, OTP `{token}`, error→Failure) (§5) → T3; covers acceptance 1,2,4,5,10.
- `authControllerProvider` cold-start `Unknown→me()→Authenticated/Unauthenticated`, login/register/logout/refreshUser, session-expired signal (§6) → T4.
- Interceptor refresh reuse + global session-expired + router redirect with verify gate + splash on `Unknown` (§6,§9) → T5; covers acceptance 3 (refresh reused by interceptor) and 6 (start routing).
- **Deferred to Part 2 (screens):** the five pt-BR screens, per-screen form controllers (`AsyncValue<void>`), resend cooldown, neutral forgot-password message, OTP auto-submit, smoke tests (acceptance 7,8,9,11) — they consume this engine + the design-system primitives.

**Placeholder scan:** every code step contains complete, compiling code and a behaviour test. The one prose note (Step 2 of T1: use a real `DateTime`, not `null`) is an explicit correction folded into the step, not a TODO.

**Type consistency:** `AuthTokens`/`AuthUser`/`AuthState` names and the `AuthUnknown`/`AuthUnauthenticated`/`AuthAuthenticated` union members are identical across T1→T4→T5. `AuthRepository` method set in T3 matches what T4's controller and T5's `onRefresh` call (`refresh()`, `me()`, `login`, `logout`, `register`). `sessionStatusFromAuth` (T4) is used identically by the T5 test and `main.dart`. `buildDio`/`AuthInterceptor` named args (`onRefresh`/`onSessionExpired`) match the foundation. `tokenStorageProvider`/`dioProvider`/`sessionStatusProvider`/`routerProvider` are the exact foundation provider names.

**Layering check:** `core/` files are untouched except via composition-root overrides in `main.dart`; `features/auth/data/*_api.dart` is the only place importing `dio`; `*_repository.dart` is the only place importing `TokenStorage` + `failureFromDio`. The router (`app/`) may import `core/widgets` + `core/session`; it does not import `features/`.

**Codegen note:** Part 1 establishes the freezed + json_serializable pipeline on a stable `freezed 3.2.5`; generated files are committed in T1. Riverpod providers are hand-written `Notifier`/`Provider` (consistent with the foundation), not `riverpod_generator` — intentional, lower codegen surface.
