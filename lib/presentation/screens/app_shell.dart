import 'package:flutter/material.dart';
import 'package:mindcash_app/presentation/widgets/empty_state.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const _screens = <_ShellScreen>[
    _ShellScreen(
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      emptyTitle: 'Seu resumo financeiro vai aparecer aqui',
      emptyMessage:
          'Cadastre contas e transacoes para acompanhar saldo, entradas e saidas.',
    ),
    _ShellScreen(
      title: 'Transacoes',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      emptyTitle: 'Nenhuma transacao cadastrada',
      emptyMessage:
          'Use o botao de adicionar para registrar receitas, despesas e transferencias.',
    ),
    _ShellScreen(
      title: 'Contas',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
      emptyTitle: 'Nenhuma conta cadastrada',
      emptyMessage:
          'Suas contas locais serao a base para calcular saldos offline.',
    ),
    _ShellScreen(
      title: 'Cartoes',
      icon: Icons.credit_card_outlined,
      selectedIcon: Icons.credit_card,
      emptyTitle: 'Cartoes entram depois do MVP',
      emptyMessage:
          'Primeiro vamos consolidar contas, categorias e transacoes.',
    ),
    _ShellScreen(
      title: 'Mais',
      icon: Icons.more_horiz,
      selectedIcon: Icons.more,
      emptyTitle: 'Configuracoes e backup',
      emptyMessage:
          'Aqui ficarao categorias, exportacao local e preferencias do app.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screen = _screens[_currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text(screen.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: EmptyState(
            icon: screen.selectedIcon,
            title: screen.emptyTitle,
            message: screen.emptyMessage,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Nova transacao',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
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
}

class _ShellScreen {
  const _ShellScreen({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final String emptyTitle;
  final String emptyMessage;
}
