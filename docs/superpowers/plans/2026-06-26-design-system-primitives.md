# Design System — Primitives (Part 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the reusable, dark-theme `core/widgets/` component primitives the auth feature (spec 02) needs — bundled fonts, the 3D `PrimaryButton`, text fields, links, identity bits, info rows, async state views, a bottom-sheet scaffold, and the OTP code input — each widget/behaviour-tested against the design tokens.

**Architecture:** Pure presentation widgets in `lib/core/widgets/`, consuming only `core/theme` tokens (`AppColors`, `AppText`, `AppRadii`, `AppSpacing`) — no feature logic, no API. Fonts are **bundled as assets** (Oswald variable + Fjalla One) so rendering is deterministic and offline and `google_fonts` is dropped. Source of truth: `spec/01-design-system.md` (distilled from `Fluxy.dc.html`). This is Part 1 of 2; Part 2 (finance components: timeline, stat/balance cards, transaction row, segmented toggle, FAB, bottom nav) comes before the transactions feature.

**Tech Stack:** Flutter (Dart `^3.12.1`), Material 3, bundled fonts (no `google_fonts` at runtime), `flutter_test`.

## Global Constraints

- Dark theme only. Colors come ONLY from `AppColors` (`lib/core/theme/tokens.dart`); never hardcode hex in a widget.
- Text uses ONLY `AppText` styles (`lib/core/theme/app_theme.dart`): Oswald for UI, Fjalla One for money amounts.
- Copy is pt-BR where a component ships default copy.
- Each widget is a stateless/stateful presentation unit in `lib/core/widgets/`, one file per component (or tight group), exporting via `lib/core/widgets/widgets.dart` barrel.
- Signature interactions from the design: 3D button = solid offset shadow `BoxShadow(color: AppColors.primaryPressed, offset: Offset(0,4), blurRadius: 0)`, press = translate down 3px + drop the shadow (~70ms).
- TDD: failing widget test first; behaviour/structure assertions (taps, state, presence of tokens), not pixel goldens. Commit after each green task.
- Tests must be pristine (bundled fonts ⇒ no `google_fonts` "font not found" noise).

## Existing tokens (from the merged foundation — consume these)

`AppColors`: `bgScreen #0F1115`, `surface #181B21`, `surfaceRaised #1C2027`, `sheet #15181E`, `border #272B33`, `timelineLine #2E2E2E`, `nodeFill #1F1F1F`, `primary #3FD68C`, `primaryPressed #239D61`, `onPrimary #07120C`, `expense #F0635A`, `onExpense #1A0605`, `textPrimary #E8EAED`, `textMuted #8B919B`, `textHint #6B7079`.
`AppText`: `displayAmount, amountMd, amountSm, titleScreen, titleSection, titleList, dateAnchor, body, bodyStrong, label, caption, hint`.
`AppRadii`: `input 13, card 20, button 16, sheet 28, fab 20`. `AppSpacing`: `screenH 28, homeH 22, md 16, lg 24`.

---

## File Structure (this plan)

- `assets/fonts/Oswald-VariableFont_wght.ttf`, `assets/fonts/FjallaOne-Regular.ttf` — bundled fonts.
- Modify `pubspec.yaml` — declare fonts, drop `google_fonts`.
- Modify `lib/core/theme/app_theme.dart` — `AppText`/theme use bundled `fontFamily` (no `google_fonts`).
- Modify `lib/core/theme/tokens.dart` — extend `AppRadii`/`AppSpacing` with values the primitives need.
- Modify `test/flutter_test_config.dart` — load bundled fonts via `FontLoader`; remove `google_fonts` setup.
- Create `lib/core/widgets/pressable_shadow_button.dart`, `primary_button.dart`, `link_button.dart`, `app_text_field.dart`, `identity.dart` (BackButton/Logo/Avatar), `info_rows.dart` (HelperText/RequirementRow), `async_views.dart` (AppLoader/AppEmptyView/AppErrorView), `bottom_sheet_scaffold.dart`, `otp_code_input.dart`, and a `widgets.dart` barrel.
- Tests under `test/core/widgets/`.

---

## Task 1: Bundle fonts, extend tokens, drop google_fonts

**Files:**
- Create: `assets/fonts/Oswald-VariableFont_wght.ttf`, `assets/fonts/FjallaOne-Regular.ttf`
- Modify: `pubspec.yaml`, `lib/core/theme/app_theme.dart`, `lib/core/theme/tokens.dart`, `test/flutter_test_config.dart`
- Test: `test/core/theme/app_theme_test.dart` (existing — must stay green), `test/core/theme/fonts_test.dart` (new)

