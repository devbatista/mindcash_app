import 'package:flutter/material.dart';
import 'package:mindcash_app/presentation/screens/dashboard_screen.dart';
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
      title: 'Inicio',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
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
      title: 'Planejamento',
      icon: Icons.event_note_outlined,
      selectedIcon: Icons.event_note,
      emptyTitle: 'Planejamento entra depois do MVP',
      emptyMessage: 'Aqui ficarao recorrencias, metas e previsoes mensais.',
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
    final isDashboard = _currentIndex == 0;

    return Scaffold(
      appBar: isDashboard ? null : AppBar(title: Text(screen.title)),
      body: SafeArea(
        child: isDashboard
            ? const DashboardScreen()
            : Padding(
                padding: const EdgeInsets.all(16),
                child: EmptyState(
                  icon: screen.selectedIcon,
                  title: screen.emptyTitle,
                  message: screen.emptyMessage,
                ),
              ),
      ),
      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          shape: const CircleBorder(),
          onPressed: () {},
          tooltip: 'Nova transacao',
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
}

class _ShellScreen {
  const _ShellScreen({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    this.emptyTitle = '',
    this.emptyMessage = '',
  });

  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final String emptyTitle;
  final String emptyMessage;
}
