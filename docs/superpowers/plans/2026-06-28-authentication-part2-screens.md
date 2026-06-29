# Authentication — Part 2: Screens — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the five pt-BR auth screens (Login, Cadastro, Verificar e-mail, Recuperar senha, Nova senha) on top of the merged auth **engine** (Part 1) and the design-system **primitives** — each with a form controller exposing `AsyncValue<void>` for loading/error, wired into the existing `go_router` routes.

**Architecture:** Each screen is a `ConsumerStatefulWidget` in `lib/features/auth/presentation/screens/` owning its `TextEditingController`s. Each has a sibling form controller (a hand-written `Notifier<AsyncValue<void>>`) in `lib/features/auth/presentation/controllers/` that calls the `AuthController`/`AuthRepository` and tracks in-flight + error. Pure validators + centralized pt-BR copy live in shared files. Navigation on success is mostly **automatic** (login/verify flip `AuthState` → the Part-1 router `refreshListenable` redirects); register/forgot/reset navigate explicitly. Only the screens + controllers are added; the engine is consumed, not modified.

**Tech Stack:** Flutter (Dart `^3.12.1`), `flutter_riverpod` v3 (hand-written `Notifier`), `go_router`, design-system widgets (`core/widgets/widgets.dart`), `mocktail` + `flutter_test`.

## Global Constraints

- **pt-BR copy only**, centralized in `auth_strings.dart` — no string literals scattered in widgets.
- **Colors ONLY from `AppColors`**, text ONLY from `AppText`, spacing from `AppSpacing`, radii from `AppRadii` (`core/theme`). Never hardcode hex.
- **Reuse design-system primitives** from `core/widgets/widgets.dart` (`PrimaryButton`, `AppTextField`, `PasswordField`, `LinkButton`, `InlineLink`, `AppBackButton`, `FluxyLogo`, `HelperText`, `RequirementRow`, `OtpCodeInput`, `AppLoader`). Do NOT rebuild them.
- **Validation mirrors the API** (spec 02 §8): email `^[^@\s]+@[^@\s]+\.[^@\s]+$` (≤320); password **8–200**; firstName/lastName **1–100** trimmed non-empty; OTP 6 digits.
- **No raw exception/JSON text shown.** Errors come from `Failure.message` via a single mapper; the login 401 is shown as "E-mail ou senha inválidos" (not the generic engine message).
- **Engine is consumed, not changed.** Do not modify `lib/features/auth/{domain,data}` or `auth_controller.dart`. The only `lib/app/` change is pointing routes at real screens (`router.dart`).
- TDD: failing test first, minimal code, green, commit per task. `flutter analyze` clean each task.

## Existing interfaces to consume (do NOT re-implement)

**Engine (Part 1, on main):**
- `authControllerProvider` (`NotifierProvider<AuthController, AuthState>`). Methods: `Future<void> login(String email, String password)`, `Future<void> register(RegisterInput input)`, `Future<void> logout()`, `Future<void> refreshUser()`, `void onSessionExpired()`.
- `authRepositoryProvider` (`AuthRepository`). Used directly for the screen-only flows: `verifyEmail(String code)`, `resendVerification(String email)`, `forgotPassword(String email)`, `resetPassword(String code, String password)`.
- `AuthState` sealed union: `AuthUnknown`/`AuthUnauthenticated`/`AuthAuthenticated(user)`. `AuthUser.emailVerified`.
- `RegisterInput({required email, firstName, lastName, password})` (`features/auth/domain/register_input.dart`).
- `Failure` (`core/error/failure.dart`): `sealed` with `.message`; subtypes incl. `UnauthorizedFailure`, `ValidationFailure`, `NetworkFailure`.

**Router (Part 1):** `lib/app/router.dart` — public routes `/login /register /forgot-password /reset-password /verify-email`; redirect auto-sends `authenticated`→`/`, `unverified`→`/verify-email`. Changing a route's `builder` to a real screen is all that's needed; the `refreshListenable` already re-runs redirect on `AuthState` changes.

**Design-system widget signatures:**
- `PrimaryButton({required String label, required VoidCallback? onPressed, bool loading = false})`
- `AppTextField({required String label, TextEditingController? controller, String? hintText, String? errorText, bool obscure = false, Widget? trailing, TextInputType? keyboardType, ValueChanged<String>? onChanged})`
- `PasswordField({required String label, TextEditingController? controller, String? errorText})`
- `LinkButton({required String label, required VoidCallback onPressed})`
- `InlineLink({required String leading, required String action, required VoidCallback onPressed})`
- `AppBackButton({required VoidCallback onPressed})`
- `FluxyLogo({double size = 52})`
- `HelperText({required String text, IconData icon = Icons.schedule})`
- `RequirementRow({required String text, required bool satisfied})`
- `OtpCodeInput({int length = 6, required ValueChanged<String> onChanged, ValueChanged<String>? onCompleted})`

**Tokens:** `AppColors.{bgScreen,primary,expense,textPrimary,textMuted,textHint,surface,border}`; `AppText.{titleScreen,titleSection,body,bodyStrong,label,caption,hint}`; `AppSpacing.{screenH=28,lg=24,md=16,gap=12,sm=8,xs=4,xl=38}`.

---

## File Structure (this plan)

- Create `lib/features/auth/presentation/auth_strings.dart` (all pt-BR copy).
- Create `lib/features/auth/presentation/auth_validators.dart` (pure validators + `failureText` mapper).
- Create `lib/features/auth/presentation/widgets/auth_scaffold.dart` (shared dark page layout).
- Create `lib/features/auth/presentation/controllers/`: `login_controller.dart`, `register_controller.dart`, `verify_email_controller.dart`, `forgot_password_controller.dart`, `reset_password_controller.dart`.
- Create `lib/features/auth/presentation/screens/`: `login_screen.dart`, `register_screen.dart`, `verify_email_screen.dart`, `forgot_password_screen.dart`, `reset_password_screen.dart`.
- Modify `lib/app/router.dart` (point the 5 routes at the real screens; remove `LoginPlaceholder` usage).
- Tests under `test/features/auth/presentation/`.

---

## Task 1: Shared validators, strings, and AuthScaffold

**Files:**
- Create: `lib/features/auth/presentation/auth_strings.dart`, `lib/features/auth/presentation/auth_validators.dart`, `lib/features/auth/presentation/widgets/auth_scaffold.dart`
- Test: `test/features/auth/presentation/auth_validators_test.dart`

**Interfaces:**
- Produces `AuthValidators`: `static String? email(String?)`, `static String? password(String?)`, `static String? name(String?)`, `static String? confirm(String? value, String other)` — each returns a pt-BR error string or `null` when valid.
- Produces `String failureText(Object? error)` — `error is Failure ? error.message : AuthStrings.genericError`.
- Produces `AuthStrings` (static const pt-BR copy).
- Produces `AuthScaffold({Widget? leading, required List<Widget> children})` — scrollable, safe-area, `bgScreen`, horizontal `screenH` padding, left-aligned column.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/auth/presentation/auth_validators_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/features/auth/presentation/auth_validators.dart';