**Interfaces:**
- Produces: `AppText` styles now backed by bundled fonts (same getter names/values). New tokens: `AppRadii.smBox = 12`, `AppRadii.chip = 13`, `AppRadii.chipSm = 8`; `AppSpacing.xs = 4`, `AppSpacing.sm = 8`, `AppSpacing.gap = 12`, `AppSpacing.xl = 38`.

- [ ] **Step 1: Download the font files**

Run:
```bash
cd /Users/gustavo/www/native/fluxy_app
mkdir -p assets/fonts
curl -fsSL "https://raw.githubusercontent.com/google/fonts/main/ofl/oswald/Oswald%5Bwght%5D.ttf" -o assets/fonts/Oswald-VariableFont_wght.ttf
curl -fsSL "https://raw.githubusercontent.com/google/fonts/main/ofl/fjallaone/FjallaOne-Regular.ttf" -o assets/fonts/FjallaOne-Regular.ttf
ls -l assets/fonts
```
Expected: two non-empty `.ttf` files (Oswald ~50KB+, FjallaOne ~40KB+). If the download is blocked, STOP and report BLOCKED with the curl error — the controller will supply the files.

- [ ] **Step 2: Declare fonts and remove google_fonts in pubspec**

In `pubspec.yaml`, remove the `google_fonts` dependency line, and under `flutter:` add:
```yaml
  fonts:
    - family: Oswald
      fonts:
        - asset: assets/fonts/Oswald-VariableFont_wght.ttf
    - family: Fjalla One
      fonts:
        - asset: assets/fonts/FjallaOne-Regular.ttf
  assets:
    - assets/fonts/
```
Run: `flutter pub get` → succeeds.

- [ ] **Step 3: Write the failing font test**

```dart
// test/core/theme/fonts_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/theme/app_theme.dart';

void main() {
  test('AppText uses bundled Oswald/Fjalla families, not google_fonts', () {
    expect(AppText.titleScreen.fontFamily, 'Oswald');
    expect(AppText.bodyStrong.fontFamily, 'Oswald');
    expect(AppText.displayAmount.fontFamily, 'Fjalla One');
    expect(AppText.amountSm.fontFamily, 'Fjalla One');
    // weights preserved
    expect(AppText.titleScreen.fontWeight, FontWeight.w700);
    expect(AppText.bodyStrong.fontWeight, FontWeight.w500);
  });
}
```

- [ ] **Step 4: Run it — expect FAIL**

Run: `flutter test test/core/theme/fonts_test.dart`
Expected: FAIL (fontFamily is currently a google_fonts internal name, not `'Oswald'`).

- [ ] **Step 5: Switch AppText + theme to bundled families**

Rewrite `lib/core/theme/app_theme.dart` removing `package:google_fonts` and using bundled families (Flutter maps `fontWeight` onto the Oswald variable `wght` axis):

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'tokens.dart';

const _ui = 'Oswald';
const _amount = 'Fjalla One';

class AppText {
  static const displayAmount = TextStyle(fontFamily: _amount, fontSize: 34, color: AppColors.primary, letterSpacing: -1);
  static const amountMd = TextStyle(fontFamily: _amount, fontSize: 18, letterSpacing: -0.3);
  static const amountSm = TextStyle(fontFamily: _amount, fontSize: 15);
  static const titleScreen = TextStyle(fontFamily: _ui, fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.6);
  static const titleSection = TextStyle(fontFamily: _ui, fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.4);
  static const titleList = TextStyle(fontFamily: _ui, fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.3);
  static const dateAnchor = TextStyle(fontFamily: _ui, fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.3);
  static const body = TextStyle(fontFamily: _ui, fontSize: 15, color: AppColors.textMuted);
  static const bodyStrong = TextStyle(fontFamily: _ui, fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static const label = TextStyle(fontFamily: _ui, fontSize: 13, color: AppColors.textMuted);
  static const caption = TextStyle(fontFamily: _ui, fontSize: 12.5, color: AppColors.textMuted);
  static const hint = TextStyle(fontFamily: _ui, fontSize: 11.5, color: AppColors.textHint);
}

ThemeData buildDarkTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    surface: AppColors.surface,
    error: AppColors.expense,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme.copyWith(surfaceTint: Colors.transparent),
    scaffoldBackgroundColor: AppColors.bgScreen,
    fontFamily: _ui,
  );
}
```

- [ ] **Step 6: Extend tokens**

In `lib/core/theme/tokens.dart`, add to `AppRadii`: `static const smBox = 12.0; static const chip = 13.0; static const chipSm = 8.0;` and to `AppSpacing`: `static const xs = 4.0; static const sm = 8.0; static const gap = 12.0; static const xl = 38.0;`

- [ ] **Step 7: Load bundled fonts in tests; drop google_fonts test setup**

Rewrite `test/flutter_test_config.dart` to load the bundled fonts (deterministic rendering, no google_fonts):
```dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _load('Oswald', 'assets/fonts/Oswald-VariableFont_wght.ttf');
  await _load('Fjalla One', 'assets/fonts/FjallaOne-Regular.ttf');
  await testMain();
}

