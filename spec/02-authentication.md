# 02 — Authentication

**Status:** Draft · **Depends on:** 00, 01 · **Date:** 2026-06-26

The full account lifecycle in pt-BR: cadastro → verificação de e-mail (código OTP)
→ login → sessão persistente via refresh → recuperação de senha (código OTP) →
sair. Owns the app's **auth state**, which the router (spec 00 §7) consumes.

Maps to design screens **01 Login · 02 Cadastro · 03 Recuperar senha · 04 Nova
senha** in `Fluxy.dc.html`, plus a **new verify-email OTP screen** built from
spec 01 components.

---

## 1. Goal

Let a user create and access their Fluxy account securely and stay signed in across
launches, with email verification and password recovery handled via **OTP codes**
(no deep-linking / Universal Links on mobile).

## 2. API surface (`/auth`, public unless noted)

| Method/Path | Body | Success | Notes |
|-------------|------|---------|-------|
| `POST /auth/register` | `{email, firstName, lastName, password}` | `201 {message}` | pwd 8–200; email ≤320; names 1–100 |
| `POST /auth/verify-email` | `{token}` | `200 {message}` | `token` = OTP **code** typed by user |
| `POST /auth/verify-email/resend` | `{email}` | `200 {message}` | re-sends a fresh code |
| `POST /auth/login` | `{email, password}` | `200 {accessToken, refreshToken, tokenType:"Bearer", expiresIn}` | |
| `POST /auth/refresh` | `{refreshToken}` | `200 {…tokens…}` | rotates both |
| `POST /auth/logout` | `{refreshToken}` | `200 {message}` | invalidates refresh token |
| `POST /auth/forgot-password` | `{email}` | `200 {message}` | always 200 (no enumeration) |
| `POST /auth/reset-password` | `{token, password}` | `200 {message}` | `token` = OTP **code** |
| `POST /auth/change-password` | `{currentPassword, newPassword}` | `200 {message}` | **auth** (spec 06) |
| `GET /me` | — | `200 {id, email, firstName, lastName, emailVerified, createdAt}` | **auth** |

> `expiresIn` is a **string** — parse defensively (seconds if numeric, else rely on
> 401-driven refresh).

## 3. Email flows: OTP codes (decided)

Both **verification** and **password reset** use emailed **numeric codes** (assumed
6 digits, backend-controlled), entered with the `OtpCodeInput` component.

- `verify-email` and `reset-password` send `{token: <code-as-string>}`.
- **Backend dependency (must hold, app-side has zero deep-link config):** the
  verification, resend, and password-reset emails contain a numeric code — not a
  link. No Universal Links / App Links / custom schemes.
- The design's "Recuperar senha" copy ("enviaremos um link") is **adapted** to
  "enviaremos um código"; the "Nova senha" screen gains a **code field**.

## 4. Domain models (`features/auth/domain`)

```text
AuthTokens { String accessToken; String refreshToken; String tokenType; String? expiresIn; }
AuthUser  { String id; String email; String firstName; String lastName;
            bool emailVerified; DateTime createdAt; }
AuthState = Unknown | Unauthenticated | Authenticated(AuthUser user)
```

`AuthUser` is shared with spec 06. `Authenticated` with `emailVerified == false`
drives the verify gate in routing.

## 5. Data layer (`features/auth/data`)

- `AuthApi` — thin dio wrapper, one method per endpoint, returns DTOs.
- `AuthRepository`:
  - `register(RegisterInput)`
  - `verifyEmail(String code)` → posts `{token: code}`
  - `resendVerification(String email)`
  - `login(String email, String password)` → persists tokens via `TokenStorage`
  - `refresh()` → reads stored refresh token, persists rotated pair (also used by `AuthInterceptor`)
  - `logout()` → calls `/auth/logout` then clears storage (clear locally even if the call fails)
  - `forgotPassword(String email)`
  - `resetPassword(String code, String password)` → posts `{token: code, password}`
  - `me()`
- Errors → `Failure` (spec 00 §5). Friendly messages: bad login → "E-mail ou senha
  inválidos"; wrong/expired code → "Código inválido ou expirado".

## 6. State & controllers (`features/auth/presentation`)

- `authControllerProvider` (Notifier) holds `AuthState`. On start: `Unknown` → read
  tokens → `me()` → `Authenticated` / `Unauthenticated`. Exposes `login`,
  `register`, `logout`, `refreshUser`.
