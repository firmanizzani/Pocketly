import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../state/app_state.dart';
import 'add_transaction_screen.dart';
import 'budget_screen.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  /// Nav indices: 0 Beranda, 1 Riwayat, 3 Statistik, 4 Profil (2 = FAB slot)
  int navIndex = 0;

  void goTo(int i) {
    setState(() => navIndex = i);
    final state = context.read<AppState>();
    if (i == 1) state.loadHistory(state.historyMonth, state.historyYear);
    if (i == 3) state.loadStats(state.statsPeriod);
    if (i == 0) state.refreshAll();
  }

  void openBudget() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BudgetScreen(onBack: () => Navigator.of(context).pop())),
    );
  }

  int get _stackIndex {
    switch (navIndex) {
      case 1:
        return 1;
      case 3:
        return 2;
      case 4:
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: IndexedStack(
        index: _stackIndex,
        children: [
          DashboardScreen(onGoHistory: () => goTo(1), onGoBudget: openBudget, onGoStats: () => goTo(3)),
          HistoryScreen(onGoProfile: () => goTo(4), onGoBudget: openBudget),
          StatsScreen(onGoProfile: () => goTo(4), onGoBudget: openBudget),
          ProfileScreen(onGoHome: () => goTo(0), onGoBudget: openBudget),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 28),
        child: SizedBox(
          width: 56,
          height: 56,
          child: FloatingActionButton(
            heroTag: 'add_tx',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
              );
              if (context.mounted) context.read<AppState>().refreshAll();
            },
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: Colors.white,
            elevation: 6,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, size: 28),
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        index: navIndex,
        onTap: goTo,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _item(0, Icons.home_outlined, Icons.home, 'Beranda'),
              _item(1, Icons.schedule_outlined, Icons.schedule, 'Riwayat'),
              const Expanded(child: SizedBox()),
              _item(3, Icons.bar_chart_outlined, Icons.bar_chart, 'Statistik'),
              _item(4, Icons.person_outline, Icons.person, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int i, IconData icon, IconData activeIcon, String label) {
    final active = index == i;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? activeIcon : icon,
              size: 24,
              color: active ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
