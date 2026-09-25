import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatter.dart';
import '../core/widgets/app_logo.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'add_transaction_screen.dart';
import 'dashboard_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.onGoProfile, required this.onGoBudget});

  final VoidCallback onGoProfile;
  final VoidCallback onGoBudget;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final filter = state.historyFilter;

    final filtered = state.transactions.where((t) {
      if (filter == 'Semua') return true;
      if (filter == 'Pemasukan') return t.isIncome;
      return t.category.toLowerCase() == filter.toLowerCase() && !t.isIncome;
    }).toList();

    final groups = <String, List<Trans>>{};
    for (final t in filtered) {
      final key = formatDayLabel(t.date, short: true);
      groups.putIfAbsent(key, () => []).add(t);
    }

    final expense =
        filtered.where((t) => !t.isIncome).fold<int>(0, (s, t) => s + t.amount);
    final income =
        filtered.where((t) => t.isIncome).fold<int>(0, (s, t) => s + t.amount);

    final chips = [
      'Semua',
      ...state.expenseCategories.map((c) => c.name),
      'Pemasukan',
    ];

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _header(onGoProfile, onGoBudget),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => state.loadHistory(state.historyMonth, state.historyYear),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  _summaryCard(state, expense, income),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: chips.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final f = chips[i];
                        final active = state.historyFilter == f;
                        return GestureDetector(
                          onTap: () => context.read<AppState>().setHistoryFilter(f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:
                                  active ? AppColors.primaryContainer : Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1))
                              ],
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: active ? Colors.white : AppColors.secondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (groups.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: cardDecoration(),
                      child: const Center(
                        child: Text('Belum ada transaksi pada filter ini',
                            style: TextStyle(color: AppColors.secondary, fontSize: 13)),
                      ),
                    )
                  else
                    for (final entry in groups.entries) ...[
                      _dayGroup(context, entry.key, entry.value),
                      const SizedBox(height: 14),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(VoidCallback onGoProfile, VoidCallback onGoBudget) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          const AppLogo(size: 36, radius: 10),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Pocketly',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                      letterSpacing: 1.2)),
              Text('Riwayat',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: onGoBudget,
            icon: const Icon(Icons.account_balance_wallet_outlined,
                color: AppColors.onSurfaceVariant),
          ),
          GestureDetector(
            onTap: onGoProfile,
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryFixed,
              child: Icon(Icons.person, size: 18, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(AppState state, int expense, int income) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(radius: 14),
      child: Column(
        children: [
          Row(
            children: [
              _circleBtn(Icons.chevron_left, () {
                var m = state.historyMonth - 1;
                var y = state.historyYear;
                if (m < 1) {
                  m = 12;
                  y -= 1;
                }
                state.loadHistory(m, y);
              }),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month, size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text('${idMonths[state.historyMonth - 1]} ${state.historyYear}',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                    const Icon(Icons.expand_more, size: 18, color: AppColors.secondary),
                  ],
                ),
              ),
              _circleBtn(Icons.chevron_right, () {
                var m = state.historyMonth + 1;
                var y = state.historyYear;
                if (m > 12) {
                  m = 1;
                  y += 1;
                }
                state.loadHistory(m, y);
              }),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Expanded(child: _flowTile('Pengeluaran', expense, false)),
                const SizedBox(width: 8),
                Expanded(child: _flowTile('Pemasukan', income, true)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(color: AppColors.surfaceContainer, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: AppColors.onSurface),
      ),
    );
  }

  Widget _flowTile(String label, int amount, bool isIncome) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isIncome
                  ? AppColors.primaryContainer.withValues(alpha: 0.2)
                  : AppColors.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: isIncome ? AppColors.primary : AppColors.error,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
                Text(
                  'Rp ${formatRupiah(amount)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isIncome ? AppColors.primary : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayGroup(BuildContext context, String label, List<Trans> items) {
    final net = items.fold<int>(0, (s, t) => s + (t.isIncome ? t.amount : -t.amount));
    final netColor = net >= 0 ? AppColors.primary : AppColors.error;
    final netSign = net >= 0 ? '+ ' : '- ';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
              Text(
                '$netSign${formatRupiah(net.abs())}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: netColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: cardDecoration(radius: 14),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _txTile(context, items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _txTile(BuildContext context, Trans t) {
    return InkWell(
      onTap: () => _showActions(context, t),
      child: TransactionRow(t: t, showDateMeta: false),
    );
  }

  void _showActions(BuildContext context, Trans t) {
    final state = context.read<AppState>();
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(t.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('${t.category} • ${formatRp(t.amount)}',
                style: const TextStyle(fontSize: 13, color: AppColors.secondary)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
              title: const Text('Ubah Transaksi'),
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => AddTransactionScreen(existing: t)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Hapus Transaksi',
                  style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.of(ctx).pop();
                if (t.id == null) return;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Text('Hapus transaksi?'),
                    content: const Text('Transaksi yang dihapus tidak dapat dikembalikan.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(d).pop(false),
                          child: const Text('Batal')),
                      TextButton(
                          onPressed: () => Navigator.of(d).pop(true),
                          child: const Text('Hapus',
                              style: TextStyle(color: AppColors.error))),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await state.deleteTransaction(t.id!);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
