# 01 — Design System

**Status:** Draft · **Depends on:** 00 · **Date:** 2026-06-26

The visual language for Fluxy, distilled from the Claude Design file
**`Fluxy.dc.html`** (claude.ai project `9f389760-cc12-4ab5-8d40-1e1c79c7d0c0`,
owner Gus). This doc is the single reference every screen spec points to. Values
below are taken verbatim from the design; treat them as the source of truth and
keep the implementation pixel-faithful.

> **Theme is dark-only** (v1). All tokens are the dark values. Mood: modern,
> tactile "fintech" — near-black surfaces, mint-green primary, coral expense,
> condensed type, subtle dotted texture, and chunky 3D buttons.

---

## 1. Color tokens

Define once in `core/theme/tokens.dart` as `AppColors`; expose semantic names.

| Token | Hex | Use |
|-------|-----|-----|
| `bgScreen` | `#0F1115` | screen / phone background, darkest |
| `surface` | `#181B21` | cards, inputs, list rows, avatar |
| `surfaceRaised` | `#1C2027` | balance hero card |
| `sheet` | `#15181E` | bottom-sheet background |
| `border` | `#272B33` | hairline borders (1px) on every surface |
| `timelineLine` | `#2E2E2E` | git-graph vertical connector |
| `nodeFill` | `#1F1F1F` | transaction timeline node center |
| `primary` | `#3FD68C` | brand, income, CTAs, links, active accents |
| `primaryPressed` | `#239D61` | 3D button bottom shadow / pressed |
| `onPrimary` | `#07120C` | text/icon on primary (near-black green) |
| `expense` | `#F0635A` | expense amounts, danger, "Despesa" toggle |
| `onExpense` | `#1A0605` | text on expense fill (toggle active) |
| `textPrimary` | `#E8EAED` | primary text |
| `textMuted` | `#8B919B` | labels, captions, secondary text |
| `textHint` | `#6B7079` | hints, tertiary (e.g. helper rows) |
| `incomeChipBg` | `rgba(63,214,140,0.13)` | income icon-chip background |
| `expenseChipBg` | `rgba(240,99,90,0.13)` | expense icon-chip background |
| `overlayScrim` | `rgba(7,9,12,0.62)` | dim behind bottom sheet |
| `grabHandle` | `#3A3F48` | bottom-sheet grab handle |

**Semantic mapping:** income/positive = `primary`; expense/negative = `expense`.
Never hardcode hex in features — reference `AppColors`.

## 2. Typography

Two Google Fonts (via `google_fonts`, bundleable later):

- **Oswald** — all UI text (a condensed sans). Weights 300–700.
- **Fjalla One** — **money amounts only** (balance hero, stat cards, transaction
  amounts, the "Valor" field). Single weight (700-ish display).

Type scale (size / weight / letter-spacing / color), from the design:

| Style | Font | Size | Weight | LS | Color | Example |
|-------|------|------|--------|----|-------|---------|
| `displayAmount` | Fjalla One | 34 | 700 | -1 | primary | balance hero `R$ 3.240,00` |
| `titleScreen` | Oswald | 28 | 700 | -0.6 | textPrimary | "Bem-vindo de volta" |
| `titleSection` | Oswald | 20 | 700 | -0.4 | textPrimary | "Nova transação", greeting name |
| `titleList` | Oswald | 16 | 700 | -0.3 | textPrimary | "Transações" |
| `amountMd` | Fjalla One | 18 | 700 | -0.3 | income/expense | stat card values |
| `amountSm` | Fjalla One | 15 | 700 | 0 | income/expense | transaction row amount |
| `dateAnchor` | Oswald | 14 | 700 | 0.3 | textPrimary | `HOJE · 21 JUN` (uppercase) |
| `body` | Oswald | 15 | 400 | 0 | textMuted | subtitles, descriptions |
| `bodyStrong` | Oswald | 15 | 500 | 0 | textPrimary | input value, tx name |
| `label` | Oswald | 13 | 400 | 0 | textMuted | field labels ("Email", "Senha") |
| `caption` | Oswald | 12.5 | 400 | 0 | textMuted | tx category subtitle |
| `hint` | Oswald | 11.5 | 400 | 0 | textHint | helper rows |

