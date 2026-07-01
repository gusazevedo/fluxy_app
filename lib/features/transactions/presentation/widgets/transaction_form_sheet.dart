// lib/features/transactions/presentation/widgets/transaction_form_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../categories/domain/category.dart';
import '../../domain/transaction.dart';
import '../providers.dart';
import '../transaction_validators.dart';
import '../transactions_controller.dart';
import '../transactions_strings.dart';

/// Body of the "Nova transação" / "Editar transação" sheet. Pass [existing] to
/// edit; otherwise it creates. The kind toggle drives which categories the
/// picker offers (a transaction must match its category's kind).
class TransactionFormSheet extends ConsumerStatefulWidget {
  const TransactionFormSheet({super.key, this.existing});

  final Transaction? existing;

  bool get isCreate => existing == null;

  @override
  ConsumerState<TransactionFormSheet> createState() =>
      _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<TransactionFormSheet> {
  late CategoryKind _kind = widget.existing?.kind ?? CategoryKind.expense;
  late String? _categoryId = widget.existing?.categoryId;
  late DateTime _occurredAt = widget.existing?.occurredAt ?? DateTime.now();
  late final TextEditingController _amount = TextEditingController(
      text: widget.existing == null
          ? ''
          : centsToInput(widget.existing!.amountCents));
  late final TextEditingController _description =
      TextEditingController(text: widget.existing?.description ?? '');

  String? _amountErr;
  String? _categoryErr;
  String? _formErr;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  void _selectKind(int i) {
    final k = i == 0 ? CategoryKind.expense : CategoryKind.income;
    if (k == _kind) return;
    setState(() {
      _kind = k;
      _categoryId = null; // categories are kind-specific; clear the selection
      _categoryErr = null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
    );
    if (picked != null) setState(() => _occurredAt = picked);
  }

  Future<void> _submit() async {
    final amountErr = amountError(_amount.text);
    final categoryErr = categoryError(_categoryId);
    if (amountErr != null || categoryErr != null) {
      setState(() {
        _amountErr = amountErr;
        _categoryErr = categoryErr;
      });
      return;
    }
    setState(() {
      _busy = true;
      _formErr = null;
    });

    final cents = parseAmountToCents(_amount.text)!;
    final desc = _description.text.trim();
    final description = desc.isEmpty ? null : desc;
    final controller = ref.read(transactionsControllerProvider.notifier);
    try {
      if (widget.isCreate) {
        await controller.create(
          amountCents: cents,
          kind: _kind,
          categoryId: _categoryId!,
          occurredAt: _occurredAt,
          description: description,
        );
      } else {
        await controller.edit(widget.existing!.copyWith(
          amountCents: cents,
          kind: _kind,
          categoryId: _categoryId!,
          occurredAt: _occurredAt,
          description: description,
        ));
      }
      if (mounted) Navigator.pop(context);
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _formErr = _messageFor(f);
      });
    }
  }

  String _messageFor(Failure f) {
    if (f is NotFoundFailure) return TransactionsStrings.notFound;
    // 409 (archived / kind mismatch) and 400 (invalid amount) carry a
    // server-provided message; fall back to it, then to a generic one.
    return f.message;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SegmentedToggle(
          segments: const [TransactionsStrings.expense, TransactionsStrings.income],
          selectedIndex: _kind == CategoryKind.expense ? 0 : 1,
          onChanged: _selectKind,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: TransactionsStrings.amountLabel,
          controller: _amount,
          hintText: '0,00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          ],
          errorText: _amountErr,
          onChanged: (_) {
            if (_amountErr != null) setState(() => _amountErr = null);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _CategoryPicker(
          kind: _kind,
          selectedId: _categoryId,
          errorText: _categoryErr,
          onChanged: (id) => setState(() {
            _categoryId = id;
            _categoryErr = null;
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        _DateField(date: _occurredAt, onTap: _pickDate),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: TransactionsStrings.descriptionLabel,
          controller: _description,
        ),
        if (_formErr != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_formErr!,
              style: AppText.caption.copyWith(color: AppColors.expense)),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: widget.isCreate
              ? TransactionsStrings.create
              : TransactionsStrings.save,
          loading: _busy,
          onPressed: _busy ? null : _submit,
        ),
      ],
    );
  }
}

/// A kind-aware category dropdown fed by [activeCategoriesProvider].
class _CategoryPicker extends ConsumerWidget {
  const _CategoryPicker({
    required this.kind,
    required this.selectedId,
    required this.errorText,
    required this.onChanged,
  });

  final CategoryKind kind;
  final String? selectedId;
  final String? errorText;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(activeCategoriesProvider(kind));
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(TransactionsStrings.categoryLabel, style: AppText.label),
        ),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.input),
            border: Border.all(
                color: hasError ? AppColors.expense : AppColors.border),
          ),
          child: categories.when(
            loading: () => const Align(
                alignment: Alignment.centerLeft,
                child: Text('...', style: AppText.body)),
            error: (_, _) => const Align(
                alignment: Alignment.centerLeft,
                child: Text(TransactionsStrings.loadError, style: AppText.body)),
            data: (cats) => DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: cats.any((c) => c.id == selectedId) ? selectedId : null,
                hint: Text(TransactionsStrings.categoryHint, style: AppText.body),
                dropdownColor: AppColors.surfaceRaised,
                icon: const Icon(Icons.expand_more, color: AppColors.textMuted),
                style: AppText.bodyStrong,
                onChanged: onChanged,
                items: [
                  for (final c in cats)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(errorText!,
                style: AppText.caption.copyWith(color: AppColors.expense)),
          ),
      ],
    );
  }
}

/// A read-only, tappable field that opens the date picker.
class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  String get _formatted {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(TransactionsStrings.dateLabel, style: AppText.label),
        ),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.input),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(child: Text(_formatted, style: AppText.bodyStrong)),
                const Icon(Icons.calendar_today_outlined,
                    size: 18, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