Future<void> _load(String family, String path) async {
  final loader = FontLoader(family)..addFont(_bytes(path));
  await loader.load();
}

Future<ByteData> _bytes(String path) async =>
    ByteData.view((await File(path).readAsBytes()).buffer);
```

- [ ] **Step 8: Run the affected tests + analyze**

Run: `flutter test test/core/theme/ && flutter analyze`
Expected: `fonts_test` PASS; existing `app_theme_test` still PASS; analyzer "No issues found!" (and `google_fonts` no longer imported anywhere — `grep -r google_fonts lib test` is empty).

- [ ] **Step 9: Commit**

```bash
git add assets/fonts pubspec.yaml pubspec.lock lib/core/theme test/flutter_test_config.dart test/core/theme/fonts_test.dart
git commit -m "feat: bundle Oswald/Fjalla fonts, drop google_fonts, extend tokens"
```

---

## Task 2: PressableShadowButton + PrimaryButton

**Files:**
- Create: `lib/core/widgets/pressable_shadow_button.dart`, `lib/core/widgets/primary_button.dart`
- Test: `test/core/widgets/primary_button_test.dart`

**Interfaces:**
- Produces: `PressableShadowButton({required Widget child, required VoidCallback? onPressed, Color color = AppColors.primary, Color shadowColor = AppColors.primaryPressed, double radius = AppRadii.button, EdgeInsets padding})` — the reusable 3D press surface (also used by Fab in Part 2).
- Produces: `PrimaryButton({required String label, required VoidCallback? onPressed, bool loading = false})` — full-width green CTA. `onPressed == null` or `loading == true` ⇒ disabled (no tap, no shadow, reduced opacity); `loading` shows a spinner in `onPrimary`.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/widgets/primary_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/theme/tokens.dart';
import 'package:fluxy_app/core/widgets/primary_button.dart';

Widget _host(Widget w) => MaterialApp(home: Scaffold(body: Center(child: w)));

void main() {
  testWidgets('tap fires onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(PrimaryButton(label: 'Entrar', onPressed: () => taps++)));
    await tester.tap(find.text('Entrar'));
    expect(taps, 1);
  });

  testWidgets('disabled (onPressed null) does not fire and drops the 3D shadow', (tester) async {
    await tester.pumpWidget(_host(const PrimaryButton(label: 'Entrar', onPressed: null)));
    await tester.tap(find.text('Entrar'), warnIfMissed: false);
    // resting shadow uses primaryPressed; disabled removes it
    final deco = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration as BoxDecoration;
    expect(deco.boxShadow == null || deco.boxShadow!.isEmpty, true);
  });

  testWidgets('loading shows a spinner and blocks taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(PrimaryButton(label: 'Entrar', loading: true, onPressed: () => taps++)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Entrar'), findsNothing);
    await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('enabled button carries the green fill and offset shadow', (tester) async {
    await tester.pumpWidget(_host(PrimaryButton(label: 'Entrar', onPressed: () {})));
    final deco = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration as BoxDecoration;
    expect(deco.color, AppColors.primary);
    expect(deco.boxShadow!.first.color, AppColors.primaryPressed);
    expect(deco.boxShadow!.first.offset, const Offset(0, 4));
    expect(deco.boxShadow!.first.blurRadius, 0);
  });
}
```

