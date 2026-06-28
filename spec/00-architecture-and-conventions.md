# 00 — Architecture & Conventions

**Status:** Draft · **Depends on:** none · **Date:** 2026-06-26

This spec defines the cross-cutting foundation every feature spec builds on. It is
not a user-facing feature; it is the system design. Implement it as the first
milestone (the "walking skeleton") so that spec 01 (design system) and spec 02
(auth) can plug into it.

> **Visual source of truth:** the app's look is defined by the Claude Design file
> `Fluxy.dc.html` (claude.ai project `9f389760-cc12-4ab5-8d40-1e1c79c7d0c0`),
> distilled into [`01-design-system.md`](./01-design-system.md). This spec covers
> *structure*; spec 01 covers *appearance*.

---

## 1. Goal

A clean, testable client architecture for the Fluxy API: layered structure, a typed
networking layer with automatic JWT refresh, a money value-type, declarative
auth-guarded navigation with a bottom-tab shell, a single dark theme, and a
TDD-friendly provider setup.

## 2. Tech stack & dependencies

`pubspec.yaml` additions (versions resolved at implementation time against Dart SDK
`^3.12.1`; pin in the lockfile):

```yaml
dependencies:
  flutter_riverpod        # state management + DI
  riverpod_annotation     # codegen providers
  dio                     # HTTP client + interceptors
  go_router               # declarative navigation
  freezed_annotation      # immutable models
  json_annotation         # JSON (de)serialization
  flutter_secure_storage  # token storage (Keychain / Keystore)
  intl                    # pt-BR date + BRL currency formatting
  google_fonts            # Oswald + Fjalla One (bundleable later)

dev_dependencies:
  build_runner
  riverpod_generator
  freezed
  json_serializable
  mocktail                # mocking in tests
  # custom_lint + riverpod_lint  # optional, recommended
```

Codegen: `dart run build_runner build --delete-conflicting-outputs`.

> **Toolchain decisions made during implementation (keep this honest):**
> - **Fonts are bundled** (Oswald + Fjalla One as `assets/fonts/`); `google_fonts`
>   was dropped (design-system Part 1).
> - **Riverpod providers are hand-written** (`Notifier`/`NotifierProvider`/`Provider`),
>   so `riverpod_generator` + `riverpod_annotation` were **removed**. Only `freezed`
>   + `json_serializable` use codegen (models/DTOs); generated `*.freezed.dart` /
>   `*.g.dart` are committed.
> - **`freezed` is pinned to stable `^3.2.5`** (not the 3.2.6 pre-release).
>   ⚠️ **Caveat:** `freezed 3.2.5` needs `analyzer <11`, but `riverpod_generator 4.x`
>   needs `analyzer ^12`. Re-adding `@riverpod` codegen for a future feature would
>   drag `freezed` back to the `3.2.6-dev` pre-release. If a feature truly needs
>   `@riverpod`, reconcile this analyzer-version conflict first (or keep hand-writing
>   providers).

## 3. Layered project structure

```
lib/
  main.dart                       # runApp(ProviderScope(child: FluxyApp()))
  app/
    app.dart                      # FluxyApp: MaterialApp.router + dark theme + router
    router.dart                   # GoRouter + auth-guard redirect + bottom-nav shell
    shell.dart                    # ShellRoute scaffold: bottom nav + FAB
  core/
    config/        env.dart       # AppConfig: baseUrl, currencyCode, locale
    network/       dio_client.dart, auth_interceptor.dart, api_exception.dart
    error/         failure.dart   # sealed Failure (see §5)
    storage/       token_storage.dart
    money/         money.dart      # value type over integer cents (see §4)
    time/          api_date.dart   # YYYY-MM-DD <-> DateTime helpers (pt-BR display)
    theme/         tokens.dart, app_theme.dart   # design-system tokens (spec 01)
    formatting/    formatters.dart # BRL currency + pt-BR date display
    widgets/       # shared components from spec 01 (buttons, fields, timeline, ...)
  features/
    <feature>/
      data/        # <feature>_api.dart, <feature>_repository.dart, dtos
      domain/      # immutable models (freezed)
      presentation/# screens, controllers (notifiers), widgets
```

**Dependency rule:** `presentation → domain → data`. Only `data/*_repository`
calls `data/*_api`; only `data/*_api` calls `dio`. UI never imports dio or touches
DTOs — repositories return domain models.

## 4. Money handling (critical)

The API uses integer **`amountCents`**. The client MUST never represent money as a
`double`.

- `Money` (freezed) wraps `int cents`. `Money.fromMajor(num major)` →
  `(major * 100).round()`. Accessors: `int cents`, `double get major` (display
  only), `bool get isNegative`.
- **Currency is BRL, locale pt-BR.** Display via
  `NumberFormat.currency(locale: 'pt_BR', symbol: r'R$')` → `R$ 3.240,00`.
  `AppConfig.currencyCode = 'BRL'`, `AppConfig.locale = 'pt_BR'`.
- The API has **no currency field** — BRL is an app-wide constant assumption.
- **Sign convention:** stored `amountCents` is a **positive magnitude**; the sign
  shown (`+` green income / `−` coral expense) is derived from `kind`, never stored
  negative. Repositories send positive `amountCents`.

## 5. Error model

The API documents only success bodies (no error schemas). Map by HTTP status with
best-effort message extraction. `sealed class Failure`:

