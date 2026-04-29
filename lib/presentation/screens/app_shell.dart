import 'package:flutter/material.dart';
import 'package:mindcash_app/domain/services/dashboard_service.dart';
import 'package:mindcash_app/presentation/app/app_dependencies.dart';
import 'package:mindcash_app/presentation/screens/accounts_screen.dart';
import 'package:mindcash_app/presentation/screens/cards_screen.dart';
import 'package:mindcash_app/presentation/screens/dashboard_screen.dart';
import 'package:mindcash_app/presentation/screens/more_screen.dart';
import 'package:mindcash_app/presentation/screens/new_transaction_screen.dart';
import 'package:mindcash_app/presentation/screens/transactions_screen.dart';

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
      appBar: isDashboard ? null : AppBar(title: Text(screen.title)),
      body: SafeArea(child: _buildBody()),
      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          shape: const CircleBorder(),
          onPressed: _openNewTransaction,
          tooltip: 'Nova transação',
          child: const Icon(Icons.add, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
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

  void _openNewTransaction() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NewTransactionScreen()),
    );
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