- [ ] **Step 2: Run it — expect FAIL** (files don't exist)

Run: `flutter test test/core/widgets/primary_button_test.dart`
Expected: FAIL — `primary_button.dart` not found.

- [ ] **Step 3: Implement PressableShadowButton**

```dart
// lib/core/widgets/pressable_shadow_button.dart
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class PressableShadowButton extends StatefulWidget {
  const PressableShadowButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color = AppColors.primary,
    this.shadowColor = AppColors.primaryPressed,
    this.radius = AppRadii.button,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Color color;
  final Color shadowColor;
  final double radius;
  final EdgeInsets padding;

  @override
  State<PressableShadowButton> createState() => _PressableShadowButtonState();
}

class _PressableShadowButtonState extends State<PressableShadowButton> {
  bool _down = false;
  bool get _enabled => widget.onPressed != null;

  void _set(bool v) {
    if (_enabled && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final pressed = _down && _enabled;
    return Opacity(
      opacity: _enabled ? 1 : 0.5,
      child: GestureDetector(
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          transform: Matrix4.translationValues(0, pressed ? 3 : 0, 0),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: (_enabled && !pressed)
                ? [BoxShadow(color: widget.shadowColor, offset: const Offset(0, 4), blurRadius: 0)]
                : const [],
          ),
          child: Center(widthFactor: 1, heightFactor: 1, child: widget.child),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Implement PrimaryButton**

```dart
// lib/core/widgets/primary_button.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'pressable_shadow_button.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.loading = false});

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return SizedBox(
      width: double.infinity,
      child: PressableShadowButton(
        onPressed: enabled ? onPressed : null,
        child: loading
            ? const SizedBox(
                height: 22, width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.onPrimary))
            : Text(label, textAlign: TextAlign.center,
                style: AppText.bodyStrong.copyWith(color: AppColors.onPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
```

- [ ] **Step 5: Run it — expect PASS**

Run: `flutter test test/core/widgets/primary_button_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/core/widgets/pressable_shadow_button.dart lib/core/widgets/primary_button.dart test/core/widgets/primary_button_test.dart
git commit -m "feat: add PressableShadowButton and PrimaryButton (3D press)"
```

---

## Task 3: LinkButton + InlineLink

**Files:**
- Create: `lib/core/widgets/link_button.dart`
- Test: `test/core/widgets/link_button_test.dart`

**Interfaces:**
- Produces: `LinkButton({required String label, required VoidCallback onPressed})` — `primary`-colored 13.5px text button.
- Produces: `InlineLink({required String leading, required String action, required VoidCallback onPressed})` — muted sentence + emphasized `textPrimary` tappable action (e.g. "Não tem conta? **Cadastre-se**").

- [ ] **Step 1: Write the failing test**

```dart
// test/core/widgets/link_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/theme/tokens.dart';
import 'package:fluxy_app/core/widgets/link_button.dart';

Widget _host(Widget w) => MaterialApp(home: Scaffold(body: Center(child: w)));

void main() {
  testWidgets('LinkButton renders primary-colored label and taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(LinkButton(label: 'Esqueci minha senha', onPressed: () => taps++)));
    final txt = tester.widget<Text>(find.text('Esqueci minha senha'));
    expect(txt.style!.color, AppColors.primary);
    await tester.tap(find.text('Esqueci minha senha'));
    expect(taps, 1);
  });

  testWidgets('InlineLink shows leading + action and taps the action', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(InlineLink(leading: 'Não tem conta?', action: 'Cadastre-se', onPressed: () => taps++)));
    expect(find.textContaining('Não tem conta?'), findsOneWidget);
    await tester.tap(find.text('Cadastre-se'));
    expect(taps, 1);
  });
}
```

- [ ] **Step 2: Run it — expect FAIL**

Run: `flutter test test/core/widgets/link_button_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

```dart
// lib/core/widgets/link_button.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class LinkButton extends StatelessWidget {
  const LinkButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Text(label,
            style: AppText.body.copyWith(
                color: AppColors.primary, fontSize: 13.5, fontWeight: FontWeight.w500)),
      );
}

class InlineLink extends StatelessWidget {
  const InlineLink({super.key, required this.leading, required this.action, required this.onPressed});
  final String leading;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$leading ', style: AppText.body),
          GestureDetector(
            onTap: onPressed,
            behavior: HitTestBehavior.opaque,
            child: Text(action, style: AppText.bodyStrong),
          ),
        ],
      );
}
```

- [ ] **Step 4: Run it — expect PASS**

Run: `flutter test test/core/widgets/link_button_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/link_button.dart test/core/widgets/link_button_test.dart
git commit -m "feat: add LinkButton and InlineLink"
```

---

## Task 4: AppTextField + PasswordField

**Files:**
- Create: `lib/core/widgets/app_text_field.dart`
- Test: `test/core/widgets/app_text_field_test.dart`

**Interfaces:**
- Produces: `AppTextField({required String label, TextEditingController? controller, String? hintText, String? errorText, bool obscure = false, Widget? trailing, TextInputType? keyboardType, ValueChanged<String>? onChanged})` — label (`AppText.label`) above a `surface` box (hairline `border`, radius `AppRadii.input`); error state turns the border `expense` and shows `errorText` (`AppText.caption` in expense) below.
- Produces: `PasswordField({required String label, TextEditingController? controller, String? errorText})` — wraps `AppTextField` with `obscure` + a show/hide trailing toggle.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/widgets/app_text_field_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/theme/tokens.dart';
import 'package:fluxy_app/core/widgets/app_text_field.dart';

Widget _host(Widget w) => MaterialApp(home: Scaffold(body: Center(child: w)));

BoxDecoration _boxOf(WidgetTester t) =>
    t.widget<Container>(find.descendant(of: find.byType(AppTextField), matching: find.byType(Container)).first).decoration as BoxDecoration;

void main() {
  testWidgets('renders label and accepts input', (tester) async {
    final c = TextEditingController();
    await tester.pumpWidget(_host(AppTextField(label: 'Email', controller: c)));
    expect(find.text('Email'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'a@b.co');
    expect(c.text, 'a@b.co');
  });

  testWidgets('error state shows message and expense-colored border', (tester) async {
    await tester.pumpWidget(_host(const AppTextField(label: 'Email', errorText: 'E-mail inválido')));
    expect(find.text('E-mail inválido'), findsOneWidget);
    expect((_boxOf(tester).border as Border).top.color, AppColors.expense);
  });

  testWidgets('PasswordField obscures and toggles visibility', (tester) async {
    await tester.pumpWidget(_host(const PasswordField(label: 'Senha')));
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, true);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, false);
  });
}
```

- [ ] **Step 2: Run it — expect FAIL**

Run: `flutter test test/core/widgets/app_text_field_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