| Variant | Trigger | UI treatment |
|---------|---------|--------------|
| `NetworkFailure` | dio connection/timeout | "Sem conexão", retry |
| `UnauthorizedFailure` | 401 after refresh failed | force logout → login |
| `ForbiddenFailure` | 403 | "Acesso negado" |
| `NotFoundFailure` | 404 | feature-specific empty/not-found |
| `ValidationFailure(fields, message)` | 400/422 | inline field errors + message |
| `ConflictFailure(message)` | 409 | inline message (e.g. duplicate) |
| `ServerFailure` | 5xx | "Algo deu errado", retry |
| `UnknownFailure` | anything else | generic message |

Message extraction order from the JSON body: `message` → `error` → `detail` →
status reason. `ValidationFailure.fields` parsed defensively from `{field:[msgs]}`
or `errors` if present, else empty. Repositories catch `DioException`, convert via
`ApiException.toFailure()`, and **throw `Failure`**; controllers expose
`AsyncValue` so `error` carries the `Failure`.

## 6. Networking & auth lifecycle

- One `Dio`, `baseUrl = AppConfig.baseUrl`
  (`https://3rgdjd69sa.execute-api.us-east-1.amazonaws.com`), JSON, sane timeouts.
- `AuthInterceptor`:
  1. `onRequest`: for authenticated routes, attach `Authorization: Bearer <accessToken>`.
  2. `onError` 401: attempt a **single** `/auth/refresh` with the stored
     `refreshToken`, serialized through one lock so concurrent 401s trigger one
     refresh. On success persist the rotated tokens and retry once. On failure,
     clear tokens, emit a global "session expired" signal, surface
     `UnauthorizedFailure`.
- `/auth/*` (except `change-password`) are **public** — no token attach, no refresh.
- `/auth/refresh` rotates **both** tokens; always persist both.

## 7. Routing, navigation & shell

`go_router` with a `redirect` reading auth state (spec 02):

- Unauthenticated → `/login`. Public routes: `/login`, `/register`,
  `/forgot-password`, `/reset-password`, `/verify-email`.
- Authenticated + `emailVerified == false` → `/verify-email`.
- Authenticated + verified → **bottom-tab shell** (`ShellRoute`):

| Tab | Route | Screen |
|-----|-------|--------|
| Início | `/` | dashboard summary (spec 05) + recent transactions timeline (spec 04) |
| Transações | `/transactions` | full list, filters, pagination (spec 04) |
| Categorias | `/categories` | manage categories (spec 03) |
| Conta | `/account` | profile + settings (spec 06) |

- A central **squircle FAB** (on Início & Transações) opens the **"Nova transação"
  bottom sheet** (spec 04). Bottom nav + FAB styling per spec 01.
- Router refreshes on auth changes via a `refreshListenable` bridged from the auth
  controller. Cold start shows a splash while `AuthState == Unknown`.

## 8. Theming

- **Dark-only** for v1 (a light variant is a deferred follow-up). One `ThemeData`
  built from the design-system tokens in [`01-design-system.md`](./01-design-system.md).
- `core/theme/tokens.dart` holds the raw color/spacing/radii/type constants;
  `core/theme/app_theme.dart` assembles `ColorScheme.dark`, `TextTheme`
  (Oswald + Fjalla One), and component themes.
- Semantic colors (income `#3fd68c`, expense `#f0635a`, surfaces, hairline) are
  defined once and reused — **no hardcoded colors in feature code**.

## 9. Localization & copy

- **Single locale: pt-BR.** All user-facing copy is Portuguese, matching the
  design. Centralize strings in a `core/strings` (or per-feature `strings.dart`)
  file for maintainability — not full `.arb` i18n (out of scope for v1).
- Dates display in pt-BR (`21 jun`, `Hoje · 21 jun`); the API exchanges
  `YYYY-MM-DD` for `occurredAt`.

## 10. Testing strategy (TDD)

- **Repository unit tests:** mock `Dio` (mocktail); assert request shape (path,
  method, body, query) and response→model / error→`Failure` mapping.
- **Controller tests:** mock repositories; assert `AsyncValue` transitions and any
  optimistic-update rollback.
- **Widget tests:** pump screens with overridden providers; assert loading / empty
  / error / data states.
- Each feature spec's "Acceptance criteria" is the source of test cases.

## 11. Configuration & environments

- `AppConfig` from `--dart-define` with defaults: `FLUXY_BASE_URL` (the AWS URL),
  `FLUXY_CURRENCY=BRL`, `FLUXY_LOCALE=pt_BR`.
- No secrets in the client. Tokens only in platform secure storage.

## 12. Acceptance criteria (foundation milestone)

1. App boots into `ProviderScope`; `flutter run` shows the login screen (placeholder
   acceptable until spec 02) instead of the counter demo, in the dark theme.
2. `Dio` configured with base URL + `AuthInterceptor` registered.
3. `TokenStorage` writes/reads/clears tokens via secure storage (unit-tested with a fake).
4. `Money` round-trips cents and formats as `R$ 3.240,00` (pt-BR); `fromMajor`
   rounding unit-tested; no `double` storage.
5. `Failure` mapping unit-tested for 401/4xx/5xx/timeout.
6. `go_router` redirect: unauthenticated → `/login`; verified → shell with the four
   tabs; unverified → `/verify-email` (tested with overridden auth provider).
7. Dark `ThemeData` loads Oswald + Fjalla One; `build_runner` generates cleanly;
   `flutter analyze` is clean.
