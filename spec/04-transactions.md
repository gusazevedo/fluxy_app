# 04 — Transactions

**Status:** Draft · **Depends on:** 00, 01, 02, 03 · **Date:** 2026-06-26

The core loop: register income/expense transactions and browse them on a date-grouped
git-graph timeline. Maps to design screen **05 Principal** (the timeline) and **06
Nova transação** (the bottom sheet). The recent timeline also appears on **Início**;
the full filterable list is the **Transações** tab.

---

## 1. Goal

Let the user create, edit, and delete transactions and browse them efficiently,
classified by category and kind, with the designed timeline presentation.

## 2. API surface (all authenticated)

| Method/Path | Query / Body | Success |
|-------------|--------------|---------|
| `GET /transactions` | `?from&to` (YYYY-MM-DD) `&categoryId&kind&limit&cursor` | `200 {items:[Transaction], nextCursor: string\|null}` |
| `POST /transactions` | `{amountCents, kind, categoryId, occurredAt, description?}` | `201 Transaction` |
| `GET /transactions/{id}` | — | `200 Transaction` |
| `PATCH /transactions/{id}` | any of `{amountCents, kind, categoryId, occurredAt, description}` | `200 Transaction` |
| `DELETE /transactions/{id}` | — | `200` (no body) |

`Transaction = {id, amountCents:int, kind:"expense"|"income", categoryId,
description: string|null, occurredAt: "YYYY-MM-DD", createdAt}`.

- **Pagination is cursor-based:** pass `cursor` = previous `nextCursor`; stop when
  `nextCursor == null`. Use `limit` for page size (e.g. 20).
- `amountCents` is a **positive** integer; `kind` carries the sign (spec 00 §4).

## 3. Domain model (`features/transactions/domain`)

```text
Transaction {
  String id; Money amount; CategoryKind kind; String categoryId;
  String? description; DateTime occurredAt; DateTime createdAt;
}
TransactionsPage { List<Transaction> items; String? nextCursor; }
TransactionFilter { DateTime? from; DateTime? to; String? categoryId; CategoryKind? kind; }
```

`amount` is `Money` over `amountCents`. `occurredAt` parsed from `YYYY-MM-DD` via
`core/time/api_date.dart`.

## 4. Data layer

- `TransactionsApi` — endpoint wrappers; serializes `occurredAt` as `YYYY-MM-DD`.
- `TransactionsRepository`:
  - `list(TransactionFilter filter, {int limit = 20, String? cursor})` → `TransactionsPage`
  - `create(NewTransaction)` / `update(String id, TransactionPatch)` / `delete(String id)`
  - `get(String id)`
- Category names for display are resolved from the categories cache (spec 03); the
  transaction only stores `categoryId`.

## 5. State & controllers (`features/transactions/presentation`)

- `transactionsListControllerProvider(filter)` → an infinite-scroll
  `AsyncValue<List<Transaction>>` that accumulates pages via `nextCursor` and
  exposes `loadMore()` / `refresh()`.
- `recentTransactionsProvider` → first page, unfiltered, for the Início timeline.
- `transactionFormControllerProvider` → drives create/edit (`AsyncValue<void>`).
- Create/update/delete **invalidate** the list + the reports summary (spec 05) so
  totals and the timeline refresh. Optimistic insert/remove with rollback.

## 6. Screens / UX (pt-BR, design-faithful)

### 6.1 Início timeline (recent) — design 05
Greeting header ("Olá, {firstName}" + `Avatar`), `BalanceHeroCard` +
Despesas/Receitas `StatCard`s (spec 05), then "Transações" (`titleList`) and the
**`TransactionTimeline`** of recent items grouped by day (date anchors `HOJE · 21
JUN`, `20 JUN`, …). Each item is a `TransactionRow` with the timeline node colored
by kind. Squircle **`Fab`** (bottom-right) opens the Nova transação sheet.

### 6.2 Transações (full list) — Transações tab
Same `TransactionTimeline`, plus a **filter bar**: kind (`SegmentedToggle` +
"Todas"), category (`SelectField` from spec 03), and a date-range chip
(`from`/`to`). **Cursor pagination** drives infinite scroll (loader row at the
bottom; "Fim" when `nextCursor == null`). Empty/error via spec 01 async views.
Row tap → edit sheet; swipe / long-press → Excluir (confirm).

### 6.3 Nova transação / Editar (bottom sheet) — design 06
`BottomSheetScaffold` over a scrim. Grab handle; title "Nova transação" / "Editar
transação".
- **Type** `SegmentedToggle` **Despesa / Receita** → sets `kind`; indicator color
  follows kind (coral/mint). On edit, prefilled.
- **Nome** (`AppTextField`) → `description` (≤280, optional but encouraged).
- **Valor** (`AppTextField`, Fjalla One, BRL mask) → parsed to `amountCents`
  (positive). Currency-masked input "R$ 340,00".
- **Categoria** (`SelectField`) → picks from active categories of the chosen kind
  (spec 03); if none exist, prompt to create one.
- **Data** (`DateField`) → `occurredAt`; default today; **future dates disabled**
  with `HelperText` "Não é possível selecionar datas futuras."
- **Adicionar transação** / **Salvar** CTA → `create`/`update`, close on success.

## 7. Validation

- `amountCents` > 0 (parsed from the masked value; reject 0 / empty).
- `categoryId` required and must match the selected `kind`.
- `occurredAt` ≤ today (no future); required.
- `description` ≤ 280, optional (nullable).
- On edit, only changed fields are sent in the PATCH.

## 8. Edge cases

- No categories for the chosen kind → inline CTA "Criar categoria" (spec 03 sheet).
- Switching kind in the form with a category selected of the other kind → clear the
  category selection.
- Empty list / filtered-empty → distinct empty states ("Nenhuma transação" vs
  "Nada encontrado para esse filtro").
- `nextCursor` loops/duplicates → de-dupe by `id` when appending pages.
- Delete → optimistic removal + undo affordance; rollback on failure.
- Amount mask + pt-BR decimals (comma) → robust parse to integer cents.

## 9. Acceptance criteria

1. `list` sends `from/to/categoryId/kind/limit/cursor` correctly and parses
   `{items, nextCursor}`; `loadMore` appends until `nextCursor == null` (mocked dio).
2. `create` posts positive `amountCents`, `kind`, `categoryId`, `occurredAt`
   (`YYYY-MM-DD`), optional `description`; returns the new `Transaction`.
3. `update` PATCHes only changed fields; `delete` calls the endpoint and removes the row.
4. Timeline groups by day with correct anchors (today = green node) and per-row kind
   colors/signs (`+`/`−`, Fjalla One).
5. The sheet disables future dates and shows the helper; amount mask → correct cents.
6. Creating/editing/deleting invalidates reports totals (spec 05) and the list.
7. Widget tests: timeline render, infinite-scroll pagination, sheet validation.
