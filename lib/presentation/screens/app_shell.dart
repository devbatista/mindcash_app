import 'package:flutter/material.dart';
import 'package:mindcash_app/domain/services/dashboard_service.dart';
import 'package:mindcash_app/presentation/screens/dashboard_screen.dart';
import 'package:mindcash_app/presentation/widgets/empty_state.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final DashboardService _dashboardService = const DashboardService();

  int _currentIndex = 0;

  static const _screens = <_ShellScreen>[
    _ShellScreen(
      title: 'Inicio',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    _ShellScreen(
      title: 'Transações',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      emptyTitle: 'Nenhuma transação cadastrada',
      emptyMessage:
          'Use o botão de adicionar para registrar receitas, despesas e transferências.',
    ),
    _ShellScreen(
      title: 'Planejamento',
      icon: Icons.event_note_outlined,
      selectedIcon: Icons.event_note,
      emptyTitle: 'Planejamento entra depois do MVP',
      emptyMessage: 'Aqui ficarão recorrências, metas e previsões mensais.',
    ),
    _ShellScreen(
      title: 'Mais',
      icon: Icons.more_horiz,
      selectedIcon: Icons.more,
      emptyTitle: 'Configurações e backup',
      emptyMessage:
          'Aqui ficarão categorias, exportação local e preferências do app.',
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
            ? FutureBuilder(
                future: _dashboardService.getSummary(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return DashboardScreen(summary: snapshot.data!);
                },
              )
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