```dart
// lib/core/widgets/app_text_field.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.errorText,
    this.obscure = false,
    this.trailing,
    this.keyboardType,
    this.onChanged,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final String? errorText;
  final bool obscure;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(label, style: AppText.label),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.input),
            border: Border.all(color: hasError ? AppColors.expense : AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                  style: AppText.bodyStrong,
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: hintText,
                    hintStyle: AppText.body,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(errorText!, style: AppText.caption.copyWith(color: AppColors.expense)),
          ),
      ],
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({super.key, required this.label, this.controller, this.errorText});
  final String label;
  final TextEditingController? controller;
  final String? errorText;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => AppTextField(
        label: widget.label,
        controller: widget.controller,
        errorText: widget.errorText,
        obscure: _obscure,
        trailing: GestureDetector(
          onTap: () => setState(() => _obscure = !_obscure),
          child: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 20, color: AppColors.textMuted),
        ),
      );
}
```

- [ ] **Step 4: Run it — expect PASS**

Run: `flutter test test/core/widgets/app_text_field_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/app_text_field.dart test/core/widgets/app_text_field_test.dart
git commit -m "feat: add AppTextField and PasswordField"
```

---

## Task 5: BackButton + Logo + Avatar

**Files:**
- Create: `lib/core/widgets/identity.dart`
- Test: `test/core/widgets/identity_test.dart`

**Interfaces:**
- Produces: `AppBackButton({required VoidCallback onPressed})` — 42×42 `surface` square (radius `AppRadii.smBox`, hairline), chevron-left.
- Produces: `FluxyLogo({double size = 52})` — rounded dark tile with a centered `primary` dot.
- Produces: `Avatar({required String firstName, required String lastName, double size = 42})` — circle `surface`, hairline, `primary` initials.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/widgets/identity_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/widgets/identity.dart';

Widget _host(Widget w) => MaterialApp(home: Scaffold(body: Center(child: w)));

void main() {
  testWidgets('AppBackButton taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(AppBackButton(onPressed: () => taps++)));
    await tester.tap(find.byType(AppBackButton));
    expect(taps, 1);
  });

  testWidgets('Avatar shows uppercased initials', (tester) async {
    await tester.pumpWidget(_host(const Avatar(firstName: 'Marina', lastName: 'Costa')));
    expect(find.text('MC'), findsOneWidget);
  });

  testWidgets('FluxyLogo renders', (tester) async {
    await tester.pumpWidget(_host(const FluxyLogo()));
    expect(find.byType(FluxyLogo), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run it — expect FAIL**

Run: `flutter test test/core/widgets/identity_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

```dart
// lib/core/widgets/identity.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.smBox),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 22),
        ),
      );
}