void main() {
  group('email', () {
    test('rejects empty and malformed', () {
      expect(AuthValidators.email(''), isNotNull);
      expect(AuthValidators.email('nope'), isNotNull);
      expect(AuthValidators.email('a@b'), isNotNull);
    });
    test('accepts a well-formed address', () {
      expect(AuthValidators.email('a@b.co'), isNull);
    });
  });

  group('password', () {
    test('rejects < 8 chars', () => expect(AuthValidators.password('1234567'), isNotNull));
    test('accepts 8..200', () {
      expect(AuthValidators.password('12345678'), isNull);
      expect(AuthValidators.password('a' * 200), isNull);
    });
    test('rejects > 200', () => expect(AuthValidators.password('a' * 201), isNotNull));
  });

  group('name', () {
    test('rejects empty/whitespace', () {
      expect(AuthValidators.name(''), isNotNull);
      expect(AuthValidators.name('   '), isNotNull);
    });
    test('accepts a trimmed name and rejects > 100', () {
      expect(AuthValidators.name('Marina'), isNull);
      expect(AuthValidators.name('a' * 101), isNotNull);
    });
  });

  group('confirm', () {
    test('rejects a mismatch, accepts a match', () {
      expect(AuthValidators.confirm('abcd1234', 'other'), isNotNull);
      expect(AuthValidators.confirm('abcd1234', 'abcd1234'), isNull);
    });
  });

  group('failureText', () {
    test('uses Failure.message', () {
      expect(failureText(const NetworkFailure()), const NetworkFailure().message);
    });
    test('falls back for a non-Failure', () {
      expect(failureText(Exception('x')), isNotEmpty);
    });
  });
}
```

- [ ] **Step 2: Run it — expect FAIL**

Run: `flutter test test/features/auth/presentation/auth_validators_test.dart`
Expected: FAIL — files don't exist.

- [ ] **Step 3: Implement strings**

```dart
// lib/features/auth/presentation/auth_strings.dart
class AuthStrings {
  AuthStrings._();

  // Shared
  static const genericError = 'Algo deu errado. Tente novamente.';
  static const email = 'E-mail';
  static const password = 'Senha';
  static const invalidEmail = 'Informe um e-mail válido.';
  static const shortPassword = 'A senha deve ter ao menos 8 caracteres.';
  static const longPassword = 'A senha deve ter no máximo 200 caracteres.';
  static const requiredField = 'Campo obrigatório.';
  static const longName = 'Use no máximo 100 caracteres.';
  static const passwordsDontMatch = 'As senhas não coincidem.';

  // Login
  static const loginTitle = 'Bem-vindo de volta';
  static const loginSubtitle = 'Entre para acompanhar suas finanças.';
  static const loginCta = 'Entrar';
  static const forgotPassword = 'Esqueci minha senha';
  static const noAccount = 'Não tem conta?';
  static const signUp = 'Cadastre-se';
  static const invalidCredentials = 'E-mail ou senha inválidos.';

  // Register
  static const registerTitle = 'Criar conta';
  static const registerSubtitle = 'Comece a organizar seu dinheiro hoje.';
  static const firstName = 'Nome';
  static const lastName = 'Sobrenome';
  static const confirmPassword = 'Confirmar senha';
  static const registerCta = 'Cadastrar';
  static const haveAccount = 'Já tem conta?';
  static const signIn = 'Entrar';

  // Verify email
  static const verifyTitle = 'Confirme seu e-mail';
  static String verifySubtitle(String email) =>
      'Digite o código de 6 dígitos que enviamos para $email.';
  static const resendCode = 'Reenviar código';
  static String resendIn(int seconds) => 'Reenviar código em ${seconds}s';
  static const invalidCode = 'Código inválido ou expirado.';
  static const changeEmail = 'Trocar e-mail';

  // Forgot password
  static const forgotTitle = 'Recuperar senha';
  static const forgotSubtitle =
      'Informe seu e-mail e enviaremos um código para redefinir sua senha.';
  static const sendCode = 'Enviar código';
  static const forgotNeutral =
      'Se houver uma conta com esse e-mail, enviamos um código.';
  static const rememberedPassword = 'Lembrou a senha?';
  static const backToLogin = 'Voltar ao login';

  // Reset password
  static const resetTitle = 'Nova senha';
  static const resetSubtitle = 'Crie uma nova senha para sua conta.';
  static const code = 'Código';
  static const newPassword = 'Nova senha';
  static const confirmNewPassword = 'Confirmar nova senha';
  static const minChars = 'Mínimo de 8 caracteres';
  static const savePassword = 'Salvar senha';
  static const passwordResetDone = 'Senha alterada. Faça login.';
}
```

- [ ] **Step 4: Implement validators**

```dart
// lib/features/auth/presentation/auth_validators.dart
import '../../../core/error/failure.dart';
import 'auth_strings.dart';

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class AuthValidators {
  AuthValidators._();

  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty || v.length > 320 || !_emailRe.hasMatch(v)) {
      return AuthStrings.invalidEmail;
    }
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.length < 8) return AuthStrings.shortPassword;
    if (v.length > 200) return AuthStrings.longPassword;
    return null;
  }

  static String? name(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return AuthStrings.requiredField;
    if (v.length > 100) return AuthStrings.longName;
    return null;
  }

  static String? confirm(String? value, String other) {
    if ((value ?? '') != other) return AuthStrings.passwordsDontMatch;
    return null;
  }
}

/// Maps any thrown error to a user-facing pt-BR string.
String failureText(Object? error) =>
    error is Failure ? error.message : AuthStrings.genericError;
```

- [ ] **Step 5: Implement AuthScaffold**

```dart
// lib/features/auth/presentation/widgets/auth_scaffold.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/tokens.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, this.leading, required this.children});
  final Widget? leading;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgScreen,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenH, vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(height: AppSpacing.lg),
              ],
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Run it — expect PASS**

Run: `flutter test test/features/auth/presentation/auth_validators_test.dart`
Expected: PASS. `flutter analyze` clean.

- [ ] **Step 7: Commit**

```bash
git add lib/features/auth/presentation/auth_strings.dart lib/features/auth/presentation/auth_validators.dart lib/features/auth/presentation/widgets/auth_scaffold.dart test/features/auth/presentation/auth_validators_test.dart
git commit -m "feat(auth): shared validators, strings, and AuthScaffold"
```

---

## Task 2: Login screen + controller

**Files:**
- Create: `lib/features/auth/presentation/controllers/login_controller.dart`, `lib/features/auth/presentation/screens/login_screen.dart`
- Modify: `lib/app/router.dart` (point `/login` at `LoginScreen`)
- Test: `test/features/auth/presentation/login_controller_test.dart`, `test/features/auth/presentation/login_screen_test.dart`

**Interfaces:**
- Produces `LoginController extends Notifier<AsyncValue<void>>` + `loginControllerProvider`. `Future<bool> submit(String email, String password)` — `AsyncLoading` → calls `authController.login` → `AsyncData(null)` + `true`, or `AsyncError(Failure)` + `false`. On `UnauthorizedFailure` it stores a `ValidationFailure(AuthStrings.invalidCredentials)` so the screen shows the friendly message.
- Produces `LoginScreen` — logo, title/subtitle, email + password fields, right-aligned "Esqueci minha senha" `LinkButton`, `PrimaryButton` (loading-bound), inline error, footer `InlineLink` → `/register`. Success needs no manual nav (router auto-redirects on `authenticated`).

- [ ] **Step 1: Write the failing controller test**

