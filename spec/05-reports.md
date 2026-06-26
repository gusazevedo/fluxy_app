# 05 — Reports (Dashboard summary)

**Status:** Draft · **Depends on:** 00, 01, 02, 03, 04 · **Date:** 2026-06-26

Period totals and per-category breakdown that power the **Início** dashboard.
Numbers + lists only — **no chart library** (decided). Maps to the hero +
Despesas/Receitas cards of design screen **05 Principal**, extended with a period
selector and a category breakdown list.

---

## 1. Goal

Show the user, for a chosen period, their income, expense, balance, transaction
count, and where the money went (per category) — at a glance on Início.

## 2. API surface (authenticated)

| Method/Path | Query | Success |
|-------------|-------|---------|
| `GET /reports/summary` | `?from&to` (YYYY-MM-DD, optional) | `200 Summary` |

```text
Summary {
  period: { from: "YYYY-MM-DD", to: "YYYY-MM-DD" },
  totals: { incomeCents, expenseCents, balanceCents, transactionCount },
  byCategory: [ { categoryId, name, kind, archived, totalCents, transactionCount } ]
}
```

Default period when `from/to` omitted = whatever the API returns; the client
**defaults to the current month** and passes explicit `from`/`to`.

## 3. Domain model (`features/reports/domain`)

```text
ReportPeriod { DateTime from; DateTime to; }
ReportTotals { Money income; Money expense; Money balance; int transactionCount; }
CategoryBreakdown { String categoryId; String name; CategoryKind kind;
                    bool archived; Money total; int transactionCount; }
ReportSummary { ReportPeriod period; ReportTotals totals; List<CategoryBreakdown> byCategory; }
```

All `*Cents` → `Money`. `balanceCents` may be negative (income − expense) → shown
with sign/color.

## 4. Data layer

- `ReportsApi.summary({DateTime? from, DateTime? to})`.
- `ReportsRepository.summary(ReportPeriod)` → `ReportSummary`; errors → `Failure`.

## 5. State & controllers (`features/reports/presentation`)

- `reportPeriodProvider` → selected `ReportPeriod` (default: current month).
- `reportSummaryControllerProvider` → `AsyncValue<ReportSummary>` keyed by the
  period; **light cache** per period, **invalidated** when transactions change
  (spec 04 §5).
- Convenience selectors for the Início hero/cards read from this provider.

## 6. Screens / UX (pt-BR, spec 01 components)

### 6.1 On Início (design 05)
- **`BalanceHeroCard`** → "Balanço do mês" + `balance` (`displayAmount`, primary;
  coral if negative).
- Two **`StatCard`s** → Despesas (`expense.total`, coral, out arrow) and Receitas
  (`income`, mint, in arrow).
- A compact **period selector** (e.g. "Junho 2026 ▾") above the hero → opens a
  month picker / range; updates `reportPeriodProvider`.

### 6.2 Breakdown (Início section or "Ver relatório" detail)
- "Por categoria" list: each row = `CategoryIconChip` + name + `transactionCount`
  caption + `total` (`amountSm`, colored by kind), sorted by `total` desc. Optional
  thin proportion bar (CSS-free, just a sized container) — still "no chart lib".
- Toggle Despesa / Receita to switch which breakdown is shown.
- Empty period → `AppEmptyView` "Sem transações nesse período".

## 7. Edge cases

- Negative balance → coral, leading `−`.
- Archived categories present in `byCategory` → still listed (dimmed) so totals reconcile.
- Period with no data → zeros in totals, empty breakdown.
- Changing the period refetches; show a loader over the cards without unmounting.

## 8. Acceptance criteria

1. `summary` sends `from`/`to` for the selected month and parses totals + byCategory
   into `Money`-typed models (mocked dio).
2. Início hero shows `balanceCents` formatted as BRL with correct sign/color.
3. Stat cards show income (mint) and expense (coral) totals.
4. Breakdown lists categories sorted by total desc with counts; Despesa/Receita toggle works.
5. Creating/editing/deleting a transaction (spec 04) invalidates and refreshes the
   summary.
6. Empty period renders the empty state; negative balance renders coral.