class FluxyLogo extends StatelessWidget {
  const FluxyLogo({super.key, this.size = 52});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(size * 0.29),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Container(
            width: size * 0.38, height: size * 0.38,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          ),
        ),
      );
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.firstName, required this.lastName, this.size = 42});
  final String firstName;
  final String lastName;
  final double size;

  String get _initials {
    final f = firstName.trim().isNotEmpty ? firstName.trim()[0] : '';
    final l = lastName.trim().isNotEmpty ? lastName.trim()[0] : '';
    return '$f$l'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(_initials,
              style: AppText.bodyStrong.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
      );
}
```

- [ ] **Step 4: Run it — expect PASS**

Run: `flutter test test/core/widgets/identity_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/identity.dart test/core/widgets/identity_test.dart
git commit -m "feat: add AppBackButton, FluxyLogo, Avatar"
```

---

## Task 6: HelperText + RequirementRow

**Files:**
- Create: `lib/core/widgets/info_rows.dart`
- Test: `test/core/widgets/info_rows_test.dart`

**Interfaces:**
- Produces: `HelperText({required String text, IconData icon = Icons.schedule})` — small `hint`-styled row with a leading icon.
- Produces: `RequirementRow({required String text, required bool satisfied})` — `primary` check-circle when `satisfied` (else muted outline) + `label` text.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/widgets/info_rows_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/theme/tokens.dart';
import 'package:fluxy_app/core/widgets/info_rows.dart';

Widget _host(Widget w) => MaterialApp(home: Scaffold(body: Center(child: w)));

void main() {
  testWidgets('HelperText shows icon + text', (tester) async {
    await tester.pumpWidget(_host(const HelperText(text: 'Não é possível selecionar datas futuras.')));
    expect(find.text('Não é possível selecionar datas futuras.'), findsOneWidget);
    expect(find.byType(Icon), findsOneWidget);
  });

  testWidgets('RequirementRow shows a primary check when satisfied', (tester) async {
    await tester.pumpWidget(_host(const RequirementRow(text: 'Mínimo de 8 caracteres', satisfied: true)));
    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.color, AppColors.onPrimary); // check glyph sits on the primary circle
    expect(find.text('Mínimo de 8 caracteres'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run it — expect FAIL**

Run: `flutter test test/core/widgets/info_rows_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

```dart
// lib/core/widgets/info_rows.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class HelperText extends StatelessWidget {
  const HelperText({super.key, required this.text, this.icon = Icons.schedule});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textHint),
          const SizedBox(width: 6),
          Flexible(child: Text(text, style: AppText.hint)),
        ],
      );
}

class RequirementRow extends StatelessWidget {
  const RequirementRow({super.key, required this.text, required this.satisfied});
  final String text;
  final bool satisfied;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: satisfied ? AppColors.primary : Colors.transparent,
              border: satisfied ? null : Border.all(color: AppColors.textMuted),
            ),
            child: satisfied
                ? const Icon(Icons.check, size: 11, color: AppColors.onPrimary)
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(text, style: AppText.label),
        ],
      );
}
```

- [ ] **Step 4: Run it — expect PASS**

Run: `flutter test test/core/widgets/info_rows_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/info_rows.dart test/core/widgets/info_rows_test.dart
git commit -m "feat: add HelperText and RequirementRow"
```

---

## Task 7: Async views (Loader / Empty / Error)

**Files:**
- Create: `lib/core/widgets/async_views.dart`
- Test: `test/core/widgets/async_views_test.dart`

**Interfaces:**
- Produces: `AppLoader()` — centered `primary` spinner.
- Produces: `AppEmptyView({required String message, IconData icon = Icons.inbox_outlined})`.
- Produces: `AppErrorView({required String message, required VoidCallback onRetry})` — message + a `PrimaryButton` "Tentar novamente".

- [ ] **Step 1: Write the failing test**

```dart
// test/core/widgets/async_views_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/widgets/async_views.dart';
import 'package:fluxy_app/core/widgets/primary_button.dart';

Widget _host(Widget w) => MaterialApp(home: Scaffold(body: w));

void main() {
  testWidgets('AppLoader shows a spinner', (tester) async {
    await tester.pumpWidget(_host(const AppLoader()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AppEmptyView shows the message', (tester) async {
    await tester.pumpWidget(_host(const AppEmptyView(message: 'Nenhuma transação')));
    expect(find.text('Nenhuma transação'), findsOneWidget);
  });

  testWidgets('AppErrorView shows message and retry fires', (tester) async {
    var retried = 0;
    await tester.pumpWidget(_host(AppErrorView(message: 'Algo deu errado', onRetry: () => retried++)));
    expect(find.text('Algo deu errado'), findsOneWidget);
    expect(find.byType(PrimaryButton), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    expect(retried, 1);
  });
}
```

