import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatter.dart';
import '../core/widgets/app_logo.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'add_transaction_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onGoHistory,
    required this.onGoBudget,
    required this.onGoStats,
  });

  final VoidCallback onGoHistory;
  final VoidCallback onGoBudget;
  final VoidCallback onGoStats;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final summary = state.summary;
    final recent = state.recentTransactions.take(5).toList();
    final usedPct =
        summary == null ? 0 : (summary.budgetPercent * 100).round();
    final now = DateTime.now();
    final monthLabel = '${idMonthsShort[now.month - 1]} ${now.year}';

    if (summary == null && state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _header(context, state),
          Expanded(
            child: RefreshIndicator(
              onRefresh: state.refreshAll,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  _greeting(state, monthLabel),
                  const SizedBox(height: 16),
                  _balanceCard(state, summary),
                  const SizedBox(height: 16),
                  _budgetCard(state, summary, usedPct, onGoBudget),
                  const SizedBox(height: 16),
                  _quickActions(context, onGoBudget, onGoStats),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transaksi Terbaru',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface),
                      ),
                      InkWell(
                        onTap: onGoHistory,
                        child: Row(
                          children: const [
                            Text(
                              'Lihat Semua',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary),
                            ),
                            Icon(Icons.chevron_right,
                                size: 16, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: cardDecoration(),
                    child: recent.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Belum ada transaksi. Tekan + untuk mulai mencatat.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 13, color: AppColors.secondary),
                            ),
                          )
                        : Column(
                            children: [
                              for (var i = 0; i < recent.length; i++) ...[
                                if (i > 0) const Divider(height: 1),
                                TransactionRow(t: recent[i]),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          const AppLogo(size: 36, radius: 10),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Pocketly',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                    letterSpacing: 1.2),
              ),
              Text(
                'Beranda',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface),
              ),
            ],
          ),
          const Spacer(),
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryFixed,
            child: Icon(Icons.person, size: 18, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  String _firstName(AppState state) {
    final name = state.user?.name.trim() ?? 'Mahasiswa';
    return name.split(RegExp(r'\s+')).first;
  }

  Widget _greeting(AppState state, String monthLabel) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, ${_firstName(state)} 👋',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onSurface),
              ),
              const SizedBox(height: 4),
              const Text(
                'Kelola keuanganmu dengan bijak bulan ini',
                style: TextStyle(fontSize: 13, color: AppColors.secondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today, size: 13, color: AppColors.primary),
              const SizedBox(width: 5),
              Text(monthLabel,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _balanceCard(AppState state, Summary? summary) {
    final visible = state.balanceVisible;
    final balance = summary?.balance ?? 0;
    final income = summary?.monthIncome ?? 0;
    final expense = summary?.monthExpense ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF0A8F5F), AppColors.onPrimaryContainer],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x2E006C49), blurRadius: 24, offset: Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -32,
            top: -32,
            child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08), shape: BoxShape.circle)),
          ),
          Positioned(
            right: 16,
            top: 40,
            child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: AppColors.primaryFixed.withValues(alpha: 0.15),
                    shape: BoxShape.circle)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'TOTAL SALDO TERSEDIA',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryFixed,
                        letterSpacing: 0.8),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: state.toggleBalance,
                    child: Icon(
                      visible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: AppColors.primaryFixed.withValues(alpha: 0.85),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999)),
                    child: const Text(
                      'Total Semua Saldo',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Rp',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryFixed)),
                  const SizedBox(width: 6),
                  Text(
                    visible ? formatRupiah(balance) : '••••••••',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -1),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _flowBox('Pemasukan', income, Icons.arrow_downward,
                          AppColors.primaryFixed, visible)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _flowBox('Pengeluaran', expense, Icons.arrow_upward,
                          AppColors.tertiaryFixedDim, visible)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _flowBox(
      String label, int amount, IconData icon, Color accent, bool visible) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration:
                BoxDecoration(color: accent.withValues(alpha: 0.3), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600, color: accent)),
                const SizedBox(height: 2),
                Text(
                  visible ? 'Rp ${formatRupiah(amount)}' : 'Rp •••••',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _budgetCard(
      AppState state, Summary? summary, int usedPct, VoidCallback onGoBudget) {
    final target = summary?.budgetTarget ?? 0;
    final remaining = summary?.budgetRemaining ?? 0;
    final percent = summary?.budgetPercent ?? 0;
    final safe = usedPct < 80;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.track_changes, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              const Text('Anggaran Bulanan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(999)),
                child: Text(
                  '$usedPct% terpakai',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent.clamp(0, 1),
              minHeight: 10,
              backgroundColor: AppColors.surfaceContainer,
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryContainer),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  text: 'Sisa: ',
                  style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                  children: [
                    TextSpan(
                      text: formatRp(remaining),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: AppColors.onSurface),
                    ),
                  ],
                ),
              ),
              Text('Target: ${formatRp(target)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(safe ? Icons.verified : Icons.warning_amber,
                    size: 18,
                    color: safe ? AppColors.primaryContainer : AppColors.tertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    safe
                        ? 'Keren! Pengeluaranmu masih dalam batas aman hemat bulan ini 🎯'
                        : 'Hati-hati, pengeluaranmu sudah mendekati batas budget bulan ini!',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                        height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: onGoBudget,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.tune, size: 16, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text('Atur Budget →',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions(
      BuildContext context, VoidCallback onGoBudget, VoidCallback onGoStats) {
    final items = <(String, IconData, VoidCallback)>[
      (
        'Catat',
        Icons.edit_note_outlined,
        () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const AddTransactionScreen()))
              .then((_) {
            if (context.mounted) context.read<AppState>().refreshAll();
          });
        }
      ),
      ('Atur Budget', Icons.track_changes_outlined, onGoBudget),
      ('Laporan', Icons.pie_chart_outline_outlined, onGoStats),
    ];
    return Row(
      children: [
        for (final (label, icon, action) in items)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: action,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x0A0F172A), blurRadius: 6, offset: Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                            color: AppColors.surfaceContainer, shape: BoxShape.circle),
                        child: Icon(icon, size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class TransactionRow extends StatelessWidget {
  const TransactionRow({super.key, required this.t, this.showDateMeta = true});

  final Trans t;
  final bool showDateMeta;

  @override
  Widget build(BuildContext context) {
    final amountColor = t.isIncome ? AppColors.primary : AppColors.tertiary;
    final sign = t.isIncome ? '+ ' : '- ';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: t.iconBg, shape: BoxShape.circle),
            child: Icon(t.icon, size: 20, color: t.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  showDateMeta
                      ? '${_dayLabel(t.date)} • ${formatTime(t.date)} • ${t.category}'
                      : '${t.category} • ${formatTime(t.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sign${formatRupiah(t.amount)}',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: amountColor),
          ),
        ],
      ),
    );
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(d.year, d.month, d.day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return '${d.day} ${idMonthsShort[d.month - 1]}';
  }
}
