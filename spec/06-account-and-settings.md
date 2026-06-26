# 06 — Account & Settings

**Status:** Draft · **Depends on:** 00, 01, 02 · **Date:** 2026-06-26

The **Conta** tab: profile from `GET /me`, change password, and sign out. No design
screen exists; build from spec 01 components in the established dark style.

---

## 1. Goal

Let the user view their account, change their password, and securely sign out.

## 2. API surface (authenticated)

| Method/Path | Body | Success |
|-------------|------|---------|
| `GET /me` | — | `200 {id, email, firstName, lastName, emailVerified, createdAt}` |
| `POST /auth/change-password` | `{currentPassword, newPassword}` | `200 {message}` |
| `POST /auth/logout` | `{refreshToken}` | `200 {message}` |

`GET /me` and the auth user model are shared with spec 02 (`AuthUser`); the logout
flow reuses `AuthRepository.logout()`.

## 3. State & controllers (`features/account/presentation`)

- Reads the current `AuthUser` from `authControllerProvider` (spec 02); a pull-to-
  refresh calls `refreshUser()` (`GET /me`).
- `changePasswordControllerProvider` → `AsyncValue<void>` for the change-password sheet.
- Logout delegates to the auth controller (clears storage, routes to `/login`).

## 4. Screens / UX (pt-BR, spec 01 components)

1. **Conta (profile)** — header: `Avatar` (initials from first/last name), full name
   (`titleSection`), email (`body`, muted), an "E-mail verificado" `RequirementRow`
   (check if `emailVerified`, else a "Verificar e-mail" action). A settings list:
   - **Alterar senha** → opens the change-password sheet.
   - **Tema:** "Escuro" (read-only note — dark-only in v1).
   - **Sair** → confirmation → logout.
2. **Alterar senha** (`BottomSheetScaffold`) — **Senha atual**, **Nova senha**,
   **Confirmar nova senha** (`PasswordField`s); `RequirementRow` "Mínimo de 8
   caracteres"; **Salvar** CTA → `POST /auth/change-password`. On success: toast
   "Senha alterada" and close.

## 5. Validation

- currentPassword: non-empty. newPassword: 8–200 and ≠ currentPassword; confirm match.
- Wrong current password → API error surfaced inline ("Senha atual incorreta").

## 6. Edge cases

- Change-password while offline → `NetworkFailure` banner + retry, inputs preserved.
- Logout when the API call fails → still clears local storage and routes to login.
- `emailVerified == false` here → offer the verify flow (spec 02) rather than blocking.

## 7. Acceptance criteria

1. Conta renders name, email, and verified state from `AuthUser`.
2. Change-password posts `{currentPassword, newPassword}`; wrong current → inline
   "Senha atual incorreta" (mocked dio).
3. New password validation (length, ≠ current, confirm match) enforced client-side.
4. Sair confirms, calls logout, clears secure storage, and returns to `/login` even
   if the network call fails.
5. Pull-to-refresh re-fetches `GET /me`.