- [ ] **Step 2: Run it — expect FAIL**

Run: `flutter test test/core/widgets/async_views_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

```dart
// lib/core/widgets/async_views.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'primary_button.dart';

class AppLoader extends StatelessWidget {
  const AppLoader({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.primary));
}

class AppEmptyView extends StatelessWidget {
  const AppEmptyView({super.key, required this.message, this.icon = Icons.inbox_outlined});
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(message, style: AppText.body, textAlign: TextAlign.center),
          ],
        ),
      );
}

class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppColors.expense),
              const SizedBox(height: AppSpacing.md),
              Text(message, style: AppText.body, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(label: 'Tentar novamente', onPressed: onRetry),
            ],
          ),
        ),
      );
}
```

- [ ] **Step 4: Run it — expect PASS**

Run: `flutter test test/core/widgets/async_views_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/async_views.dart test/core/widgets/async_views_test.dart
git commit -m "feat: add AppLoader, AppEmptyView, AppErrorView"
```

---

## Task 8: BottomSheetScaffold

**Files:**
- Create: `lib/core/widgets/bottom_sheet_scaffold.dart`
- Test: `test/core/widgets/bottom_sheet_scaffold_test.dart`

**Interfaces:**
- Produces: `BottomSheetScaffold({required String title, required Widget child})` — `sheet` bg, top radius `AppRadii.sheet`, grab handle (40×5), `titleSection` title, then `child`. Safe-area + scroll aware.
- Produces: `Future<T?> showFluxySheet<T>(BuildContext context, {required String title, required Widget child})` — opens it via `showModalBottomSheet` with the `overlayScrim`.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/widgets/bottom_sheet_scaffold_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/widgets/bottom_sheet_scaffold.dart';

void main() {
  testWidgets('shows title and child; opens via showFluxySheet', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          return Center(
            child: ElevatedButton(
              onPressed: () => showFluxySheet(context, title: 'Nova transação', child: const Text('corpo')),
              child: const Text('open'),
            ),
          );
        }),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Nova transação'), findsOneWidget);
    expect(find.text('corpo'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run it — expect FAIL**

Run: `flutter test test/core/widgets/bottom_sheet_scaffold_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

```dart
// lib/core/widgets/bottom_sheet_scaffold.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class BottomSheetScaffold extends StatelessWidget {
  const BottomSheetScaffold({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.sheet,
        border: Border(top: BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      padding: EdgeInsets.fromLTRB(24, 14, 24, 30 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 5,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3F48),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Text(title, style: AppText.titleSection),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

Future<T?> showFluxySheet<T>(BuildContext context, {required String title, required Widget child}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x9E07090C), // overlayScrim rgba(7,9,12,0.62)
    builder: (_) => BottomSheetScaffold(title: title, child: child),
  );
}
```

- [ ] **Step 4: Run it — expect PASS**

Run: `flutter test test/core/widgets/bottom_sheet_scaffold_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/bottom_sheet_scaffold.dart test/core/widgets/bottom_sheet_scaffold_test.dart
git commit -m "feat: add BottomSheetScaffold + showFluxySheet"
```

---

## Task 9: OtpCodeInput + widgets barrel

**Files:**
- Create: `lib/core/widgets/otp_code_input.dart`, `lib/core/widgets/widgets.dart`
- Test: `test/core/widgets/otp_code_input_test.dart`

**Interfaces:**
- Produces: `OtpCodeInput({int length = 6, required ValueChanged<String> onChanged, ValueChanged<String>? onCompleted})` — `length` boxes (`surface`, hairline, radius `AppRadii.smBox`), numeric keyboard, auto-advance, full-code paste, fires `onCompleted` when `length` digits are entered. The current code is handled as a `String`.
- Produces: `lib/core/widgets/widgets.dart` — barrel exporting every Part-1 widget.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/widgets/otp_code_input_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/widgets/otp_code_input.dart';

Widget _host(Widget w) => MaterialApp(home: Scaffold(body: Center(child: w)));

