# Categories Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the **Categorias** feature — list income/expense categories split by kind, create/rename/delete them with optimistic UI, surfacing archived items read-only — on top of the auth-era networking/design-system foundation.

**Architecture:** Mirror the auth feature's layering exactly: thin `CategoriesApi` (dio wrappers) → guarded `CategoriesRepository` (maps `DioException → Failure`) → a hand-written `CategoriesController extends AsyncNotifier<List<Category>>` holding a `kind`/`includeArchived` filter and exposing optimistic `create`/`rename`/`remove`/`setFilter`. Screens compose spec-01 primitives; two missing primitives (`SegmentedToggle`, `CategoryIconChip`) are added to `core/widgets`. The `/categories` shell tab is pointed at the real screen.

**Tech Stack:** Flutter (Dart `^3.12.1`), `flutter_riverpod` v3 (hand-written `AsyncNotifier`/`Notifier`), `dio`, `go_router`, `freezed` + `json_serializable` (build_runner), design-system widgets (`core/widgets/widgets.dart`), `mocktail` + `flutter_test`.

## Global Constraints

- **pt-BR copy only**, centralized in `categories_strings.dart` — no string literals scattered in widgets.
- **Colors ONLY from `AppColors`**, text ONLY from `AppText`, spacing from `AppSpacing`, radii from `AppRadii` (`core/theme`). Never hardcode hex.
- **Reuse design-system primitives** from `core/widgets/widgets.dart` (`AppTextField`, `PrimaryButton`, `AppEmptyView`, `AppLoader`, `AppErrorView`, `BottomSheetScaffold`/`showFluxySheet`). Add only the two genuinely-missing ones (`SegmentedToggle`, `CategoryIconChip`) to `core/widgets`.
- **Validation:** category name 1–60 chars, trimmed, non-empty. Kind required on create; immutable after (PATCH renames only).
- **No raw exception/JSON text shown.** Errors come from `Failure.message`; a create-conflict (409) shows "Já existe uma categoria com esse nome"; a delete-conflict (409) shows "Categoria em uso e não pode ser excluída." (No archive action exists — the API exposes no archive endpoint.)
- **Engine reuse, not change.** Do not modify `lib/core/network`, `lib/core/error`, or the auth feature. The only `lib/app/` change is pointing the `/categories` route at the real screen.
- **Riverpod note:** do NOT use a manual `AsyncNotifierProvider.family` — reading the family argument in v3 requires the `@internal` `ref.$arg`, which breaks analyze-clean. Use a single `AsyncNotifier` with a `setFilter()` method instead.
- TDD: failing test first, minimal code, green, commit per task. `flutter analyze` clean each task.

## Existing interfaces to consume (do NOT re-implement)

**Networking / errors:**
- `dioProvider` (`Provider<Dio>`) — `lib/core/network/dio_client.dart`.
- `failureFromDio(DioException)` → `Failure` — `lib/core/network/api_exception.dart`. Maps `409 → ConflictFailure`, `400/422 → ValidationFailure`, `404 → NotFoundFailure`, timeouts/connection → `NetworkFailure`, `5xx → ServerFailure`.
- `Failure` (`lib/core/error/failure.dart`): `sealed`, has `.message`; subtypes incl. `ConflictFailure`, `ValidationFailure`, `NotFoundFailure`, `NetworkFailure`, `UnknownFailure`.

**Design-system (existing):**
- `AppTextField({required String label, TextEditingController? controller, String? hintText, String? errorText, bool obscure, Widget? trailing, TextInputType? keyboardType, ValueChanged<String>? onChanged})`
- `PrimaryButton({required String label, required VoidCallback? onPressed, bool loading = false})`
- `AppLoader()`, `AppEmptyView({required String message, IconData icon})`, `AppErrorView({required String message, required VoidCallback onRetry})`
- `BottomSheetScaffold({required String title, required Widget child})` and `Future<T?> showFluxySheet<T>(BuildContext, {required String title, required Widget child})`

**Tokens:** `AppColors.{bgScreen,surface,surfaceRaised,sheet,border,primary,onPrimary,expense,onExpense,textPrimary,textMuted,textHint}`; `AppText.{titleScreen,titleSection,titleList,body,bodyStrong,label,caption,hint}`; `AppSpacing.{xs=4,sm=8,gap=12,md=16,lg=24,screenH=28,xl=38}`; `AppRadii.{input=13,card=20,button=16,sheet=28,smBox=12,chip=13,chipSm=8}`.

**Router:** `lib/app/router.dart` — the `/categories` tab currently uses `const PlaceholderScreen('Categorias')` inside the `ShellRoute`. Only its `builder` changes. `sessionStatusProvider` (`lib/core/session/session_status.dart`) is overridable in tests. `routerProvider` builds the `GoRouter`.

## File Structure (this plan)

- Create `lib/core/widgets/segmented_toggle.dart` — generic 2+ segment pill toggle.
- Create `lib/core/widgets/category_icon_chip.dart` — kind-tinted leading chip.
- Modify `lib/core/widgets/widgets.dart` — export both.
- Create `lib/features/categories/domain/category.dart` (+ generated `.freezed.dart`/`.g.dart`).
- Create `lib/features/categories/data/categories_api.dart`.
- Create `lib/features/categories/data/categories_repository.dart`.
- Create `lib/features/categories/presentation/categories_strings.dart`.
- Create `lib/features/categories/presentation/category_validators.dart`.
- Create `lib/features/categories/presentation/categories_controller.dart`.
- Create `lib/features/categories/presentation/screens/categories_screen.dart`.
- Create `lib/features/categories/presentation/widgets/category_row.dart`.
- Create `lib/features/categories/presentation/widgets/category_form_sheet.dart`.
- Create `lib/features/categories/presentation/widgets/delete_category_dialog.dart`.
- Modify `lib/app/router.dart` — point `/categories` at `CategoriesScreen`.
- Tests under `test/core/widgets/` and `test/features/categories/`.

---

## Task 1: New design-system primitives (`SegmentedToggle`, `CategoryIconChip`)

**Files:**
- Create: `lib/core/widgets/segmented_toggle.dart`
- Create: `lib/core/widgets/category_icon_chip.dart`
- Modify: `lib/core/widgets/widgets.dart`
- Test: `test/core/widgets/segmented_toggle_test.dart`
- Test: `test/core/widgets/category_icon_chip_test.dart`