```dart
// test/features/auth/presentation/login_controller_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/features/auth/presentation/auth_controller.dart';
import 'package:fluxy_app/features/auth/presentation/auth_strings.dart';
import 'package:fluxy_app/features/auth/presentation/controllers/login_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements AuthController {}

void main() {
  test('submit success → AsyncData and returns true', () async {
    final auth = _MockAuth();
    when(() => auth.login(any(), any())).thenAnswer((_) async {});
    final c = ProviderContainer(overrides: [
      authControllerProvider.overrideWith(() => auth),
    ]);
    addTearDown(c.dispose);

    final ok = await c.read(loginControllerProvider.notifier).submit('a@b.co', 'secret123');

    expect(ok, true);
    expect(c.read(loginControllerProvider).hasError, false);
  });

  test('a 401 surfaces the friendly "invalid credentials" message', () async {
    final auth = _MockAuth();
    when(() => auth.login(any(), any())).thenThrow(const UnauthorizedFailure());
    final c = ProviderContainer(overrides: [
      authControllerProvider.overrideWith(() => auth),
    ]);
    addTearDown(c.dispose);

    final ok = await c.read(loginControllerProvider.notifier).submit('a@b.co', 'x');

    expect(ok, false);
    final state = c.read(loginControllerProvider);
    expect(state.hasError, true);
    expect((state.error as Failure).message, AuthStrings.invalidCredentials);
  });
}
```

> NOTE: `authControllerProvider.overrideWith(() => auth)` provides a stub `AuthController` whose `build()` is the mock's (mocktail returns `null`/does nothing). Because `LoginController` only ever calls `.notifier`'s `login`, the mock's `build()` is not exercised. If mocktail complains about an unstubbed `build()`, add `when(() => auth.build()).thenReturn(const AuthState.unauthenticated());` and import `auth_state.dart`.

- [ ] **Step 2: Run it — expect FAIL**

Run: `flutter test test/features/auth/presentation/login_controller_test.dart`
Expected: FAIL — `login_controller.dart` not found.

- [ ] **Step 3: Implement the controller**

```dart
// lib/features/auth/presentation/controllers/login_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failure.dart';
import '../auth_controller.dart';
import '../auth_strings.dart';

class LoginController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> submit(String email, String password) async {
    state = const AsyncLoading();
    try {
      await ref.read(authControllerProvider.notifier).login(email, password);
      if (!ref.mounted) return false;
      state = const AsyncData(null);
      return true;
    } on Failure catch (e, st) {
      if (!ref.mounted) return false;
      // A 401 on login means bad credentials, not an expired session.
      final shown = e is UnauthorizedFailure
          ? const ValidationFailure(AuthStrings.invalidCredentials)
          : e;
      state = AsyncError(shown, st);
      return false;
    }
  }
}

final loginControllerProvider =
    NotifierProvider<LoginController, AsyncValue<void>>(LoginController.new);
```

- [ ] **Step 4: Run it — expect PASS**

Run: `flutter test test/features/auth/presentation/login_controller_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Write the failing screen test**

```dart
// test/features/auth/presentation/login_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/features/auth/presentation/auth_controller.dart';
import 'package:fluxy_app/features/auth/presentation/auth_strings.dart';
import 'package:fluxy_app/features/auth/presentation/screens/login_screen.dart';
import 'package:fluxy_app/features/auth/domain/auth_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements AuthController {}

Widget _host(ProviderContainer c) => UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: LoginScreen()),
    );