`core/theme/app_theme.dart` maps these into `TextTheme` + named `TextStyle`
getters (`AppText.titleScreen`, `AppText.displayAmount`, …).

## 3. Spacing, radii, sizing

- **Spacing scale (px):** 4, 7, 8, 12, 14, 16, 18, 20, 22, 28, 30, 36, 38. Screen
  horizontal padding: 28 (auth) / 22 (home). Generous vertical rhythm.
- **Radii (px):** input 12–13 · card/surface 18–20 · CTA button 16 · icon-chip 8
  (sm) / 13 (tx 42px) / 15 (logo 52px) · bottom-sheet top 28 · FAB 20 (squircle) ·
  toggle container 13 / indicator 10 · avatar 50% · phone frame 42 (design canvas only).
- **Hit targets:** CTA button padding 16 all-round; inputs 14–15 vertical.

## 4. Elevation, texture & motion (signatures)

These three details define the brand — implement them precisely:

1. **3D button.** Primary CTAs and the FAB have a solid offset shadow
   `BoxShadow(color: primaryPressed, offset: (0,4), blur: 0)`. On press: translate
   the button down 3px and remove the shadow (`translateY(3px); box-shadow:none`),
   ~70ms ease. Build as a reusable `PressableShadowButton`.
2. **Dotted texture.** Cards (`surfaceRaised`, stat cards, balance hero) carry a
   faint dot grid: `radial-gradient(rgba(255,255,255,0.06) 1px, transparent 1px)`
   at 14×14px. In Flutter: a `CustomPainter` dot-grid overlay or a tiled asset.
3. **Hairline borders.** Almost every surface has `1px solid border` (`#272B33`).

Other motion: segmented toggle indicator slides with
`cubic-bezier(.4,0,.2,1)` over 300ms (color cross-fades 300ms).

## 5. Iconography

Lucide-style **stroke** icons, `stroke-width` 2–2.6, round caps/joins. Use
`lucide_icons` (or equivalent) / hand-rolled `CustomPaint` for the few custom ones.
Key glyphs seen: chevron-left (back), chevron-down (select), calendar, clock,
plus, check, arrow-out (`M7 17L17 7…` expense/outgoing), arrow-in
(`M17 7L7 17…` income/incoming).

## 6. Component specs

Each component lives in `core/widgets/`. Spec = anatomy → tokens → states.

1. **PrimaryButton** — full-width green CTA. `primary` fill, `onPrimary` 16/700
   text, radius 16, padding 16, 3D shadow + press (§4.1). States: enabled, pressed,
   loading (spinner in `onPrimary`), disabled (reduced opacity, no shadow).
2. **LinkButton** — text-only, `primary` 13.5/500 (e.g. "Esqueci minha senha",
   "Voltar ao login").
3. **InlineLink** — muted sentence with an emphasized `textPrimary` 500 action
   ("Não tem conta? **Cadastre-se**").
4. **AppTextField** — label (`label` style) above a `surface` box, `border`
   hairline, radius 13, padding 15×16, `bodyStrong` text. Error state: border →
   `expense`, error message (`caption`, expense) below. Variants:
   - **PasswordField** — obscured, dots `letter-spacing:3`, trailing show/hide.
   - **SelectField** — trailing chevron-down; opens a picker; same box.
   - **DateField** — trailing calendar icon; opens date picker.
5. **BackButton** — 42×42 `surface` square, radius 12, hairline, chevron-left.
6. **Logo** — rounded-square dark tile with a `primary` dot centered (sizes 34/52).
7. **Avatar** — circle `surface`, hairline, `primary` initials (`MC`), 42px.
8. **OtpCodeInput** — 6 boxes (`surface`, hairline, radius 12), `displayAmount`-ish
   centered digit; numeric keyboard, auto-advance, full-paste, auto-submit at 6.
   Error shake + `expense` borders on invalid.
