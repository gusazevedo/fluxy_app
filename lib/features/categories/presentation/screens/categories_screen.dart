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
    if (!ok || !mounted) return;
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