- `authStateProvider` (derived) for the router redirect + `refreshListenable`.
- Per-screen form controllers (`AsyncValue<void>`): login, register, verify,
  forgot, reset — track in-flight + error.
- Global listener reacts to the interceptor "session expired" signal → set
  `Unauthenticated`, clear storage, one-time toast "Sua sessão expirou".

## 7. Screens / UX (pt-BR, design-faithful)

All screens dark, Oswald copy, `PrimaryButton` CTAs, `AppTextField`s per spec 01.

1. **Login** (`/login`) — design 01. Logo tile; "Bem-vindo de volta" (`titleScreen`)
   + "Entre para acompanhar suas finanças."; Email + Senha fields; "Esqueci minha
   senha" (`LinkButton`, right-aligned); **Entrar** CTA; footer "Não tem conta?
   **Cadastre-se**".
2. **Cadastro** (`/register`) — design 02. "Criar conta" + "Comece a organizar seu
   dinheiro hoje."; **Nome** (firstName), **Sobrenome** (lastName), Email, Senha,
   Confirmar senha; **Cadastrar** CTA; footer "Já tem conta? **Entrar**". On `201`
   → navigate to **Verificar e-mail** with email prefilled.
   - (Design draws a single "Nome"; spec uses firstName + lastName to match the API.)
3. **Verificar e-mail** (`/verify-email`) — **new screen**, spec 01 style.
   "Confirme seu e-mail" + "Digite o código de 6 dígitos que enviamos para
   {email}."; `OtpCodeInput` (auto-submit at 6); **Reenviar código** (`LinkButton`)
   with ~60s cooldown countdown; on success `refreshUser()` → router admits to the
   shell. Invalid → "Código inválido ou expirado". "Trocar e-mail" → sign out.
4. **Recuperar senha** (`/forgot-password`) — design 03 (copy adapted). BackButton;
   "Recuperar senha" + "Informe seu e-mail e enviaremos um **código** para
   redefinir sua senha."; Email; **Enviar código** CTA → navigate to Nova senha;
   neutral confirmation regardless of outcome (no enumeration); "Lembrou a senha?
   **Voltar ao login**".
5. **Nova senha** (`/reset-password`) — design 04 (+ code field). BackButton; "Nova
   senha" + "Crie uma nova senha para sua conta."; **Código** (`OtpCodeInput` or
   text), **Nova senha**, **Confirmar nova senha**; `RequirementRow` "Mínimo de 8
   caracteres"; **Salvar senha** CTA → success → back to Login.

No raw exception text shown; all errors via the `Failure` → pt-BR message map.

## 8. Validation (client mirrors the API, not the web's stricter zod)

- Email: `^[^@\s]+@[^@\s]+\.[^@\s]+$`, ≤320.
- Password: **8–200** (the web's `max(10)` is ignored). Register/reset confirm match.
- firstName / lastName: **1–100**, trimmed, non-empty.
- OTP: digits; submit at 6 (API is source of truth).

## 9. Session persistence & security

- Tokens only in `flutter_secure_storage`; never logged, never in prefs.
- Cold start restores session before painting the shell (splash during `Unknown`).
- `logout` clears tokens, best-effort hits the API, routes to `/login`.

## 10. Edge cases

- Refresh invalid at startup → `Unauthenticated`, silent.
- 401 mid-session → interceptor refresh; failure → forced logout + one-time message.
- Email already registered → inline API message ("E-mail já cadastrado" if provided).
- Verify when already verified → treat as success.
- Resend spam → blocked by cooldown; API rate-limit surfaced as its mapped message.
- Offline submit → `NetworkFailure` banner + retry; form keeps input.

## 11. Acceptance criteria

1. `login` posts `{email,password}`, persists both tokens, returns `AuthTokens` (mocked dio).
2. Bad credentials → friendly `Failure` (no stack/JSON leak).
3. `verifyEmail(code)` posts `{token: code}`; success triggers `me()` refresh.
4. `resetPassword(code, pwd)` posts `{token: code, password: pwd}`.
5. `refresh()` persists the **rotated** pair; reused by the interceptor.
6. Start: valid tokens → shell; none → `/login`; `emailVerified==false` → `/verify-email`.
7. Register success → verify screen, email prefilled; `OtpCodeInput` pastes + auto-submits.
8. Resend respects the ~60s cooldown.
9. Forgot-password shows the neutral message regardless of API outcome.
10. Logout clears secure storage and returns to `/login` even if the call fails.
11. Widget smoke tests: login/register/verify/forgot/reset in loading/error/success.