**Interfaces:**
- Produces: `SegmentedToggle({required List<String> segments, required int selectedIndex, required ValueChanged<int> onChanged, Color selectedColor})` and `CategoryIconChip({required bool isExpense, double size})`.

- [ ] **Step 1: Write the failing test for SegmentedToggle**

```dart
// test/core/widgets/segmented_toggle_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/widgets/segmented_toggle.dart';

void main() {
  testWidgets('renders all segments and reports taps by index', (tester) async {
    int? tapped;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SegmentedToggle(
          segments: const ['Despesa', 'Receita'],
          selectedIndex: 0,
          onChanged: (i) => tapped = i,
        ),
      ),
    ));

    expect(find.text('Despesa'), findsOneWidget);
    expect(find.text('Receita'), findsOneWidget);

    await tester.tap(find.text('Receita'));
    expect(tapped, 1);
  });
}
```

- [ ] **Step 2: Run it — expect FAIL** (no such file)

Run: `flutter test test/core/widgets/segmented_toggle_test.dart`
Expected: FAIL — `Target of URI doesn't exist: segmented_toggle.dart`.

- [ ] **Step 3: Implement `SegmentedToggle`**

```dart
// lib/core/widgets/segmented_toggle.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// A pill-shaped segmented control. Generic over its labels so it can drive the
/// Despesa/Receita kind switch (categories, transactions) and any future binary
/// or n-ary choice.
class SegmentedToggle extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
    this.selectedColor = AppColors.primary,
  });

  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < segments.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: i == selectedIndex ? selectedColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.chipSm),
                  ),
                  child: Text(
                    segments[i],
                    textAlign: TextAlign.center,
                    style: AppText.bodyStrong.copyWith(
                      color: i == selectedIndex
                          ? AppColors.bgScreen
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run it — expect PASS**

Run: `flutter test test/core/widgets/segmented_toggle_test.dart`
Expected: PASS.

- [ ] **Step 5: Write the failing test for CategoryIconChip**

```dart
// test/core/widgets/category_icon_chip_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/theme/tokens.dart';
import 'package:fluxy_app/core/widgets/category_icon_chip.dart';

void main() {
  testWidgets('expense chip uses the expense color; income uses primary',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(children: [
          CategoryIconChip(isExpense: true),
          CategoryIconChip(isExpense: false),
        ]),
      ),
    ));

    final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
    expect(icons[0].color, AppColors.expense);
    expect(icons[1].color, AppColors.primary);
  });
}
```

- [ ] **Step 6: Run it — expect FAIL** (no such file)

Run: `flutter test test/core/widgets/category_icon_chip_test.dart`
Expected: FAIL — `Target of URI doesn't exist: category_icon_chip.dart`.

- [ ] **Step 7: Implement `CategoryIconChip`**

```dart
// lib/core/widgets/category_icon_chip.dart
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Kind-tinted leading chip for a category row / picker entry.
/// Expense → red tint + inward arrow; income → green tint + outward arrow.
class CategoryIconChip extends StatelessWidget {
  const CategoryIconChip({super.key, required this.isExpense, this.size = 42});

  final bool isExpense;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = isExpense ? AppColors.expense : AppColors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Icon(
        isExpense ? Icons.south_west : Icons.north_east,
        color: color,
        size: size * 0.5,
      ),
    );
  }
}
```

- [ ] **Step 8: Run it — expect PASS**

Run: `flutter test test/core/widgets/category_icon_chip_test.dart`
Expected: PASS.

- [ ] **Step 9: Export both from the barrel**

In `lib/core/widgets/widgets.dart`, add these two export lines (keep the list alphabetical-ish, matching the existing file):

```dart
export 'category_icon_chip.dart';
export 'segmented_toggle.dart';
```

- [ ] **Step 10: Analyze + commit**

Run: `flutter analyze`
Expected: No issues found.

```bash
git add lib/core/widgets/segmented_toggle.dart lib/core/widgets/category_icon_chip.dart lib/core/widgets/widgets.dart test/core/widgets/segmented_toggle_test.dart test/core/widgets/category_icon_chip_test.dart
git commit -m "feat(categories): SegmentedToggle + CategoryIconChip primitives"
```

---

## Task 2: `Category` domain model

**Files:**
- Create: `lib/features/categories/domain/category.dart`
- Generated: `lib/features/categories/domain/category.freezed.dart`, `category.g.dart` (build_runner)
- Test: `test/features/categories/domain/category_test.dart`

**Interfaces:**
- Produces: `enum CategoryKind { expense, income }` (JSON values `'expense'`/`'income'`, so `CategoryKind.expense.name == 'expense'`); `Category({required String id, required String name, required CategoryKind kind, required bool archived, required DateTime createdAt})` with `Category.fromJson` and `copyWith`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/categories/domain/category_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/features/categories/domain/category.dart';