void main() {
  testWidgets('renders 6 boxes and reports the assembled code', (tester) async {
    String code = '';
    String? completed;
    await tester.pumpWidget(_host(OtpCodeInput(
      onChanged: (v) => code = v,
      onCompleted: (v) => completed = v,
    )));
    expect(find.byType(TextField), findsNWidgets(6));

    final fields = find.byType(TextField);
    for (var i = 0; i < 6; i++) {
      await tester.enterText(fields.at(i), '${i + 1}');
      await tester.pump();
    }
    expect(code, '123456');
    expect(completed, '123456');
  });
}
```

- [ ] **Step 2: Run it — expect FAIL**

Run: `flutter test test/core/widgets/otp_code_input_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement OtpCodeInput**

```dart
// lib/core/widgets/otp_code_input.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class OtpCodeInput extends StatefulWidget {
  const OtpCodeInput({super.key, this.length = 6, required this.onChanged, this.onCompleted});
  final int length;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpCodeInput> createState() => _OtpCodeInputState();
}

class _OtpCodeInputState extends State<OtpCodeInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _emit() {
    final code = _code;
    widget.onChanged(code);
    if (code.length == widget.length && !code.contains('')) {
      widget.onCompleted?.call(code);
    }
  }

  void _onChanged(int i, String v) {
    // Full-code paste into one box.
    if (v.length > 1) {
      final digits = v.replaceAll(RegExp(r'\D'), '');
      for (var j = 0; j < widget.length; j++) {
        _controllers[j].text = j < digits.length ? digits[j] : '';
      }
      final next = digits.length.clamp(0, widget.length - 1);
      _nodes[next].requestFocus();
      _emit();
      return;
    }
    if (v.isNotEmpty && i < widget.length - 1) _nodes[i + 1].requestFocus();
    if (v.isEmpty && i > 0) _nodes[i - 1].requestFocus();
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (i) {
        return SizedBox(
          width: 48, height: 56,
          child: TextField(
            controller: _controllers[i],
            focusNode: _nodes[i],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppText.titleSection,
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.smBox),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.smBox),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            onChanged: (v) => _onChanged(i, v),
          ),
        );
      }),
    );
  }
}
```

- [ ] **Step 4: Run it — expect PASS**

Run: `flutter test test/core/widgets/otp_code_input_test.dart`
Expected: PASS.

- [ ] **Step 5: Create the barrel**

```dart
// lib/core/widgets/widgets.dart
export 'app_text_field.dart';
export 'async_views.dart';
export 'bottom_sheet_scaffold.dart';
export 'identity.dart';
export 'info_rows.dart';
export 'link_button.dart';
export 'otp_code_input.dart';
export 'pressable_shadow_button.dart';
export 'primary_button.dart';
```

- [ ] **Step 6: Full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: all tests PASS, pristine output (no `google_fonts` noise); analyzer "No issues found!".

- [ ] **Step 7: Commit**

```bash
git add lib/core/widgets/otp_code_input.dart lib/core/widgets/widgets.dart test/core/widgets/otp_code_input_test.dart
git commit -m "feat: add OtpCodeInput and widgets barrel"
```

---

## Self-Review

**Spec coverage (`spec/01-design-system.md` §6 components — Part 1 subset):** PrimaryButton → T2; LinkButton/InlineLink → T3; AppTextField + PasswordField → T4; BackButton/Logo/Avatar → T5; HelperText/RequirementRow → T6; async views → T7; BottomSheetScaffold → T8; OtpCodeInput → T9; fonts/tokens foundation (§1,§2,§3,§7) → T1. **Deferred to Part 2 (finance components):** StatCard, BalanceHeroCard, CategoryIconChip, TransactionRow, TransactionTimeline, SegmentedToggle, Fab, BottomNavBar, SelectField, DateField — explicitly out of scope here (needed by transactions/reports, not auth).

**Placeholder scan:** no TBD/TODO; every code step has complete, compiling widget code and a behaviour test.

**Type consistency:** `PressableShadowButton`(T2) consumed by `PrimaryButton`(T2) and (later) Fab; `PrimaryButton`(T2) consumed by `AppErrorView`(T7); `AppText`/`AppColors`/`AppRadii`/`AppSpacing` token names match the foundation (`smBox`/`chip`/`chipSm` + `xs`/`sm`/`gap`/`xl` added in T1); the barrel(T9) re-exports the exact file names created.

**Note on goldens:** tests assert behaviour + token usage (colors/styles via finders), not pixel goldens — robust across machines. With bundled fonts (T1) a future golden suite would be deterministic if added.
