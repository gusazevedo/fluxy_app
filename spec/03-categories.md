# 03 — Categories

**Status:** Draft · **Depends on:** 00, 01, 02 · **Date:** 2026-06-26

Manage the income/expense categories used to classify transactions. Lives in the
**Categorias** tab and feeds the category picker in the "Nova transação" sheet
(spec 04) and the per-category breakdown (spec 05). No design screen exists for
this; build from spec 01 components.

---

## 1. Goal

Let the user create, rename, archive, and delete their categories, split by kind
(Despesa / Receita), so transactions can be classified consistently.

## 2. API surface (all authenticated)

| Method/Path | Query / Body | Success | Notes |
|-------------|--------------|---------|-------|
| `GET /categories` | `?kind=expense\|income`, `?includeArchived=bool` | `200 [Category]` | filters optional |
| `POST /categories` | `{name, kind}` | `201 Category` | name 1–60; kind enum |
| `GET /categories/{id}` | — | `200 Category` | |
| `PATCH /categories/{id}` | `{name}` | `200 Category` | **rename only** |
| `DELETE /categories/{id}` | — | `200` (no body) | see §6 archive vs delete |

`Category = {id, name, kind: "expense"|"income", archived: bool, createdAt}`.

## 3. Domain model (`features/categories/domain`)

```text
CategoryKind = expense | income
Category { String id; String name; CategoryKind kind; bool archived; DateTime createdAt; }
```

## 4. Data layer

- `CategoriesApi` — endpoint wrappers.
- `CategoriesRepository`:
  - `list({CategoryKind? kind, bool includeArchived = false})`
  - `create(String name, CategoryKind kind)`
  - `get(String id)`
  - `rename(String id, String newName)`
  - `delete(String id)`
- Maps errors → `Failure`. Duplicate name (if API returns 409) → `ConflictFailure`
  → "Já existe uma categoria com esse nome".

## 5. State & controllers (`features/categories/presentation`)

- `categoriesControllerProvider` → `AsyncValue<List<Category>>`, parameterized by a
  `kind` filter + `includeArchived` toggle.
- A lightweight `categoriesProvider` exposing the active (non-archived) list by kind
  for reuse by the transaction sheet (spec 04) and reports (spec 05) — **light cache**
  (spec 00 §data strategy): fetched once, invalidated on create/rename/delete.
- Mutations are **optimistic** with rollback on failure.

## 6. Archive vs delete

- The model has an `archived` flag, and the only documented mutation besides
  create/rename is `DELETE`. The API exposes no archive endpoint, so:
  - **Delete** = `DELETE /categories/{id}` (hard delete). Confirm first (see §7).
  - **Archived** categories are surfaced read-only (filter `includeArchived=true`)
    so historical transactions still resolve a name; archived items are visually
    dimmed and excluded from the transaction picker.
- If a delete is rejected because the category is in use (e.g. 409), surface
  "Categoria em uso — arquive em vez de excluir" and keep it.

## 7. Screens / UX (pt-BR, spec 01 components)

1. **Categorias (list)** — `SegmentedToggle` **Despesa / Receita** at top; list of
   rows (`surface`, radius 16): leading `CategoryIconChip` (kind-tinted) · name
   (`bodyStrong`); trailing overflow menu (Renomear / Excluir). Archived rows dimmed
   with an "Arquivada" tag. Empty state (`AppEmptyView`): "Nenhuma categoria ainda".
   FAB or header "+" → Nova categoria. A "Mostrar arquivadas" toggle.
2. **Nova categoria** (bottom sheet, `BottomSheetScaffold`) — `SegmentedToggle` kind,
   **Nome** (`AppTextField`, ≤60), **Criar** CTA.
3. **Renomear** (bottom sheet) — prefilled **Nome**, **Salvar** CTA.
4. **Excluir** — confirmation dialog ("Excluir categoria?") → `delete`.

## 8. Validation

- Name: 1–60 chars, trimmed, non-empty. Kind required on create (immutable after —
  PATCH only renames).

## 9. Edge cases

- Empty list per kind → empty state with a create CTA.
- Delete the last category of a kind → allowed; the transaction sheet then prompts
  to create one.
- Network error on mutation → optimistic change rolls back, error toast.
- Archived category referenced by a transaction → still resolvable by name (list
  with `includeArchived=true` when hydrating names).

## 10. Acceptance criteria

1. `list(kind: expense)` calls `GET /categories?kind=expense`; `includeArchived`
   adds the query (mocked dio).
2. `create` posts `{name, kind}`; result prepended to the cached list optimistically.
3. `rename` PATCHes `{name}`; row updates; rollback on failure.
4. `delete` calls `DELETE /categories/{id}`; confirmation required; 409 → in-use message.
5. List screen renders Despesa/Receita via the toggle, dims archived, shows empty state.
6. The active-by-kind provider returns only non-archived categories for the picker.