void main() {
  test('fromJson parses kind enum, archived flag and createdAt', () {
    final c = Category.fromJson(const {
      'id': 'c1',
      'name': 'Mercado',
      'kind': 'expense',
      'archived': false,
      'createdAt': '2026-01-02T03:04:05.000Z',
    });

    expect(c.id, 'c1');
    expect(c.name, 'Mercado');
    expect(c.kind, CategoryKind.expense);
    expect(c.archived, false);
    expect(c.createdAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
  });

  test('CategoryKind.name matches the API query value', () {
    expect(CategoryKind.expense.name, 'expense');
    expect(CategoryKind.income.name, 'income');
  });
}
```

- [ ] **Step 2: Run it — expect FAIL** (no such file)

Run: `flutter test test/features/categories/domain/category_test.dart`
Expected: FAIL — `Target of URI doesn't exist: category.dart`.

- [ ] **Step 3: Write the model**

```dart
// lib/features/categories/domain/category.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

enum CategoryKind {
  @JsonValue('expense')
  expense,
  @JsonValue('income')
  income,
}

@freezed
abstract class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    required CategoryKind kind,
    required bool archived,
    required DateTime createdAt,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}
```

- [ ] **Step 4: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: generates `category.freezed.dart` and `category.g.dart`; "Succeeded".

- [ ] **Step 5: Run it — expect PASS**

Run: `flutter test test/features/categories/domain/category_test.dart`
Expected: PASS.

- [ ] **Step 6: Analyze + commit**

Run: `flutter analyze`
Expected: No issues found.

```bash
git add lib/features/categories/domain/ test/features/categories/domain/category_test.dart
git commit -m "feat(categories): Category domain model"
```

---

## Task 3: `CategoriesApi` + `CategoriesRepository`

**Files:**
- Create: `lib/features/categories/data/categories_api.dart`
- Create: `lib/features/categories/data/categories_repository.dart`
- Test: `test/features/categories/data/categories_api_test.dart`
- Test: `test/features/categories/data/categories_repository_test.dart`

**Interfaces:**
- Consumes: `dioProvider`, `failureFromDio`, `Category`, `CategoryKind`.
- Produces:
  - `CategoriesApi(Dio)` with `Future<List<Category>> list({CategoryKind? kind, bool includeArchived})`, `Future<Category> create(String name, CategoryKind kind)`, `Future<Category> get(String id)`, `Future<Category> rename(String id, String name)`, `Future<void> delete(String id)`; `categoriesApiProvider`.
  - `CategoriesRepository(CategoriesApi)` with the same five methods (`rename(String id, String newName)`), each mapping errors to `Failure`; `categoriesRepositoryProvider`.

- [ ] **Step 1: Write the failing API test**

```dart
// test/features/categories/data/categories_api_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/features/categories/data/categories_api.dart';
import 'package:fluxy_app/features/categories/domain/category.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

Response<dynamic> _resp(String path, dynamic data, [int code = 200]) => Response(
      requestOptions: RequestOptions(path: path),
      statusCode: code,
      data: data,
    );

Map<String, dynamic> _json(String id, String name, String kind) => {
      'id': id,
      'name': name,
      'kind': kind,
      'archived': false,
      'createdAt': '2026-01-02T03:04:05.000Z',
    };

void main() {
  late _MockDio dio;
  late CategoriesApi api;

  setUp(() {
    dio = _MockDio();
    api = CategoriesApi(dio);
  });

  test('list passes kind + includeArchived as query params', () async {
    when(() => dio.get('/categories', queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => _resp('/categories', [_json('c1', 'Mercado', 'expense')]));

    final out = await api.list(kind: CategoryKind.expense, includeArchived: true);

    expect(out.single.name, 'Mercado');
    verify(() => dio.get('/categories',
        queryParameters: {'kind': 'expense', 'includeArchived': true})).called(1);
  });

  test('list omits query params when unset', () async {
    when(() => dio.get('/categories', queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => _resp('/categories', const []));

    await api.list();

    verify(() => dio.get('/categories', queryParameters: {})).called(1);
  });

  test('create posts {name, kind} and parses the result', () async {
    when(() => dio.post('/categories', data: any(named: 'data')))
        .thenAnswer((_) async => _resp('/categories', _json('c2', 'Salário', 'income'), 201));

    final c = await api.create('Salário', CategoryKind.income);

    expect(c.id, 'c2');
    expect(c.kind, CategoryKind.income);
    verify(() => dio.post('/categories', data: {'name': 'Salário', 'kind': 'income'}))
        .called(1);
  });

  test('rename PATCHes {name}', () async {
    when(() => dio.patch('/categories/c1', data: any(named: 'data')))
        .thenAnswer((_) async => _resp('/categories/c1', _json('c1', 'Compras', 'expense')));

    final c = await api.rename('c1', 'Compras');

    expect(c.name, 'Compras');
    verify(() => dio.patch('/categories/c1', data: {'name': 'Compras'})).called(1);
  });

  test('delete DELETEs the id', () async {
    when(() => dio.delete('/categories/c1'))
        .thenAnswer((_) async => _resp('/categories/c1', null));

    await api.delete('c1');

    verify(() => dio.delete('/categories/c1')).called(1);
  });
}
```

- [ ] **Step 2: Run it — expect FAIL** (no such file)

Run: `flutter test test/features/categories/data/categories_api_test.dart`
Expected: FAIL — `Target of URI doesn't exist: categories_api.dart`.

- [ ] **Step 3: Write `CategoriesApi`**

```dart
// lib/features/categories/data/categories_api.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/category.dart';

class CategoriesApi {
  CategoriesApi(this._dio);
  final Dio _dio;

  Future<List<Category>> list({CategoryKind? kind, bool includeArchived = false}) async {
    final res = await _dio.get('/categories', queryParameters: {
      if (kind != null) 'kind': kind.name,
      if (includeArchived) 'includeArchived': true,
    });
    return (res.data as List)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Category> create(String name, CategoryKind kind) async {
    final res = await _dio.post('/categories', data: {'name': name, 'kind': kind.name});
    return Category.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Category> get(String id) async {
    final res = await _dio.get('/categories/$id');
    return Category.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Category> rename(String id, String name) async {
    final res = await _dio.patch('/categories/$id', data: {'name': name});
    return Category.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _dio.delete('/categories/$id');
}

final categoriesApiProvider =
    Provider<CategoriesApi>((ref) => CategoriesApi(ref.watch(dioProvider)));
```

- [ ] **Step 4: Run it — expect PASS**

Run: `flutter test test/features/categories/data/categories_api_test.dart`
Expected: PASS.

- [ ] **Step 5: Write the failing repository test**

```dart
// test/features/categories/data/categories_repository_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/features/categories/data/categories_api.dart';
import 'package:fluxy_app/features/categories/data/categories_repository.dart';
import 'package:fluxy_app/features/categories/domain/category.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements CategoriesApi {}

DioException _dioErr(int code) => DioException(
      requestOptions: RequestOptions(path: '/categories'),
      response: Response(
          requestOptions: RequestOptions(path: '/categories'), statusCode: code),
      type: DioExceptionType.badResponse,
    );

Category _cat = Category(
  id: 'c1',
  name: 'Mercado',
  kind: CategoryKind.expense,
  archived: false,
  createdAt: DateTime.utc(2026, 1, 2),
);

void main() {
  late _MockApi api;
  late CategoriesRepository repo;

  setUp(() {
    api = _MockApi();
    repo = CategoriesRepository(api);
  });

  test('list delegates to the api', () async {
    when(() => api.list(kind: CategoryKind.expense, includeArchived: false))
        .thenAnswer((_) async => [_cat]);

    final out = await repo.list(kind: CategoryKind.expense);

    expect(out.single.id, 'c1');
  });

  test('create maps a 409 to ConflictFailure', () async {
    when(() => api.create('Mercado', CategoryKind.expense)).thenThrow(_dioErr(409));

    expect(
      () => repo.create('Mercado', CategoryKind.expense),
      throwsA(isA<ConflictFailure>()),
    );
  });

  test('delete maps a 409 to ConflictFailure', () async {
    when(() => api.delete('c1')).thenThrow(_dioErr(409));

    expect(() => repo.delete('c1'), throwsA(isA<ConflictFailure>()));
  });

  test('rename maps a network error to NetworkFailure', () async {
    when(() => api.rename('c1', 'X')).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/categories/c1'),
      type: DioExceptionType.connectionError,
    ));

    expect(() => repo.rename('c1', 'X'), throwsA(isA<NetworkFailure>()));
  });
}
```

- [ ] **Step 6: Run it — expect FAIL** (no such file)

Run: `flutter test test/features/categories/data/categories_repository_test.dart`
Expected: FAIL — `Target of URI doesn't exist: categories_repository.dart`.

- [ ] **Step 7: Write `CategoriesRepository`**

```dart
// lib/features/categories/data/categories_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/api_exception.dart';
import '../domain/category.dart';
import 'categories_api.dart';

class CategoriesRepository {
  CategoriesRepository(this._api);
  final CategoriesApi _api;

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on Failure {
      rethrow;
    } on DioException catch (e) {
      throw failureFromDio(e);
    } catch (_) {
      throw const UnknownFailure();
    }
  }

  Future<List<Category>> list({CategoryKind? kind, bool includeArchived = false}) =>
      _guard(() => _api.list(kind: kind, includeArchived: includeArchived));

  Future<Category> create(String name, CategoryKind kind) =>
      _guard(() => _api.create(name, kind));

  Future<Category> get(String id) => _guard(() => _api.get(id));

  Future<Category> rename(String id, String newName) =>
      _guard(() => _api.rename(id, newName));

  Future<void> delete(String id) => _guard(() => _api.delete(id));
}

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => CategoriesRepository(ref.watch(categoriesApiProvider)),
);
```

- [ ] **Step 8: Run it — expect PASS**

Run: `flutter test test/features/categories/data/`
Expected: PASS.

- [ ] **Step 9: Analyze + commit**

Run: `flutter analyze`
Expected: No issues found.

```bash
git add lib/features/categories/data/ test/features/categories/data/
git commit -m "feat(categories): CategoriesApi + guarded repository"
```

---

## Task 4: Strings, validator, and `CategoriesController`

**Files:**
- Create: `lib/features/categories/presentation/categories_strings.dart`
- Create: `lib/features/categories/presentation/category_validators.dart`
- Create: `lib/features/categories/presentation/categories_controller.dart`
- Test: `test/features/categories/presentation/category_validators_test.dart`
- Test: `test/features/categories/presentation/categories_controller_test.dart`

**Interfaces:**
- Consumes: `categoriesRepositoryProvider`, `Category`, `CategoryKind`, `Failure`.
- Produces:
  - `CategoriesStrings` (static pt-BR copy, incl. `dupName`, `inUse`, `nameRequired`, `nameTooLong`).
  - `String? categoryNameError(String raw)` — null when valid.
  - `typedef CategoryFilter = ({CategoryKind kind, bool includeArchived});`
  - `CategoriesController extends AsyncNotifier<List<Category>>` with `CategoryFilter get filter`, `Future<void> setFilter({CategoryKind? kind, bool? includeArchived})`, `Future<void> create(String name, CategoryKind kind)`, `Future<void> rename(String id, String newName)`, `Future<void> remove(String id)`.
  - `categoriesControllerProvider` (`AsyncNotifierProvider<CategoriesController, List<Category>>`).

- [ ] **Step 1: Write the strings file** (no test of its own — consumed by later steps)

```dart
// lib/features/categories/presentation/categories_strings.dart
class CategoriesStrings {
  CategoriesStrings._();

  static const tab = 'Categorias';
  static const expense = 'Despesa';
  static const income = 'Receita';

  static const empty = 'Nenhuma categoria ainda';
  static const showArchived = 'Mostrar arquivadas';
  static const archivedTag = 'Arquivada';

  static const newCategory = 'Nova categoria';
  static const renameTitle = 'Renomear categoria';
  static const nameLabel = 'Nome';
  static const create = 'Criar';
  static const save = 'Salvar';
  static const rename = 'Renomear';
  static const delete = 'Excluir';
  static const cancel = 'Cancelar';

  static const deleteConfirmTitle = 'Excluir categoria?';
  static String deleteConfirmBody(String name) =>
      'A categoria "$name" será excluída permanentemente.';

  static const loadError = 'Não foi possível carregar as categorias.';
  static const retry = 'Tentar novamente';

  // Validation / conflicts
  static const nameRequired = 'Informe um nome.';
  static const nameTooLong = 'Máximo de 60 caracteres.';
  static const dupName = 'Já existe uma categoria com esse nome.';
  static const inUse = 'Categoria em uso e não pode ser excluída.';
}
```

- [ ] **Step 2: Write the failing validator test**

```dart
// test/features/categories/presentation/category_validators_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/features/categories/presentation/categories_strings.dart';
import 'package:fluxy_app/features/categories/presentation/category_validators.dart';

void main() {
  test('rejects empty / whitespace-only names', () {
    expect(categoryNameError(''), CategoriesStrings.nameRequired);
    expect(categoryNameError('   '), CategoriesStrings.nameRequired);
  });

  test('rejects names longer than 60 chars (after trim)', () {
    expect(categoryNameError('a' * 61), CategoriesStrings.nameTooLong);
  });

  test('accepts a valid trimmed name', () {
    expect(categoryNameError('  Mercado  '), null);
    expect(categoryNameError('a' * 60), null);
  });
}
```

- [ ] **Step 3: Run it — expect FAIL** (no such file)

Run: `flutter test test/features/categories/presentation/category_validators_test.dart`
Expected: FAIL — `Target of URI doesn't exist: category_validators.dart`.

- [ ] **Step 4: Write the validator**

```dart
// lib/features/categories/presentation/category_validators.dart
import 'categories_strings.dart';

/// Returns a pt-BR error message, or null when the name is valid (1–60 trimmed).
String? categoryNameError(String raw) {
  final name = raw.trim();
  if (name.isEmpty) return CategoriesStrings.nameRequired;
  if (name.length > 60) return CategoriesStrings.nameTooLong;
  return null;
}
```

- [ ] **Step 5: Run it — expect PASS**

Run: `flutter test test/features/categories/presentation/category_validators_test.dart`
Expected: PASS.

- [ ] **Step 6: Write the failing controller test**

```dart
// test/features/categories/presentation/categories_controller_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/core/error/failure.dart';
import 'package:fluxy_app/features/categories/data/categories_repository.dart';
import 'package:fluxy_app/features/categories/domain/category.dart';
import 'package:fluxy_app/features/categories/presentation/categories_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements CategoriesRepository {}

Category _cat(String id, String name, {bool archived = false}) => Category(
      id: id,
      name: name,
      kind: CategoryKind.expense,
      archived: archived,
      createdAt: DateTime.utc(2026, 1, 1),
    );

ProviderContainer _container(_MockRepo repo) {
  final c = ProviderContainer(
    overrides: [categoriesRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('build loads the default (expense, not archived) list', () async {
    final repo = _MockRepo();
    when(() => repo.list(kind: CategoryKind.expense, includeArchived: false))
        .thenAnswer((_) async => [_cat('c1', 'Mercado')]);
    final c = _container(repo);

    final list = await c.read(categoriesControllerProvider.future);

    expect(list.single.name, 'Mercado');
  });

  test('create optimistically prepends, then replaces with the server item',
      () async {
    final repo = _MockRepo();
    when(() => repo.list(kind: CategoryKind.expense, includeArchived: false))
        .thenAnswer((_) async => [_cat('c1', 'Mercado')]);
    when(() => repo.create('Lazer', CategoryKind.expense))
        .thenAnswer((_) async => _cat('c2', 'Lazer'));
    final c = _container(repo);
    await c.read(categoriesControllerProvider.future);

    await c.read(categoriesControllerProvider.notifier)
        .create('Lazer', CategoryKind.expense);

    final names = c.read(categoriesControllerProvider).value!.map((e) => e.name);
    expect(names, ['Lazer', 'Mercado']);
  });

  test('create rolls back and rethrows on failure', () async {
    final repo = _MockRepo();
    when(() => repo.list(kind: CategoryKind.expense, includeArchived: false))
        .thenAnswer((_) async => [_cat('c1', 'Mercado')]);
    when(() => repo.create('Dup', CategoryKind.expense))
        .thenThrow(const ConflictFailure());
    final c = _container(repo);
    await c.read(categoriesControllerProvider.future);

    await expectLater(
      c.read(categoriesControllerProvider.notifier)
          .create('Dup', CategoryKind.expense),
      throwsA(isA<ConflictFailure>()),
    );
    final names = c.read(categoriesControllerProvider).value!.map((e) => e.name);
    expect(names, ['Mercado']); // rolled back
  });

  test('remove optimistically drops the row, rolls back on failure', () async {
    final repo = _MockRepo();
    when(() => repo.list(kind: CategoryKind.expense, includeArchived: false))
        .thenAnswer((_) async => [_cat('c1', 'Mercado'), _cat('c2', 'Lazer')]);
    when(() => repo.delete('c1')).thenThrow(const ConflictFailure());
    final c = _container(repo);
    await c.read(categoriesControllerProvider.future);

    await expectLater(
      c.read(categoriesControllerProvider.notifier).remove('c1'),
      throwsA(isA<ConflictFailure>()),
    );
    final ids = c.read(categoriesControllerProvider).value!.map((e) => e.id);
    expect(ids, ['c1', 'c2']); // rolled back
  });

  test('setFilter refetches with the new kind', () async {
    final repo = _MockRepo();
    when(() => repo.list(kind: CategoryKind.expense, includeArchived: false))
        .thenAnswer((_) async => [_cat('c1', 'Mercado')]);
    when(() => repo.list(kind: CategoryKind.income, includeArchived: false))
        .thenAnswer((_) async => [_cat('c9', 'Salário')]);
    final c = _container(repo);
    await c.read(categoriesControllerProvider.future);

    await c.read(categoriesControllerProvider.notifier)
        .setFilter(kind: CategoryKind.income);

    expect(c.read(categoriesControllerProvider).value!.single.name, 'Salário');
    verify(() => repo.list(kind: CategoryKind.income, includeArchived: false))
        .called(1);
  });
}
```

- [ ] **Step 7: Run it — expect FAIL** (no such file)

Run: `flutter test test/features/categories/presentation/categories_controller_test.dart`
Expected: FAIL — `Target of URI doesn't exist: categories_controller.dart`.

- [ ] **Step 8: Write the controller**

```dart
// lib/features/categories/presentation/categories_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/failure.dart';
import '../data/categories_repository.dart';
import '../domain/category.dart';

typedef CategoryFilter = ({CategoryKind kind, bool includeArchived});

/// Owns the currently-viewed category list. A single notifier (not a family)
/// holding its own [filter]; `setFilter` refetches. Mutations are optimistic
/// and roll back + rethrow on a [Failure] so the screen can surface it.
class CategoriesController extends AsyncNotifier<List<Category>> {
  CategoryFilter _filter = (kind: CategoryKind.expense, includeArchived: false);
  CategoryFilter get filter => _filter;

  CategoriesRepository get _repo => ref.read(categoriesRepositoryProvider);

  @override
  Future<List<Category>> build() =>
      _repo.list(kind: _filter.kind, includeArchived: _filter.includeArchived);

  Future<void> setFilter({CategoryKind? kind, bool? includeArchived}) async {
    _filter = (
      kind: kind ?? _filter.kind,
      includeArchived: includeArchived ?? _filter.includeArchived,
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.list(kind: _filter.kind, includeArchived: _filter.includeArchived),
    );
  }

  Future<void> create(String name, CategoryKind kind) async {
    final previous = state.valueOrNull ?? const <Category>[];
    // A category of the other kind doesn't belong to the visible list; create it
    // without touching state (it appears when the user switches tab).
    if (kind != _filter.kind) {
      await _repo.create(name, kind);
      return;
    }
    final temp = Category(
      id: 'temp-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      kind: kind,
      archived: false,
      createdAt: DateTime.now(),
    );
    state = AsyncData([temp, ...previous]);
    try {
      final created = await _repo.create(name, kind);
      state = AsyncData([created, ...previous]);
    } on Failure {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> rename(String id, String newName) async {
    final previous = state.valueOrNull ?? const <Category>[];
    state = AsyncData([
      for (final c in previous) c.id == id ? c.copyWith(name: newName) : c,
    ]);
    try {
      await _repo.rename(id, newName);
    } on Failure {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> remove(String id) async {
    final previous = state.valueOrNull ?? const <Category>[];
    state = AsyncData([for (final c in previous) if (c.id != id) c]);
    try {
      await _repo.delete(id);
    } on Failure {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final categoriesControllerProvider =
    AsyncNotifierProvider<CategoriesController, List<Category>>(
        CategoriesController.new);
```

- [ ] **Step 9: Run it — expect PASS**

Run: `flutter test test/features/categories/presentation/categories_controller_test.dart`
Expected: PASS.

- [ ] **Step 10: Analyze + commit**

Run: `flutter analyze`
Expected: No issues found.

```bash
git add lib/features/categories/presentation/categories_strings.dart lib/features/categories/presentation/category_validators.dart lib/features/categories/presentation/categories_controller.dart test/features/categories/presentation/category_validators_test.dart test/features/categories/presentation/categories_controller_test.dart
git commit -m "feat(categories): strings, name validator, optimistic list controller"
```

---

## Task 5: Screens — list, form sheet, delete dialog

**Files:**
- Create: `lib/features/categories/presentation/widgets/category_row.dart`
- Create: `lib/features/categories/presentation/widgets/delete_category_dialog.dart`
- Create: `lib/features/categories/presentation/widgets/category_form_sheet.dart`
- Create: `lib/features/categories/presentation/screens/categories_screen.dart`
- Test: `test/features/categories/presentation/categories_screen_test.dart`
- Test: `test/features/categories/presentation/category_form_sheet_test.dart`

**Interfaces:**
- Consumes: `categoriesControllerProvider`, `categoriesRepositoryProvider` (in tests), `Category`, `CategoryKind`, `categoryNameError`, `CategoriesStrings`, design-system primitives.
- Produces: `CategoryRow`, `showDeleteCategoryDialog`, `CategoryFormSheet`, `CategoriesScreen`.

- [ ] **Step 1: Write `CategoryRow`**

```dart
// lib/features/categories/presentation/widgets/category_row.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/category.dart';
import '../categories_strings.dart';

class CategoryRow extends StatelessWidget {
  const CategoryRow({
    super.key,
    required this.category,
    required this.onRename,
    required this.onDelete,
  });

  final Category category;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: category.archived ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.gap),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Row(
          children: [
            CategoryIconChip(isExpense: category.kind == CategoryKind.expense),
            const SizedBox(width: AppSpacing.gap),
            Expanded(
              child: Text(category.name,
                  style: AppText.bodyStrong, overflow: TextOverflow.ellipsis),
            ),
            if (category.archived)
              const _ArchivedTag()
            else
              PopupMenuButton<String>(
                color: AppColors.surfaceRaised,
                icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                onSelected: (v) => v == 'rename' ? onRename() : onDelete(),
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'rename',
                      child: Text(CategoriesStrings.rename, style: AppText.bodyStrong)),
                  PopupMenuItem(
                      value: 'delete',
                      child: Text(CategoriesStrings.delete,
                          style: AppText.bodyStrong.copyWith(color: AppColors.expense))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ArchivedTag extends StatelessWidget {
  const _ArchivedTag();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadii.chipSm),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(CategoriesStrings.archivedTag, style: AppText.caption),
      );
}
```

- [ ] **Step 2: Write `showDeleteCategoryDialog`**

```dart
// lib/features/categories/presentation/widgets/delete_category_dialog.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/category.dart';
import '../categories_strings.dart';

/// Returns true when the user confirms the deletion.
Future<bool> showDeleteCategoryDialog(BuildContext context, Category category) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.sheet,
      title: Text(CategoriesStrings.deleteConfirmTitle, style: AppText.titleSection),
      content: Text(CategoriesStrings.deleteConfirmBody(category.name), style: AppText.body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(CategoriesStrings.cancel, style: AppText.bodyStrong),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(CategoriesStrings.delete,
              style: AppText.bodyStrong.copyWith(color: AppColors.expense)),
        ),
      ],
    ),
  );
  return ok ?? false;
}
```

- [ ] **Step 3: Write `CategoryFormSheet`** (create + rename in one widget)

```dart
// lib/features/categories/presentation/widgets/category_form_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/category.dart';
import '../categories_controller.dart';
import '../categories_strings.dart';
import '../category_validators.dart';

/// Body of the "Nova categoria" / "Renomear categoria" sheet. Pass [existing]
/// to rename (kind is fixed and hidden); otherwise it creates with a kind
/// toggle defaulting to [initialKind].
class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({super.key, this.existing, this.initialKind = CategoryKind.expense});

  final Category? existing;
  final CategoryKind initialKind;

  bool get isCreate => existing == null;

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late CategoryKind _kind = widget.existing?.kind ?? widget.initialKind;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final err = categoryNameError(_name.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final controller = ref.read(categoriesControllerProvider.notifier);
    final name = _name.text.trim();
    try {
      if (widget.isCreate) {
        await controller.create(name, _kind);
      } else {
        await controller.rename(widget.existing!.id, name);
      }
      if (mounted) Navigator.pop(context);
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = f is ConflictFailure ? CategoriesStrings.dupName : f.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isCreate) ...[
          SegmentedToggle(
            segments: const [CategoriesStrings.expense, CategoriesStrings.income],
            selectedIndex: _kind == CategoryKind.expense ? 0 : 1,
            onChanged: (i) =>
                setState(() => _kind = i == 0 ? CategoryKind.expense : CategoryKind.income),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        AppTextField(
          label: CategoriesStrings.nameLabel,
          controller: _name,
          errorText: _error,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: widget.isCreate ? CategoriesStrings.create : CategoriesStrings.save,
          loading: _busy,
          onPressed: _busy ? null : _submit,
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Write `CategoriesScreen`**

```dart
// lib/features/categories/presentation/screens/categories_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/category.dart';
import '../categories_controller.dart';
import '../categories_strings.dart';
import '../widgets/category_form_sheet.dart';
import '../widgets/category_row.dart';
import '../widgets/delete_category_dialog.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  CategoryKind _kind = CategoryKind.expense;
  bool _showArchived = false;

  CategoriesController get _controller =>
      ref.read(categoriesControllerProvider.notifier);

  void _setKind(int i) {
    final k = i == 0 ? CategoryKind.expense : CategoryKind.income;
    if (k == _kind) return;
    setState(() => _kind = k);
    _controller.setFilter(kind: k);
  }

  void _toggleArchived() {
    setState(() => _showArchived = !_showArchived);
    _controller.setFilter(includeArchived: _showArchived);
  }

  void _create() => showFluxySheet(context,
      title: CategoriesStrings.newCategory,
      child: CategoryFormSheet(initialKind: _kind));

  void _rename(Category c) => showFluxySheet(context,
      title: CategoriesStrings.renameTitle, child: CategoryFormSheet(existing: c));

  Future<void> _delete(Category c) async {
    final ok = await showDeleteCategoryDialog(context, c);
    if (!ok) return;
    try {
      await _controller.remove(c.id);
    } on Failure catch (f) {
      if (!mounted) return;
      final msg = f is ConflictFailure ? CategoriesStrings.inUse : f.message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoriesControllerProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Text(CategoriesStrings.tab, style: AppText.titleScreen),
                const Spacer(),
                _AddButton(onTap: _create),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SegmentedToggle(
              segments: const [CategoriesStrings.expense, CategoriesStrings.income],
              selectedIndex: _kind == CategoryKind.expense ? 0 : 1,
              onChanged: _setKind,
            ),
            const SizedBox(height: AppSpacing.gap),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleArchived,
              child: Row(
                children: [
                  Icon(
                    _showArchived ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 18,
                    color: _showArchived ? AppColors.primary : AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(CategoriesStrings.showArchived, style: AppText.label),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: state.when(
                loading: () => const AppLoader(),
                error: (e, _) => AppErrorView(
                  message: e is Failure ? e.message : CategoriesStrings.loadError,
                  onRetry: () => ref.invalidate(categoriesControllerProvider),
                ),
                data: (cats) => cats.isEmpty
                    ? const AppEmptyView(message: CategoriesStrings.empty)
                    : ListView.separated(
                        itemCount: cats.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, i) {
                          final c = cats[i];
                          return CategoryRow(
                            category: c,
                            onRename: () => _rename(c),
                            onDelete: () => _delete(c),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.smBox),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.add, color: AppColors.textPrimary, size: 22),
        ),
      );
}
```

- [ ] **Step 5: Write the failing screen test**

```dart
// test/features/categories/presentation/categories_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/features/categories/data/categories_repository.dart';
import 'package:fluxy_app/features/categories/domain/category.dart';
import 'package:fluxy_app/features/categories/presentation/categories_strings.dart';
import 'package:fluxy_app/features/categories/presentation/screens/categories_screen.dart';
import 'package:fluxy_app/features/categories/presentation/widgets/category_row.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements CategoriesRepository {}

Category _cat(String id, String name, {bool archived = false}) => Category(
      id: id,
      name: name,
      kind: CategoryKind.expense,
      archived: archived,
      createdAt: DateTime.utc(2026, 1, 1),
    );

Widget _host(_MockRepo repo) => ProviderScope(
      overrides: [categoriesRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: Scaffold(body: CategoriesScreen())),
    );

void main() {
  testWidgets('renders the kind toggle and category rows', (tester) async {
    final repo = _MockRepo();
    when(() => repo.list(kind: CategoryKind.expense, includeArchived: false))
        .thenAnswer((_) async => [_cat('c1', 'Mercado')]);

    await tester.pumpWidget(_host(repo));
    await tester.pumpAndSettle();

    expect(find.text(CategoriesStrings.tab), findsOneWidget);
    expect(find.text(CategoriesStrings.expense), findsWidgets); // toggle segment
    expect(find.text('Mercado'), findsOneWidget);
    expect(find.byType(CategoryRow), findsOneWidget);
  });

  testWidgets('empty list shows the empty state', (tester) async {
    final repo = _MockRepo();
    when(() => repo.list(kind: CategoryKind.expense, includeArchived: false))
        .thenAnswer((_) async => const <Category>[]);

    await tester.pumpWidget(_host(repo));
    await tester.pumpAndSettle();

    expect(find.text(CategoriesStrings.empty), findsOneWidget);
  });

  testWidgets('tapping Receita refetches with the income kind', (tester) async {
    final repo = _MockRepo();
    when(() => repo.list(kind: CategoryKind.expense, includeArchived: false))
        .thenAnswer((_) async => [_cat('c1', 'Mercado')]);
    when(() => repo.list(kind: CategoryKind.income, includeArchived: false))
        .thenAnswer((_) async => const <Category>[]);

    await tester.pumpWidget(_host(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text(CategoriesStrings.income));
    await tester.pumpAndSettle();

    verify(() => repo.list(kind: CategoryKind.income, includeArchived: false))
        .called(1);
  });
}
```

- [ ] **Step 6: Run it — expect PASS** (implementation already written in Steps 1–4)

Run: `flutter test test/features/categories/presentation/categories_screen_test.dart`
Expected: PASS.

- [ ] **Step 7: Write the failing form-sheet test**

```dart
// test/features/categories/presentation/category_form_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/features/categories/data/categories_repository.dart';
import 'package:fluxy_app/features/categories/domain/category.dart';
import 'package:fluxy_app/features/categories/presentation/categories_controller.dart';
import 'package:fluxy_app/features/categories/presentation/categories_strings.dart';
import 'package:fluxy_app/features/categories/presentation/widgets/category_form_sheet.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements CategoriesRepository {}

Category _cat(String id, String name) => Category(
      id: id,
      name: name,
      kind: CategoryKind.expense,
      archived: false,
      createdAt: DateTime.utc(2026, 1, 1),
    );

Future<void> _pump(WidgetTester tester, _MockRepo repo) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [categoriesRepositoryProvider.overrideWithValue(repo)],
    child: const MaterialApp(
      home: Scaffold(body: CategoryFormSheet(initialKind: CategoryKind.expense)),
    ),
  ));
}

void main() {
  testWidgets('blank name shows the required error and does not call create',
      (tester) async {
    final repo = _MockRepo();
    await _pump(tester, repo);

    await tester.tap(find.text(CategoriesStrings.create));
    await tester.pump();

    expect(find.text(CategoriesStrings.nameRequired), findsOneWidget);
    verifyNever(() => repo.create(any(), any()));
  });

  testWidgets('valid name calls create with the selected kind', (tester) async {
    final repo = _MockRepo();
    // controller.create needs the initial list to optimistically prepend onto.
    when(() => repo.list(kind: CategoryKind.expense, includeArchived: false))
        .thenAnswer((_) async => const <Category>[]);
    when(() => repo.create('Lazer', CategoryKind.expense))
        .thenAnswer((_) async => _cat('c2', 'Lazer'));
    await _pump(tester, repo);

    await tester.enterText(find.byType(TextField), 'Lazer');
    await tester.tap(find.text(CategoriesStrings.create));
    await tester.pumpAndSettle();

    verify(() => repo.create('Lazer', CategoryKind.expense)).called(1);
  });
}
```

Note: register a `CategoryKind` fallback for the `verifyNever(any(), any())` matcher.

- [ ] **Step 8: Add the mocktail fallback to the form-sheet test**

In `category_form_sheet_test.dart`, add a `setUpAll` registering the `CategoryKind` fallback (required by `any()` for a non-nullable enum argument):

```dart
void main() {
  setUpAll(() => registerFallbackValue(CategoryKind.expense));
  // ... testWidgets blocks ...
}
```

- [ ] **Step 9: Run it — expect PASS**

Run: `flutter test test/features/categories/presentation/category_form_sheet_test.dart`
Expected: PASS.

- [ ] **Step 10: Analyze + commit**

Run: `flutter analyze`
Expected: No issues found.

```bash
git add lib/features/categories/presentation/widgets/ lib/features/categories/presentation/screens/ test/features/categories/presentation/categories_screen_test.dart test/features/categories/presentation/category_form_sheet_test.dart
git commit -m "feat(categories): list screen, form sheet, delete dialog"
```

---

## Task 6: Routing integration + smoke test

**Files:**
- Modify: `lib/app/router.dart` (point `/categories` at `CategoriesScreen`)
- Test: `test/app/categories_routing_test.dart` (new)

**Interfaces:** none new — final wiring + an end-to-end assertion that the real screen renders at `/categories`.

- [ ] **Step 1: Write the failing routing test**

```dart
// test/app/categories_routing_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxy_app/app/router.dart';
import 'package:fluxy_app/core/session/session_status.dart';
import 'package:fluxy_app/features/categories/data/categories_repository.dart';
import 'package:fluxy_app/features/categories/domain/category.dart';
import 'package:fluxy_app/features/categories/presentation/screens/categories_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements CategoriesRepository {}

void main() {
  testWidgets('authenticated /categories renders the real CategoriesScreen',
      (tester) async {
    final repo = _MockRepo();
    when(() => repo.list(kind: CategoryKind.expense, includeArchived: false))
        .thenAnswer((_) async => const <Category>[]);

    final c = ProviderContainer(overrides: [
      sessionStatusProvider.overrideWith((ref) => SessionStatus.authenticated),
      categoriesRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(c.dispose);
    final router = c.read(routerProvider);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    router.go('/categories');
    await tester.pumpAndSettle();

    expect(find.byType(CategoriesScreen), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run it — expect FAIL**

Run: `flutter test test/app/categories_routing_test.dart`
Expected: FAIL — finds `PlaceholderScreen`, not `CategoriesScreen`.

- [ ] **Step 3: Wire the route**

In `lib/app/router.dart`, add the import near the other feature-screen imports:

```dart
import '../features/categories/presentation/screens/categories_screen.dart';
```

Then change the `/categories` shell route builder from:

```dart
GoRoute(path: '/categories', builder: (_, _) => const PlaceholderScreen('Categorias')),
```

to:

```dart
GoRoute(path: '/categories', builder: (_, _) => const CategoriesScreen()),
```

(Leave the other three shell tabs on `PlaceholderScreen`.)

- [ ] **Step 4: Run it — expect PASS**

Run: `flutter test test/app/categories_routing_test.dart`
Expected: PASS.

- [ ] **Step 5: Full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: ALL pass; analyzer "No issues found!". No pending-timer or overflow errors.

- [ ] **Step 6: Commit**

```bash
git add lib/app/router.dart test/app/categories_routing_test.dart
git commit -m "feat(categories): wire Categorias tab into routing"
```

- [ ] **Step 7: Squash the branch to a single commit** (project rule: one commit per branch before PR)

```bash
git reset --soft main
git commit -m "feat(categories): Categorias tab — CRUD with optimistic list"
flutter test && flutter analyze   # verify the squashed tree is green
```

---

## Self-Review

**Spec coverage (spec 03):**
- §2 API surface → Task 3 (`CategoriesApi` wraps `GET/POST/GET/PATCH/DELETE /categories`).
- §3 domain model → Task 2 (`Category` + `CategoryKind`).
- §4 data layer (`list/create/get/rename/delete`, 409 → `ConflictFailure`) → Task 3.
- §5 state & controllers → Task 4. **Deviation (approved):** a single `AsyncNotifier` with `setFilter` replaces a `family` because reading a manual family's argument needs the `@internal` `ref.$arg` (breaks analyze-clean). The lightweight active-by-kind cache provider is **deferred to spec 04** (approved — no consumer exists yet).
- §6 archive vs delete → delete is hard `DELETE`; archived rows are surfaced read-only (dimmed, "Arquivada" tag, no overflow menu, excluded from edits) when "Mostrar arquivadas" is on. **Deviation (approved):** a delete-conflict shows "Categoria em uso e não pode ser excluída." (no archive action — the API exposes none).
- §7 screens → Task 5 (list with toggle + show-archived + empty state + add button; create/rename sheet; delete dialog).
- §8 validation → Task 4 (`categoryNameError`, 1–60 trimmed).
- §9 edge cases → empty state (Task 5), optimistic rollback (Task 4 tests), delete-last allowed (no guard added), archived resolvable via `includeArchived` (Task 3/5).
- §10 acceptance → AC1 (Task 3 list query test), AC2 (Task 4 optimistic prepend test), AC3 (Task 4 rename + rollback test), AC4 (Task 3 delete + 409 test, Task 5 confirm dialog), AC5 (Task 5 toggle/empty/archived rendering), AC6 (active-by-kind picker — deferred to spec 04 with its consumer).

**Placeholder scan:** every code step contains complete, compiling code + commands. No TBD/TODO.

**Type consistency:** `CategoryKind`/`Category` (T2) consumed unchanged by T3–T5; `CategoriesApi`/`CategoriesRepository` method names (`list/create/get/rename/delete`, `rename(id,newName)`) match across T3 and the controller (T4); controller surface (`setFilter/create/rename/remove`, `categoriesControllerProvider`) matches the screens (T5) and tests; primitives `SegmentedToggle({segments,selectedIndex,onChanged})` and `CategoryIconChip({isExpense})` (T1) are consumed unchanged by T5. `categoryNameError` (T4) used by the form sheet (T5).