9. **BalanceHeroCard** — `surfaceRaised`, dotted texture, hairline, radius 20,
   padding 20×22. Label (`label`) + `displayAmount` (primary).
10. **StatCard** — half-width; icon-chip (income/expense bg) + arrow glyph, label
    (`caption`), value (`amountMd`, colored). Two side-by-side (Despesas/Receitas).
11. **CategoryIconChip** — rounded square (radius 8–13), tinted bg
    (income/expense chip), colored stroke glyph. Drives transaction-row leading.
12. **TransactionRow** — `surface`, radius 16, padding 10×12: leading
    `CategoryIconChip` (42px) · title (`bodyStrong`) + category (`caption`) · trailing
    signed amount (`amountSm`, colored, `+`/`−`).
13. **TransactionTimeline** — vertical git-graph. **Date anchor:** larger node
    (15px; `primary` for today, `textMuted` for past) with a `4px bgScreen` ring +
    `dateAnchor` label. **Transaction node:** 11px, `nodeFill` center, 2.5px ring in
    income/expense color, connected by a 2px `timelineLine`. Groups transactions by
    day. Handles top/middle/last connector segments.
14. **SegmentedToggle (Despesa/Receita)** — container `bgScreen`+hairline radius 13,
    padding 4; sliding indicator (radius 10) that is `expense` when Despesa /
    `primary` when Receita and translates 0↔100%. Active label gets dark on-color
    text; inactive `textMuted`. Icon + label per side. (§4 motion.)
15. **Fab** — 60×60 squircle (radius 20), `primary`, plus glyph (`onPrimary`), 3D
    shadow + drop shadow `0 14px 22px rgba(0,0,0,.35)`, press (§4.1).
16. **BottomSheetScaffold** — `sheet` bg, top radius 28, hairline-top, grab handle
    (40×5, `grabHandle`), scrim `overlayScrim`. Title (`titleSection`) + content.
17. **HelperText** — small icon + `hint` text row (e.g. clock + "Não é possível
    selecionar datas futuras.").
18. **RequirementRow** — `primary` check-circle + `label` text ("Mínimo de 8
    caracteres"); satisfied vs unmet states.
19. **BottomNavBar** — four items (Início · Transações · Categorias · Conta); active
    = `primary`, inactive = `textMuted`; over `bgScreen`/`surface` with hairline-top.
20. **Async views** — `AppLoader` (centered spinner, `primary`), `AppEmptyView`
    (icon + muted message), `AppErrorView` (message + retry `PrimaryButton`). Used
    for every list/detail loading/empty/error state.

## 7. Flutter integration

- `core/theme/tokens.dart` → `AppColors`, `AppRadii`, `AppSpacing`, raw type consts.
- `core/theme/app_theme.dart` → `buildDarkTheme()` returning `ThemeData` with dark
  `ColorScheme` (primary `#3FD68C`, surface `#181B21`, background `#0F1115`, error
  `#F0635A`), `TextTheme` from Oswald, plus `AppText` named styles incl. Fjalla One.
- Components in `core/widgets/` consume only theme/tokens. Feature screens compose
  components — they MUST NOT introduce raw colors, paddings, or font families.
- Fonts: `GoogleFonts.oswald(...)` / `GoogleFonts.fjallaOne(...)`; can switch to
  bundled assets in `pubspec.yaml` for offline/perf without touching call sites.

## 8. Acceptance criteria

1. `AppColors`/`AppText` expose every token in §1–§2 with the exact values.
2. `buildDarkTheme()` yields the dark scheme; a sample screen renders with Oswald
   body + Fjalla One amounts.
3. `PrimaryButton` and `Fab` show the 3D offset shadow and the press-down animation.
4. `TransactionTimeline` renders date anchors + nodes + connectors matching the
   design for a 2-day sample (today green anchor, past gray anchor).
5. `SegmentedToggle` animates the indicator and swaps colors between Despesa/Receita.
6. `OtpCodeInput` accepts paste and auto-submits at 6 digits.
7. A golden/widget test snapshots `TransactionRow`, `BalanceHeroCard`, and
   `PrimaryButton` against the design tokens.