void main() {
  testWidgets('renders title, fields and CTA', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await tester.pumpWidget(_host(c));
    expect(find.text(AuthStrings.loginTitle), findsOneWidget);
    expect(find.text(AuthStrings.loginCta), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2)); // email + password
  });

  testWidgets('invalid email shows a field error and does not call login', (tester) async {
    final auth = _MockAuth();
    when(() => auth.build()).thenReturn(const AuthState.unauthenticated());
    final c = ProviderContainer(overrides: [authControllerProvider.overrideWith(() => auth)]);
    addTearDown(c.dispose);
    await tester.pumpWidget(_host(c));

    await tester.enterText(find.byType(TextField).at(0), 'nope');
    await tester.enterText(find.byType(TextField).at(1), 'secret123');
    await tester.tap(find.text(AuthStrings.loginCta));
    await tester.pump();

    expect(find.text(AuthStrings.invalidEmail), findsOneWidget);
    verifyNever(() => auth.login(any(), any()));
  });

  testWidgets('a failed login shows the friendly error', (tester) async {
    final auth = _MockAuth();
    when(() => auth.build()).thenReturn(const AuthState.unauthenticated());
    when(() => auth.login(any(), any())).thenThrow(const UnauthorizedFailure());
    final c = ProviderContainer(overrides: [authControllerProvider.overrideWith(() => auth)]);
    addTearDown(c.dispose);
    await tester.pumpWidget(_host(c));

    await tester.enterText(find.byType(TextField).at(0), 'a@b.co');
    await tester.enterText(find.byType(TextField).at(1), 'wrongpass');
    await tester.tap(find.text(AuthStrings.loginCta));
    await tester.pumpAndSettle();

    expect(find.text(AuthStrings.invalidCredentials), findsOneWidget);
  });
}
```

- [ ] **Step 6: Implement the screen**

```dart
// lib/features/auth/presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../auth_strings.dart';
import '../auth_validators.dart';
import '../controllers/login_controller.dart';
import '../widgets/auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final emailError = AuthValidators.email(_email.text);
    final passwordError = AuthValidators.password(_password.text);
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });
    if (emailError != null || passwordError != null) return;
    // Success flips AuthState → the router redirects automatically.
    await ref
        .read(loginControllerProvider.notifier)
        .submit(_email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final loading = state.isLoading;
    return AuthScaffold(
      children: [
        const FluxyLogo(),
        const SizedBox(height: AppSpacing.lg),
        Text(AuthStrings.loginTitle, style: AppText.titleScreen),
        const SizedBox(height: AppSpacing.sm),
        Text(AuthStrings.loginSubtitle, style: AppText.body),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          label: AuthStrings.email,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
        ),
        const SizedBox(height: AppSpacing.md),
        PasswordField(
          label: AuthStrings.password,
          controller: _password,
          errorText: _passwordError,
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: LinkButton(
            label: AuthStrings.forgotPassword,
            onPressed: () => context.go('/forgot-password'),
          ),
        ),
        if (state.hasError) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(failureText(state.error),
              style: AppText.caption.copyWith(color: AppColors.expense)),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: AuthStrings.loginCta,
          loading: loading,
          onPressed: loading ? null : _submit,
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: InlineLink(
            leading: AuthStrings.noAccount,
            action: AuthStrings.signUp,
            onPressed: () => context.go('/register'),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 7: Point the route at the screen**

In `lib/app/router.dart`: add `import '../features/auth/presentation/screens/login_screen.dart';` and change the `/login` route to `GoRoute(path: '/login', builder: (_, _) => const LoginScreen())`. (Leave `LoginPlaceholder` import for now; it is removed in Task 7.)

- [ ] **Step 8: Run screen test + analyze**

Run: `flutter test test/features/auth/presentation/login_screen_test.dart && flutter analyze`
Expected: PASS (3 tests); analyzer clean.

- [ ] **Step 9: Commit**

```bash
git add lib/features/auth/presentation/controllers/login_controller.dart lib/features/auth/presentation/screens/login_screen.dart lib/app/router.dart test/features/auth/presentation/login_controller_test.dart test/features/auth/presentation/login_screen_test.dart
git commit -m "feat(auth): Login screen + controller"
```

---

## Task 3: Cadastro (register) screen + controller

**Files:**
- Create: `lib/features/auth/presentation/controllers/register_controller.dart`, `lib/features/auth/presentation/screens/register_screen.dart`
- Modify: `lib/app/router.dart` (point `/register` at `RegisterScreen`)
- Test: `test/features/auth/presentation/register_controller_test.dart`, `test/features/auth/presentation/register_screen_test.dart`

**Interfaces:**
- Produces `RegisterController extends Notifier<AsyncValue<void>>` + `registerControllerProvider`. `Future<bool> submit(RegisterInput input)` — `AsyncLoading` → `authController.register(input)` → `AsyncData` + `true` / `AsyncError(Failure)` + `false`.
- Produces `RegisterScreen` — back button → `/login`; title/subtitle; Nome, Sobrenome, Email, Senha, Confirmar senha; `PrimaryButton`; footer `InlineLink` → `/login`. On success navigates to `/verify-email?email=<encoded>`.

- [ ] **Step 1: Write the failing controller test**

```dart
// test/features/auth/presentation/register_controller_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/features/auth/domain/auth_state.dart';
import 'package:fluxy_app/features/auth/domain/register_input.dart';
import 'package:fluxy_app/features/auth/presentation/auth_controller.dart';
import 'package:fluxy_app/features/auth/presentation/controllers/register_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements AuthController {}

const _input = RegisterInput(
    email: 'a@b.co', firstName: 'Marina', lastName: 'Costa', password: 'secret123');

void main() {
  setUpAll(() => registerFallbackValue(_input));

  test('submit success → true', () async {
    final auth = _MockAuth();
    when(() => auth.build()).thenReturn(const AuthState.unauthenticated());
    when(() => auth.register(any())).thenAnswer((_) async {});
    final c = ProviderContainer(overrides: [authControllerProvider.overrideWith(() => auth)]);
    addTearDown(c.dispose);

    expect(await c.read(registerControllerProvider.notifier).submit(_input), true);
  });

  test('a conflict (email taken) → AsyncError with the API message', () async {
    final auth = _MockAuth();
    when(() => auth.build()).thenReturn(const AuthState.unauthenticated());
    when(() => auth.register(any()))
        .thenThrow(const ConflictFailure('E-mail já cadastrado'));
    final c = ProviderContainer(overrides: [authControllerProvider.overrideWith(() => auth)]);
    addTearDown(c.dispose);

    final ok = await c.read(registerControllerProvider.notifier).submit(_input);
    expect(ok, false);
    expect((c.read(registerControllerProvider).error as Failure).message,
        'E-mail já cadastrado');
  });
}
```

- [ ] **Step 2: Run it — expect FAIL** (`register_controller.dart` not found)

- [ ] **Step 3: Implement the controller**

```dart
// lib/features/auth/presentation/controllers/register_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failure.dart';
import '../../domain/register_input.dart';
import '../auth_controller.dart';

class RegisterController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> submit(RegisterInput input) async {
    state = const AsyncLoading();
    try {
      await ref.read(authControllerProvider.notifier).register(input);
      if (!ref.mounted) return false;
      state = const AsyncData(null);
      return true;
    } on Failure catch (e, st) {
      if (!ref.mounted) return false;
      state = AsyncError(e, st);
      return false;
    }
  }
}

final registerControllerProvider =
    NotifierProvider<RegisterController, AsyncValue<void>>(RegisterController.new);
```

- [ ] **Step 4: Run it — expect PASS** (2 tests)

- [ ] **Step 5: Write the failing screen test**

```dart
// test/features/auth/presentation/register_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/features/auth/presentation/auth_strings.dart';
import 'package:fluxy_app/features/auth/presentation/screens/register_screen.dart';

Widget _host() => const ProviderScope(child: MaterialApp(home: RegisterScreen()));

void main() {
  testWidgets('renders the five fields and CTA', (tester) async {
    await tester.pumpWidget(_host());
    expect(find.text(AuthStrings.registerTitle), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(5)); // first,last,email,pwd,confirm
    expect(find.text(AuthStrings.registerCta), findsOneWidget);
  });

  testWidgets('mismatched passwords block submit with an inline error', (tester) async {
    await tester.pumpWidget(_host());
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Marina');
    await tester.enterText(fields.at(1), 'Costa');
    await tester.enterText(fields.at(2), 'a@b.co');
    await tester.enterText(fields.at(3), 'secret123');
    await tester.enterText(fields.at(4), 'different');
    await tester.tap(find.text(AuthStrings.registerCta));
    await tester.pump();
    expect(find.text(AuthStrings.passwordsDontMatch), findsOneWidget);
  });
}
```

- [ ] **Step 6: Implement the screen**

```dart
// lib/features/auth/presentation/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/register_input.dart';
import '../auth_strings.dart';
import '../auth_validators.dart';
import '../controllers/register_controller.dart';
import '../widgets/auth_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _firstErr, _lastErr, _emailErr, _passwordErr, _confirmErr;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final firstErr = AuthValidators.name(_first.text);
    final lastErr = AuthValidators.name(_last.text);
    final emailErr = AuthValidators.email(_email.text);
    final passwordErr = AuthValidators.password(_password.text);
    final confirmErr = AuthValidators.confirm(_confirm.text, _password.text);
    setState(() {
      _firstErr = firstErr;
      _lastErr = lastErr;
      _emailErr = emailErr;
      _passwordErr = passwordErr;
      _confirmErr = confirmErr;
    });
    if ([firstErr, lastErr, emailErr, passwordErr, confirmErr].any((e) => e != null)) {
      return;
    }
    final email = _email.text.trim();
    final ok = await ref.read(registerControllerProvider.notifier).submit(
          RegisterInput(
            email: email,
            firstName: _first.text.trim(),
            lastName: _last.text.trim(),
            password: _password.text,
          ),
        );
    if (ok && mounted) {
      context.go('/verify-email?email=${Uri.encodeComponent(email)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerControllerProvider);
    final loading = state.isLoading;
    return AuthScaffold(
      leading: AppBackButton(onPressed: () => context.go('/login')),
      children: [
        Text(AuthStrings.registerTitle, style: AppText.titleScreen),
        const SizedBox(height: AppSpacing.sm),
        Text(AuthStrings.registerSubtitle, style: AppText.body),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(label: AuthStrings.firstName, controller: _first, errorText: _firstErr),
        const SizedBox(height: AppSpacing.md),
        AppTextField(label: AuthStrings.lastName, controller: _last, errorText: _lastErr),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: AuthStrings.email,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailErr,
        ),
        const SizedBox(height: AppSpacing.md),
        PasswordField(label: AuthStrings.password, controller: _password, errorText: _passwordErr),
        const SizedBox(height: AppSpacing.md),
        PasswordField(
            label: AuthStrings.confirmPassword, controller: _confirm, errorText: _confirmErr),
        if (state.hasError) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(failureText(state.error),
              style: AppText.caption.copyWith(color: AppColors.expense)),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
            label: AuthStrings.registerCta, loading: loading, onPressed: loading ? null : _submit),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: InlineLink(
            leading: AuthStrings.haveAccount,
            action: AuthStrings.signIn,
            onPressed: () => context.go('/login'),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 7: Point `/register` at `RegisterScreen`** in `lib/app/router.dart` (add import; replace the placeholder builder).

- [ ] **Step 8: Run screen test + analyze** — `flutter test test/features/auth/presentation/register_screen_test.dart && flutter analyze` → PASS (2 tests), clean.

- [ ] **Step 9: Commit**

```bash
git add lib/features/auth/presentation/controllers/register_controller.dart lib/features/auth/presentation/screens/register_screen.dart lib/app/router.dart test/features/auth/presentation/register_controller_test.dart test/features/auth/presentation/register_screen_test.dart
git commit -m "feat(auth): Cadastro screen + controller"
```

---

## Task 4: Verificar e-mail screen + controller

**Files:**
- Create: `lib/features/auth/presentation/controllers/verify_email_controller.dart`, `lib/features/auth/presentation/screens/verify_email_screen.dart`
- Modify: `lib/app/router.dart` (point `/verify-email` at `VerifyEmailScreen`, reading the `email` query param)
- Test: `test/features/auth/presentation/verify_email_controller_test.dart`, `test/features/auth/presentation/verify_email_screen_test.dart`

**Interfaces:**
- Produces `VerifyEmailController extends Notifier<AsyncValue<void>>` + `verifyEmailControllerProvider`:
  - `Future<bool> verify(String code)` — calls `authRepository.verifyEmail(code)`, then `authController.refreshUser()`; `AsyncData`+`true` on success, `AsyncError(ValidationFailure(invalidCode))`+`false` on a `Failure`.
  - `Future<void> resend(String email)` — calls `authRepository.resendVerification(email)` (best-effort; swallows error).
- Produces `VerifyEmailScreen({required String email})` — title + `verifySubtitle(email)`; `OtpCodeInput` (auto-submits via `onCompleted`); a `Reenviar código` `LinkButton` with a ~60s cooldown countdown (disabled while counting); a `Trocar e-mail` `LinkButton` → `authController.logout()` + `/login`. On verify success: if the user is now `authenticated`+verified the router redirects to `/`; otherwise (no session — came from register) navigate to `/login`.

- [ ] **Step 1: Write the failing controller test**

```dart
// test/features/auth/presentation/verify_email_controller_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/features/auth/data/auth_repository.dart';
import 'package:fluxy_app/features/auth/domain/auth_state.dart';
import 'package:fluxy_app/features/auth/presentation/auth_controller.dart';
import 'package:fluxy_app/features/auth/presentation/auth_strings.dart';
import 'package:fluxy_app/features/auth/presentation/controllers/verify_email_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}
class _MockAuth extends Mock implements AuthController {}

ProviderContainer _c(_MockRepo repo, _MockAuth auth) {
  final c = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(repo),
    authControllerProvider.overrideWith(() => auth),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('verify success calls repo.verifyEmail then refreshUser', () async {
    final repo = _MockRepo();
    final auth = _MockAuth();
    when(() => auth.build()).thenReturn(const AuthState.unauthenticated());
    when(() => repo.verifyEmail('123456')).thenAnswer((_) async {});
    when(() => auth.refreshUser()).thenAnswer((_) async {});
    final c = _c(repo, auth);

    final ok = await c.read(verifyEmailControllerProvider.notifier).verify('123456');

    expect(ok, true);
    verify(() => repo.verifyEmail('123456')).called(1);
    verify(() => auth.refreshUser()).called(1);
  });

  test('an invalid code → AsyncError with the friendly message', () async {
    final repo = _MockRepo();
    final auth = _MockAuth();
    when(() => auth.build()).thenReturn(const AuthState.unauthenticated());
    when(() => repo.verifyEmail(any())).thenThrow(const ValidationFailure('bad'));
    final c = _c(repo, auth);

    final ok = await c.read(verifyEmailControllerProvider.notifier).verify('000000');

    expect(ok, false);
    expect((c.read(verifyEmailControllerProvider).error as Failure).message,
        AuthStrings.invalidCode);
  });

  test('resend swallows errors (best-effort)', () async {
    final repo = _MockRepo();
    final auth = _MockAuth();
    when(() => auth.build()).thenReturn(const AuthState.unauthenticated());
    when(() => repo.resendVerification(any())).thenThrow(const NetworkFailure());
    final c = _c(repo, auth);

    await c.read(verifyEmailControllerProvider.notifier).resend('a@b.co'); // must not throw
    verify(() => repo.resendVerification('a@b.co')).called(1);
  });
}
```

- [ ] **Step 2: Run it — expect FAIL**

- [ ] **Step 3: Implement the controller**

```dart
// lib/features/auth/presentation/controllers/verify_email_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failure.dart';
import '../../data/auth_repository.dart';
import '../auth_controller.dart';
import '../auth_strings.dart';

class VerifyEmailController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> verify(String code) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).verifyEmail(code);
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (!ref.mounted) return false;
      state = const AsyncData(null);
      return true;
    } on Failure catch (_, st) {
      if (!ref.mounted) return false;
      state = AsyncError(const ValidationFailure(AuthStrings.invalidCode), st);
      return false;
    }
  }

  Future<void> resend(String email) async {
    try {
      await ref.read(authRepositoryProvider).resendVerification(email);
    } on Failure {
      // best-effort; cooldown still applies in the UI
    }
  }
}

