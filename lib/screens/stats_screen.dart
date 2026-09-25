import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatter.dart';
import '../core/widgets/app_logo.dart';
import '../models/models.dart';
import '../state/app_state.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.onGoProfile, required this.onGoBudget});

  final VoidCallback onGoProfile;
  final VoidCallback onGoBudget;

  static const periods = ['week', 'month', 'year'];

  String _periodLabel(AppState state, String key) {
    final now = DateTime.now();
    if (key == 'month') {
      return 'Bulan Ini (${idMonthsShort[now.month - 1]} ${now.year})';
    }
    if (key == 'year') return 'Tahun ${now.year}';
    return AppState.periodLabels[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final stats = state.stats;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _header(onGoProfile, onGoBudget),
          Expanded(
            child: stats == null && state.loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => state.loadStats(state.statsPeriod),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      children: [
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: periods.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final p = periods[i];
                              final active = state.statsPeriod == p;
                              return GestureDetector(
                                onTap: () => context.read<AppState>().loadStats(p),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? AppColors.primaryContainer
                                        : AppColors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Color(0x0A000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 1))
                                    ],
                                  ),
                                  child: Text(
                                    _periodLabel(state, p),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          active ? Colors.white : AppColors.secondary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (stats != null) ...[
                          _cashBanner(state, stats),
                          const SizedBox(height: 14),
                          _donutCard(stats),
                          const SizedBox(height: 14),
                          _barCard(stats),
                          const SizedBox(height: 14),
                          _insightCard(stats),
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
              Text('Statistik',
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

  Widget _cashBanner(AppState state, StatsData stats) {
    final budgetLeft = 1 - stats.budgetPercent;
    final safe = stats.budgetPercent < 0.8;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(radius: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
                color: AppColors.surfaceContainer, shape: BoxShape.circle),
            child: const Icon(Icons.savings_outlined, size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SISA SALDO KAS',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                        letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(formatRp(stats.balance),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: safe ? AppColors.primaryFixed : AppColors.tertiaryFixed,
                    borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(safe ? Icons.trending_up : Icons.warning_amber,
                        size: 12,
                        color: safe
                            ? AppColors.onPrimaryFixedVariant
                            : AppColors.tertiary),
                    const SizedBox(width: 3),
                    Text(safe ? 'Aman' : 'Hati-hati',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: safe
                                ? AppColors.onPrimaryFixedVariant
                                : AppColors.tertiary)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text('Budget ${(budgetLeft * 100).round()}% tersisa',
                  style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _donutCard(StatsData stats) {
    final slices = stats.byCategory;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pengeluaran per Kategori',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLow, shape: BoxShape.circle),
                child: const Icon(Icons.tune, size: 16, color: AppColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (slices.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('Belum ada pengeluaran pada periode ini',
                    style: TextStyle(fontSize: 13, color: AppColors.secondary)),
              ),
            )
          else ...[
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 68,
                      sections: [
                        for (final s in slices)
                          PieChartSectionData(
                            value: s.amount.toDouble(),
                            color: s.color,
                            radius: 26,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Total Pengeluaran',
                          style: TextStyle(fontSize: 11, color: AppColors.secondary)),
                      const SizedBox(height: 2),
                      Text(formatRp(stats.expense),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                              letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle,
                              size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('${slices.length} Kategori',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final s in slices) ...[
              _legendRow(s),
              if (s != slices.last) const SizedBox(height: 2),
            ],
          ],
        ],
      ),
    );
  }

  Widget _legendRow(StatSlice s) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: s.iconBg, shape: BoxShape.circle),
            child: Icon(s.icon, size: 16, color: s.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                Text('${s.percentLabel}% dari total',
                    style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(formatRp(s.amount),
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          const SizedBox(width: 8),
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
        ],
      ),
    );
  }

  Widget _barCard(StatsData stats) {
    final monthly = stats.monthly;
    final maxVal =
        monthly.fold<int>(0, (m, b) => b.income > m ? b.income : m);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pemasukan vs Pengeluaran',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('Tren bulan terakhir',
                        style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                  ],
                ),
              ),
              Row(
                children: [
                  _legendDot(AppColors.primaryContainer, 'Masuk'),
                  const SizedBox(width: 10),
                  _legendDot(AppColors.tertiaryContainer, 'Keluar'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: monthly.isEmpty
                ? const Center(
                    child: Text('Belum ada data',
                        style: TextStyle(fontSize: 13, color: AppColors.secondary)))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (maxVal == 0 ? 1 : maxVal) * 1.15,
                      barTouchData: BarTouchData(enabled: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: AppColors.surfaceContainerLow,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= monthly.length) {
                                return const SizedBox.shrink();
                              }
                              final b = monthly[i];
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  b.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: b.current
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: b.current
                                        ? AppColors.primary
                                        : AppColors.secondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < monthly.length; i++)
                          BarChartGroupData(
                            x: i,
                            barsSpace: 4,
                            barRods: [
                              BarChartRodData(
                                toY: monthly[i].income.toDouble(),
                                color: AppColors.primaryContainer,
                                width: 12,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6)),
                              ),
                              BarChartRodData(
                                toY: monthly[i].expense.toDouble(),
                                color: AppColors.tertiaryContainer,
                                width: 12,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6)),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rata-rata Simpanan',
                          style: TextStyle(fontSize: 11, color: AppColors.secondary)),
                      const SizedBox(height: 2),
                      Text('${stats.avgSavings >= 0 ? '+' : ''}${formatRp(stats.avgSavings)}/bln',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: stats.avgSavings >= 0
                                  ? AppColors.primary
                                  : AppColors.error)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Rasio Tabungan',
                        style: TextStyle(fontSize: 11, color: AppColors.secondary)),
                    const SizedBox(height: 2),
                    Text('${(stats.savingsRate * 100).round()}%',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
      ],
    );
  }

  Widget _insightCard(StatsData stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0F172A), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -16,
            bottom: -16,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.primaryFixed.withValues(alpha: 0.3), blurRadius: 24)
                ],
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(999)),
                child: const Text('💡', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('INSIGHT MAHASISWA',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 0.8)),
                        SizedBox(width: 6),
                        DotBullet(),
                        SizedBox(width: 6),
                        Text('Terbaru',
                            style: TextStyle(fontSize: 11, color: AppColors.secondary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stats.insight,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.onSurface, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DotBullet extends StatelessWidget {
  const DotBullet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
          color: AppColors.primaryContainer, shape: BoxShape.circle),
    );
  }
}
