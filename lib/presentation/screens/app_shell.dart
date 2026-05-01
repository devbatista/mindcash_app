import 'package:flutter/material.dart';
import 'package:mindcash_app/domain/services/dashboard_service.dart';
import 'package:mindcash_app/presentation/app/app_dependencies.dart';
import 'package:mindcash_app/presentation/screens/accounts_screen.dart';
import 'package:mindcash_app/presentation/screens/cards_screen.dart';
import 'package:mindcash_app/presentation/screens/dashboard_screen.dart';
import 'package:mindcash_app/presentation/screens/more_screen.dart';
import 'package:mindcash_app/presentation/screens/new_transaction_screen.dart';
import 'package:mindcash_app/presentation/screens/transactions_screen.dart';
import 'package:mindcash_app/presentation/widgets/error_state.dart';
import 'package:mindcash_app/presentation/widgets/loading_state.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  DateTime _selectedDashboardMonth = DateTime.now();

  static const _screens = <_ShellScreen>[
    _ShellScreen(
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    _ShellScreen(
      title: 'Transações',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    _ShellScreen(
      title: 'Contas',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
    ),
    _ShellScreen(
      title: 'Cartões',
      icon: Icons.credit_card_outlined,
      selectedIcon: Icons.credit_card,
    ),
    _ShellScreen(
      title: 'Mais',
      icon: Icons.more_horiz,
      selectedIcon: Icons.more,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screen = _screens[_currentIndex];
    final isDashboard = _currentIndex == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isDashboard ? 'MindCash' : screen.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: _openCreateMenu,
              icon: const Icon(Icons.add),
              label: const Text('Novo'),
            ),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: NavigationBar(
        height: 82,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          for (final item in _screens)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.title,
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return switch (_currentIndex) {
      0 => FutureBuilder(
        future: DashboardService(
          AppDependencies.databaseOf(context),
        ).getSummary(month: _selectedDashboardMonth),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorState(
              title: 'Não foi possível carregar o dashboard',
              message: 'Tente novamente em instantes.',
              onRetry: () => setState(() {}),
            );
          }

          if (!snapshot.hasData) {
            return const LoadingState(message: 'Carregando dashboard...');
          }

          return DashboardScreen(
            summary: snapshot.data!,
            selectedMonth: _selectedDashboardMonth,
            onMonthChanged: (month) {
              setState(() => _selectedDashboardMonth = month);
            },
            onShowAllTransactions: () {
              setState(() => _currentIndex = 1);
            },
          );
        },
      ),
      1 => const TransactionsScreen(),
      2 => const AccountsScreen(),
      3 => const CardsScreen(),
      _ => const MoreScreen(),
    };
  }

  Future<void> _openCreateMenu() {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Novo lançamento',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                _CreateActionTile(
                  icon: Icons.arrow_downward,
                  color: Colors.red,
                  title: 'Despesa',
                  subtitle: 'Registrar um gasto ou pagamento',
                  onTap: () => _selectCreateAction(context, 'expense'),
                ),
                _CreateActionTile(
                  icon: Icons.arrow_upward,
                  color: Colors.green,
                  title: 'Receita',
                  subtitle: 'Registrar dinheiro recebido',
                  onTap: () => _selectCreateAction(context, 'income'),
                ),
                _CreateActionTile(
                  icon: Icons.swap_horiz,
                  color: Colors.blue,
                  title: 'Transferência',
                  subtitle: 'Mover saldo entre contas',
                  onTap: () => _selectCreateAction(context, 'transfer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectCreateAction(BuildContext sheetContext, String type) {
    Navigator.of(sheetContext).pop();
    _openNewTransaction(type);
  }

  void _openNewTransaction(String initialType) {
    Navigator.of(context)
        .push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => NewTransactionScreen(initialType: initialType),
          ),
        )
        .then((saved) {
          if (saved ?? false) {
            setState(() {});
          }
        });
  }
}

class _ShellScreen {
  const _ShellScreen({
    required this.title,
    required this.icon,
    required this.selectedIcon,
  });

  final String title;
  final IconData icon;
  final IconData selectedIcon;
}

class _CreateActionTile extends StatelessWidget {
  const _CreateActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: Icon(icon),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}