final verifyEmailControllerProvider =
    NotifierProvider<VerifyEmailController, AsyncValue<void>>(VerifyEmailController.new);
```

- [ ] **Step 4: Run it — expect PASS** (3 tests)

- [ ] **Step 5: Write the failing screen test**

```dart
// test/features/auth/presentation/verify_email_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/widgets/widgets.dart';
import 'package:fluxy_app/features/auth/data/auth_repository.dart';
import 'package:fluxy_app/features/auth/domain/auth_state.dart';
import 'package:fluxy_app/features/auth/presentation/auth_controller.dart';
import 'package:fluxy_app/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}
class _MockAuth extends Mock implements AuthController {}

void main() {
  testWidgets('entering 6 digits auto-submits to repo.verifyEmail', (tester) async {
    final repo = _MockRepo();
    final auth = _MockAuth();
    when(() => auth.build()).thenReturn(const AuthState.unauthenticated());
    when(() => repo.verifyEmail(any())).thenAnswer((_) async {});
    when(() => auth.refreshUser()).thenAnswer((_) async {});
    final c = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      authControllerProvider.overrideWith(() => auth),
    ]);
    addTearDown(c.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: VerifyEmailScreen(email: 'a@b.co')),
    ));
    expect(find.byType(OtpCodeInput), findsOneWidget);

    final boxes = find.byType(TextField);
    for (var i = 0; i < 6; i++) {
      await tester.enterText(boxes.at(i), '${i + 1}');
      await tester.pump();
    }
    await tester.pump();
    verify(() => repo.verifyEmail('123456')).called(1);
  });

  testWidgets('resend starts a cooldown that disables the button', (tester) async {
    final repo = _MockRepo();
    final auth = _MockAuth();
    when(() => auth.build()).thenReturn(const AuthState.unauthenticated());
    when(() => repo.resendVerification(any())).thenAnswer((_) async {});
    final c = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      authControllerProvider.overrideWith(() => auth),
    ]);
    addTearDown(c.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: VerifyEmailScreen(email: 'a@b.co')),
    ));

    await tester.tap(find.text('Reenviar código'));
    await tester.pump();
    verify(() => repo.resendVerification('a@b.co')).called(1);
    // Now in cooldown: the active "Reenviar código" label is gone (shows a countdown).
    expect(find.text('Reenviar código'), findsNothing);
    // Let the timer cancel so the test exits cleanly.
    await tester.pump(const Duration(seconds: 61));
  });
}
```

- [ ] **Step 6: Implement the screen**

```dart
// lib/features/auth/presentation/screens/verify_email_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../auth_controller.dart';
import '../auth_strings.dart';
import '../auth_validators.dart';
import '../controllers/verify_email_controller.dart';
import '../widgets/auth_scaffold.dart';

