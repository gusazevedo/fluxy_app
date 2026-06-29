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
