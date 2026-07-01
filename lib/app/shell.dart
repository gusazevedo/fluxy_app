// lib/app/shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/tokens.dart';
import '../core/widgets/widgets.dart';
import '../features/transactions/presentation/transactions_strings.dart';
import '../features/transactions/presentation/widgets/transaction_form_sheet.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  static const _tabs = ['/', '/transactions', '/categories', '/account'];

  int _indexFor(String location) {
    final i = _tabs.indexWhere((t) => t == '/' ? location == '/' : location.startsWith(t));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    return Scaffold(
      body: child,
      floatingActionButton: (location == '/' || location.startsWith('/transactions'))
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => showFluxySheet(
                context,
                title: TransactionsStrings.newTransaction,
                child: const TransactionFormSheet(),
              ),
              child: const Icon(Icons.add, color: AppColors.onPrimary),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexFor(location),
        onDestinationSelected: (i) => context.go(_tabs[i]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.swap_vert), label: 'Transações'),
          NavigationDestination(icon: Icon(Icons.category_outlined), label: 'Categorias'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Conta'),
        ],
      ),
    );
  }
}