const _cooldownSeconds = 60;

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});
  final String email;
  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _timer;
  int _remaining = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _remaining = _cooldownSeconds);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        if (mounted) setState(() => _remaining = 0);
      } else {
        if (mounted) setState(() => _remaining -= 1);
      }
    });
  }

  Future<void> _onCompleted(String code) async {
    final ok = await ref.read(verifyEmailControllerProvider.notifier).verify(code);
    if (!ok || !mounted) return;
    // If a session exists the router redirects to the shell automatically;
    // when there is no session (came from register), go to login.
    final authed = ref.read(authControllerProvider) is AuthAuthenticated;
    if (!authed) context.go('/login');
  }

  Future<void> _resend() async {
    _startCooldown();
    await ref.read(verifyEmailControllerProvider.notifier).resend(widget.email);
  }

  Future<void> _changeEmail() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verifyEmailControllerProvider);
    final counting = _remaining > 0;
    return AuthScaffold(
      leading: AppBackButton(onPressed: _changeEmail),
      children: [
        Text(AuthStrings.verifyTitle, style: AppText.titleScreen),
        const SizedBox(height: AppSpacing.sm),
        Text(AuthStrings.verifySubtitle(widget.email), style: AppText.body),
        const SizedBox(height: AppSpacing.xl),
        OtpCodeInput(onChanged: (_) {}, onCompleted: _onCompleted),
        if (state.isLoading) ...[
          const SizedBox(height: AppSpacing.lg),
          const AppLoader(),
        ],
        if (state.hasError) ...[
          const SizedBox(height: AppSpacing.md),
          Text(failureText(state.error),
              style: AppText.caption.copyWith(color: AppColors.expense)),
        ],
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: counting
              ? Text(AuthStrings.resendIn(_remaining), style: AppText.label)
              : LinkButton(label: AuthStrings.resendCode, onPressed: _resend),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: LinkButton(label: AuthStrings.changeEmail, onPressed: _changeEmail),
        ),
      ],
    );
  }
}
```

- [ ] **Step 7: Point `/verify-email` at the screen (read the query param)**

In `lib/app/router.dart` add the import and change the route to read the `email` query param:
```dart
GoRoute(
  path: '/verify-email',
  builder: (_, state) =>
      VerifyEmailScreen(email: state.uri.queryParameters['email'] ?? ''),
),
```

- [ ] **Step 8: Run screen test + analyze** — PASS (2 tests), clean. (The cooldown test pumps 61s so the periodic timer cancels before teardown — no pending-timer failure.)

- [ ] **Step 9: Commit**

```bash
git add lib/features/auth/presentation/controllers/verify_email_controller.dart lib/features/auth/presentation/screens/verify_email_screen.dart lib/app/router.dart test/features/auth/presentation/verify_email_controller_test.dart test/features/auth/presentation/verify_email_screen_test.dart
git commit -m "feat(auth): Verificar e-mail screen + controller (OTP + resend cooldown)"
```

---

## Task 5: Recuperar senha (forgot password) screen + controller

**Files:**
- Create: `lib/features/auth/presentation/controllers/forgot_password_controller.dart`, `lib/features/auth/presentation/screens/forgot_password_screen.dart`
- Modify: `lib/app/router.dart` (point `/forgot-password` at the screen)
- Test: `test/features/auth/presentation/forgot_password_controller_test.dart`, `test/features/auth/presentation/forgot_password_screen_test.dart`

**Interfaces:**
- Produces `ForgotPasswordController extends Notifier<AsyncValue<void>>` + `forgotPasswordControllerProvider`. `Future<bool> submit(String email)` — calls `authRepository.forgotPassword(email)`; returns `true` on success. (The API always 200s; on a network error it surfaces the `Failure`.)
- Produces `ForgotPasswordScreen` — back button → `/login`; title/subtitle; Email; `Enviar código` CTA; "Lembrou a senha? **Voltar ao login**". On success navigates to `/reset-password?email=<encoded>` (the neutral confirmation copy is shown on the reset screen / via the navigation).

- [ ] **Step 1: Write the failing controller test**

```dart
// test/features/auth/presentation/forgot_password_controller_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/features/auth/data/auth_repository.dart';
import 'package:fluxy_app/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}

ProviderContainer _c(_MockRepo repo) {
  final c = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repo)]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('submit success → true and calls repo.forgotPassword', () async {
    final repo = _MockRepo();
    when(() => repo.forgotPassword('a@b.co')).thenAnswer((_) async {});
    final c = _c(repo);
    expect(await c.read(forgotPasswordControllerProvider.notifier).submit('a@b.co'), true);
    verify(() => repo.forgotPassword('a@b.co')).called(1);
  });

  test('a network error → false + AsyncError', () async {
    final repo = _MockRepo();
    when(() => repo.forgotPassword(any())).thenThrow(const NetworkFailure());
    final c = _c(repo);
    expect(await c.read(forgotPasswordControllerProvider.notifier).submit('a@b.co'), false);
    expect(c.read(forgotPasswordControllerProvider).hasError, true);
  });
}
```

- [ ] **Step 2: Run it — expect FAIL**

- [ ] **Step 3: Implement the controller**

```dart
// lib/features/auth/presentation/controllers/forgot_password_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failure.dart';
import '../../data/auth_repository.dart';

class ForgotPasswordController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> submit(String email) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email);
      if (!ref.mounted) return false;
      state = const AsyncData(null);
      return true;
    } on Failure catch (e, st) {
      if (!ref.mounted) return false;
      state = AsyncError(e, st);
      return false;
    }
  }
}

final forgotPasswordControllerProvider =
    NotifierProvider<ForgotPasswordController, AsyncValue<void>>(
        ForgotPasswordController.new);
```

- [ ] **Step 4: Run it — expect PASS** (2 tests)

- [ ] **Step 5: Write the failing screen test**

```dart
// test/features/auth/presentation/forgot_password_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/features/auth/presentation/auth_strings.dart';
import 'package:fluxy_app/features/auth/presentation/screens/forgot_password_screen.dart';

