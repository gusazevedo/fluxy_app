# Fluxy App — Specifications

Spec-driven development for the **Fluxy** personal-finance Flutter client.
Every feature is specified here _before_ implementation. Build the features in the
order below; each spec lists its dependencies.

- **API:** Fluxy API (OpenAPI 3.0.3, JWT bearer auth)
- **API docs:** `https://3rgdjd69sa.execute-api.us-east-1.amazonaws.com/docs`
- **API spec JSON:** `https://3rgdjd69sa.execute-api.us-east-1.amazonaws.com/docs/json`
- **Visual design (source of truth):** Claude Design `Fluxy.dc.html` — claude.ai
  project `9f389760-cc12-4ab5-8d40-1e1c79c7d0c0` (owner Gus), read via the
  `claude_design` MCP. Distilled into [`01-design-system.md`](./01-design-system.md).
- **Client stack:** Flutter · Riverpod (+codegen) · dio · go_router · freezed ·
  flutter_secure_storage · intl · google_fonts

## Product decisions

- **Locale/currency:** pt-BR + BRL (`R$ 3.240,00`); Portuguese copy throughout.
- **Theme:** dark-only (v1); fonts Oswald (UI) + Fjalla One (amounts).
- **Email flows:** OTP **codes** for verification and password reset (no deep-linking).
- **Navigation:** bottom tabs — Início · Transações · Categorias · Conta; FAB → "Nova transação".
- **Data:** online-only + light cache. **Money:** integer cents end-to-end.

## Build order

| # | Spec | Depends on | Status |
|---|------|------------|--------|
| 00 | [Architecture & Conventions](./00-architecture-and-conventions.md) | — | Draft |
| 01 | [Design System](./01-design-system.md) | 00 | Draft |
| 02 | [Authentication](./02-authentication.md) | 00, 01 | Draft |
| 03 | [Categories](./03-categories.md) | 00, 01, 02 | Draft |
| 04 | [Transactions](./04-transactions.md) | 00, 01, 02, 03 | Draft |
| 05 | [Reports (Dashboard summary)](./05-reports.md) | 00, 01, 02, 03, 04 | Draft |
| 06 | [Account & Settings](./06-account-and-settings.md) | 00, 01, 02 | Draft |

## How to use these specs

1. Read `00-architecture-and-conventions.md` (structure) and `01-design-system.md`
   (appearance) first — every feature spec assumes both.
2. Implement features in build order. Each feature spec is self-contained for its
   slice: API surface, models, repository, controllers, screens, states, edge
   cases, and acceptance criteria.
3. Follow TDD (spec 00 §10). Write the failing test from the acceptance criteria,
   then implement.

## Conventions

- **MUST / SHOULD / MAY** carry RFC-2119 weight.
- API field names are quoted exactly as the API uses them (e.g. `amountCents`).
- Money is **always** integer cents end-to-end (spec 00 §4); BRL formatting.
- "Controller" = a Riverpod notifier exposing state to the UI.
- "Repository" = the only layer permitted to call the API client.
- UI composes spec 01 components; no raw colors/fonts/paddings in feature code.