void main() {
  testWidgets('renders title, email field and CTA', (tester) async {
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ForgotPasswordScreen())));
    expect(find.text(AuthStrings.forgotTitle), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text(AuthStrings.sendCode), findsOneWidget);
  });

  testWidgets('an invalid email blocks submit', (tester) async {
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ForgotPasswordScreen())));
    await tester.enterText(find.byType(TextField), 'nope');
    await tester.tap(find.text(AuthStrings.sendCode));
    await tester.pump();
    expect(find.text(AuthStrings.invalidEmail), findsOneWidget);
  });
}
```

- [ ] **Step 6: Implement the screen**

```dart
// lib/features/auth/presentation/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../auth_strings.dart';
import '../auth_validators.dart';
import '../controllers/forgot_password_controller.dart';
import '../widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  String? _emailError;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final emailError = AuthValidators.email(_email.text);
    setState(() => _emailError = emailError);
    if (emailError != null) return;
    final email = _email.text.trim();
    final ok = await ref.read(forgotPasswordControllerProvider.notifier).submit(email);
    if (ok && mounted) {
      context.go('/reset-password?email=${Uri.encodeComponent(email)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);
    final loading = state.isLoading;
    return AuthScaffold(
      leading: AppBackButton(onPressed: () => context.go('/login')),
      children: [
        Text(AuthStrings.forgotTitle, style: AppText.titleScreen),
        const SizedBox(height: AppSpacing.sm),
        Text(AuthStrings.forgotSubtitle, style: AppText.body),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          label: AuthStrings.email,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
        ),
        if (state.hasError) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(failureText(state.error),
              style: AppText.caption.copyWith(color: AppColors.expense)),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
            label: AuthStrings.sendCode, loading: loading, onPressed: loading ? null : _submit),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: InlineLink(
            leading: AuthStrings.rememberedPassword,
            action: AuthStrings.backToLogin,
            onPressed: () => context.go('/login'),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 7: Point `/forgot-password` at the screen** in `lib/app/router.dart`.

- [ ] **Step 8: Run screen test + analyze** — PASS (2 tests), clean.

- [ ] **Step 9: Commit**

```bash
git add lib/features/auth/presentation/controllers/forgot_password_controller.dart lib/features/auth/presentation/screens/forgot_password_screen.dart lib/app/router.dart test/features/auth/presentation/forgot_password_controller_test.dart test/features/auth/presentation/forgot_password_screen_test.dart
git commit -m "feat(auth): Recuperar senha screen + controller"
```

---

## Task 6: Nova senha (reset password) screen + controller

**Files:**
- Create: `lib/features/auth/presentation/controllers/reset_password_controller.dart`, `lib/features/auth/presentation/screens/reset_password_screen.dart`
- Modify: `lib/app/router.dart` (point `/reset-password` at the screen, reading the `email` query param)
- Test: `test/features/auth/presentation/reset_password_controller_test.dart`, `test/features/auth/presentation/reset_password_screen_test.dart`

**Interfaces:**
- Produces `ResetPasswordController extends Notifier<AsyncValue<void>>` + `resetPasswordControllerProvider`. `Future<bool> submit(String code, String password)` — calls `authRepository.resetPassword(code, password)`; `true`/`AsyncData` on success, `false`/`AsyncError(Failure)` otherwise (a `Failure` from a bad code shows `AuthStrings.invalidCode`).
- Produces `ResetPasswordScreen({String? email})` — back button → `/login`; title/subtitle; `Código` field, `Nova senha`, `Confirmar nova senha`; a live `RequirementRow(AuthStrings.minChars, satisfied: password.length >= 8)`; `Salvar senha` CTA. On success navigates to `/login`.

- [ ] **Step 1: Write the failing controller test**

```dart
// test/features/auth/presentation/reset_password_controller_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/features/auth/data/auth_repository.dart';
import 'package:fluxy_app/features/auth/presentation/auth_strings.dart';
import 'package:fluxy_app/features/auth/presentation/controllers/reset_password_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}

ProviderContainer _c(_MockRepo repo) {
  final c = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repo)]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('submit posts code+password and returns true', () async {
    final repo = _MockRepo();
    when(() => repo.resetPassword('123456', 'newpass12')).thenAnswer((_) async {});
    final c = _c(repo);
    expect(await c.read(resetPasswordControllerProvider.notifier).submit('123456', 'newpass12'),
        true);
    verify(() => repo.resetPassword('123456', 'newpass12')).called(1);
  });

  test('a bad code → false + friendly message', () async {
    final repo = _MockRepo();
    when(() => repo.resetPassword(any(), any())).thenThrow(const ValidationFailure('bad'));
    final c = _c(repo);
    expect(await c.read(resetPasswordControllerProvider.notifier).submit('000000', 'newpass12'),
        false);
    expect((c.read(resetPasswordControllerProvider).error as Failure).message,
        AuthStrings.invalidCode);
  });
}
```

- [ ] **Step 2: Run it — expect FAIL**

- [ ] **Step 3: Implement the controller**

```dart
// lib/features/auth/presentation/controllers/reset_password_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failure.dart';
import '../../data/auth_repository.dart';
import '../auth_strings.dart';

class ResetPasswordController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> submit(String code, String password) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).resetPassword(code, password);
      if (!ref.mounted) return false;
      state = const AsyncData(null);
      return true;
    } on Failure catch (_, st) {
      if (!ref.mounted) return false;
      state = AsyncError(const ValidationFailure(AuthStrings.invalidCode), st);
      return false;
    }
  }
}

final resetPasswordControllerProvider =
    NotifierProvider<ResetPasswordController, AsyncValue<void>>(
        ResetPasswordController.new);
```

- [ ] **Step 4: Run it — expect PASS** (2 tests)

- [ ] **Step 5: Write the failing screen test**

```dart
// test/features/auth/presentation/reset_password_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/widgets/widgets.dart';
import 'package:fluxy_app/features/auth/presentation/auth_strings.dart';
import 'package:fluxy_app/features/auth/presentation/screens/reset_password_screen.dart';

void main() {
  testWidgets('renders code + two password fields and the requirement row', (tester) async {
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ResetPasswordScreen())));
    expect(find.text(AuthStrings.resetTitle), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3)); // code + new + confirm
    expect(find.byType(RequirementRow), findsOneWidget);
  });

  testWidgets('a short password keeps the requirement unsatisfied and blocks submit',
      (tester) async {
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ResetPasswordScreen())));
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '123456');
    await tester.enterText(fields.at(1), 'short'); // < 8
    await tester.enterText(fields.at(2), 'short');
    await tester.pump();
    await tester.tap(find.text(AuthStrings.savePassword));
    await tester.pump();
    expect(find.text(AuthStrings.shortPassword), findsOneWidget);
  });
}
```

- [ ] **Step 6: Implement the screen**

```dart
// lib/features/auth/presentation/screens/reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../auth_strings.dart';
import '../auth_validators.dart';
import '../controllers/reset_password_controller.dart';
import '../widgets/auth_scaffold.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.email});
  final String? email;
  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _codeErr, _passwordErr, _confirmErr;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {})); // live RequirementRow
  }

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final codeErr = _code.text.trim().length == 6 ? null : AuthStrings.invalidCode;
    final passwordErr = AuthValidators.password(_password.text);
    final confirmErr = AuthValidators.confirm(_confirm.text, _password.text);
    setState(() {
      _codeErr = codeErr;
      _passwordErr = passwordErr;
      _confirmErr = confirmErr;
    });
    if (codeErr != null || passwordErr != null || confirmErr != null) return;
    final ok = await ref
        .read(resetPasswordControllerProvider.notifier)
        .submit(_code.text.trim(), _password.text);
    if (ok && mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordControllerProvider);
    final loading = state.isLoading;
    return AuthScaffold(
      leading: AppBackButton(onPressed: () => context.go('/login')),
      children: [
        Text(AuthStrings.resetTitle, style: AppText.titleScreen),
        const SizedBox(height: AppSpacing.sm),
        Text(AuthStrings.resetSubtitle, style: AppText.body),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          label: AuthStrings.code,
          controller: _code,
          keyboardType: TextInputType.number,
          errorText: _codeErr,
        ),
        const SizedBox(height: AppSpacing.md),
        PasswordField(
            label: AuthStrings.newPassword, controller: _password, errorText: _passwordErr),
        const SizedBox(height: AppSpacing.sm),
        RequirementRow(
            text: AuthStrings.minChars, satisfied: _password.text.length >= 8),
        const SizedBox(height: AppSpacing.md),
        PasswordField(
            label: AuthStrings.confirmNewPassword,
            controller: _confirm,
            errorText: _confirmErr),
        if (state.hasError) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(failureText(state.error),
              style: AppText.caption.copyWith(color: AppColors.expense)),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
            label: AuthStrings.savePassword, loading: loading, onPressed: loading ? null : _submit),
      ],
    );
  }
}
```

- [ ] **Step 7: Point `/reset-password` at the screen (read the query param)** in `lib/app/router.dart`:
```dart
GoRoute(
  path: '/reset-password',
  builder: (_, state) =>
      ResetPasswordScreen(email: state.uri.queryParameters['email']),
),
```

- [ ] **Step 8: Run screen test + analyze** — PASS (2 tests), clean.

- [ ] **Step 9: Commit**

```bash
git add lib/features/auth/presentation/controllers/reset_password_controller.dart lib/features/auth/presentation/screens/reset_password_screen.dart lib/app/router.dart test/features/auth/presentation/reset_password_controller_test.dart test/features/auth/presentation/reset_password_screen_test.dart
git commit -m "feat(auth): Nova senha screen + controller"
```

---

## Task 7: Routing integration cleanup + full-flow smoke test

**Files:**
- Modify: `lib/app/router.dart` (remove the now-unused `LoginPlaceholder`; confirm all 5 auth routes point at real screens; `PlaceholderScreen` stays only for the shell tabs)
- Modify: `lib/app/placeholder_screens.dart` (delete `LoginPlaceholder`; keep `PlaceholderScreen` for the four shell tabs)
- Test: `test/app/auth_screens_routing_test.dart` (new)

**Interfaces:** none new — final wiring + an end-to-end widget assertion that the real screens render at their routes.

- [ ] **Step 1: Write the failing test**

```dart
// test/app/auth_screens_routing_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/app/router.dart';
import 'package:fluxy_app/core/session/session_status.dart';
import 'package:fluxy_app/features/auth/presentation/auth_strings.dart';
import 'package:fluxy_app/features/auth/presentation/screens/login_screen.dart';
import 'package:fluxy_app/features/auth/presentation/screens/register_screen.dart';

void main() {
  testWidgets('unauthenticated boot renders the real LoginScreen at /login',
      (tester) async {
    final c = ProviderContainer(overrides: [
      sessionStatusProvider.overrideWith((ref) => SessionStatus.unauthenticated),
    ]);
    addTearDown(c.dispose);
    final router = c.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(AuthStrings.loginTitle), findsOneWidget);

    // Navigate to register via the footer link.
    await tester.tap(find.text(AuthStrings.signUp));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run it — expect FAIL** (or pass partially; ensure it fails before the cleanup if `LoginScreen` isn't yet the `/login` builder — it is, from Task 2, so this test should already pass for the first assertion; it primarily guards the integration).

Run: `flutter test test/app/auth_screens_routing_test.dart`

- [ ] **Step 3: Remove `LoginPlaceholder`**

In `lib/app/placeholder_screens.dart`, delete the `LoginPlaceholder` class (keep `PlaceholderScreen`). In `lib/app/router.dart`, ensure no `LoginPlaceholder` reference remains (the `/login` route already uses `LoginScreen` from Task 2). Confirm the four shell routes still use `PlaceholderScreen`.

- [ ] **Step 4: Full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: ALL pass; analyzer "No issues found!". No pending-timer or overflow errors.

- [ ] **Step 5: Commit**

```bash
git add lib/app/router.dart lib/app/placeholder_screens.dart test/app/auth_screens_routing_test.dart
git commit -m "feat(auth): wire real auth screens into routing; drop LoginPlaceholder"
```

---

## Self-Review

**Spec coverage (spec 02 §7 screens + §8 validation + acceptance 7–9, 11):**
- Login (§7.1) → T2; Cadastro (§7.2, → verify with email prefilled, AC7) → T3; Verificar e-mail (§7.3, OtpCodeInput auto-submit AC7, resend ~60s cooldown AC8) → T4; Recuperar senha (§7.4, neutral) → T5; Nova senha (§7.5, code + RequirementRow) → T6; routing integration + smoke (AC11) → T7.
- Validation (§8) mirrors the API: email regex/≤320, password 8–200, name 1–100, OTP 6 → T1 (unit-tested) used by every screen.
- Friendly errors via `failureText`; login 401 → "E-mail ou senha inválidos" (T2). Forgot-password neutrality (AC9): the screen never reveals account existence — it always navigates forward to reset on a 2xx (the API always 200s).
- **Acceptance 7** (register→verify, email prefilled, OTP pastes+auto-submits): register navigates `/verify-email?email=`; `OtpCodeInput.onCompleted` auto-submits (paste path proven in the design-system OTP tests). **Acceptance 8** (resend ~60s cooldown): T4 timer. **Acceptance 11** (smoke tests in loading/error/success): each screen has widget tests; controllers have unit tests for success + error.

**Placeholder scan:** every code step has complete, compiling code + a behaviour test. No TBD/TODO.

**Type consistency:** all controllers are `Notifier<AsyncValue<void>>` with `submit`/`verify` returning `Future<bool>`; screens read `state.isLoading`/`state.hasError`/`failureText(state.error)`. `AuthStrings`/`AuthValidators`/`failureText`/`AuthScaffold` (T1) are consumed unchanged by T2–T6. Engine names (`authControllerProvider`, `authRepositoryProvider`, `AuthController.login/register/refreshUser/logout`, `AuthRepository.verifyEmail/resendVerification/forgotPassword/resetPassword`, `RegisterInput`, `AuthAuthenticated`) match Part 1 exactly. Router route paths match the Part-1 public set.

**Navigation model:** login/verify rely on the Part-1 `refreshListenable` auto-redirect (no manual nav on success); register→verify, forgot→reset, reset→login, change-email→login navigate explicitly via `context.go`. Email is passed as a URL-encoded `email` query param and read via `state.uri.queryParameters`.

**Layering:** screens/controllers live in `presentation/`; they consume `authControllerProvider`/`authRepositoryProvider` (no dio, no direct API). The only `app/` change is route builders. Engine (`domain`/`data`/`auth_controller`) is untouched.

**Carry-forwards honored:** login 401 friendly message (engine review carry-forward) applied in T2. (The design-system OTP "clear-on-focus / debounce duplicate onCompleted" refinement is a `core/widgets` concern; `onCompleted` here triggers an idempotent `verify` guarded by `AsyncLoading`, so a duplicate fire re-submits the same code harmlessly — acceptable for v1; a deeper OtpCodeInput fix stays a design-system follow-up.)
