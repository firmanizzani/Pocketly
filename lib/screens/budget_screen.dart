import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatter.dart';
import '../core/widgets/app_logo.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late final TextEditingController _targetController;
  final FocusNode _targetFocus = FocusNode();
  bool saving = false;
  int? _serverAmount;
  bool _pendingSync = false;

  @override
  void initState() {
    super.initState();
    final budget = context.read<AppState>().budget;
    _serverAmount = budget?.totalAmount;
    _targetController =
        TextEditingController(text: formatRupiah(budget?.totalAmount ?? 0));
    _targetFocus.addListener(_onTargetFocusChange);
    // Muat budget jika belum ada (hindari loading tanpa akhir)
    if (budget == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<AppState>().refreshAll();
      });
    }
  }

  @override
  void dispose() {
    _targetFocus.removeListener(_onTargetFocusChange);
    _targetController.dispose();
    _targetFocus.dispose();
    super.dispose();
  }

  void _onTargetFocusChange() {
    if (!_targetFocus.hasFocus && _pendingSync && mounted) {
      _applySync();
    }
  }

  void _syncTargetField(int amount) {
    if (_serverAmount == amount && !_pendingSync) return;
    _serverAmount = amount;
    if (_targetFocus.hasFocus) {
      _pendingSync = true;
      return;
    }
    _applySync();
  }

  void _applySync() {
    _pendingSync = false;
    final amount = _serverAmount ?? 0;
    final text = formatRupiah(amount);
    if (_targetController.text != text) {
      _targetController.text = text;
    }
  }

  int _parseTarget() {
    final cleaned = _targetController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  void _addTarget(int delta) {
    final next = _parseTarget() + delta;
    setState(() => _targetController.text = formatRupiah(next));
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    setState(() => saving = true);
    try {
      await state.saveBudget(amount: _parseTarget());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Target Tersimpan!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyimpan. Periksa koneksi.')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final budget = state.budget ??
        BudgetData(
          month: DateTime.now().month,
          year: DateTime.now().year,
          totalAmount: 0,
          totalUsed: 0,
          categories: const [],
        );

    final used = budget.totalUsed;
    final remaining = budget.remaining;
    final percent = budget.percent.clamp(0.0, 1.0);
    final percentLabel = (budget.totalAmount > 0
            ? used / budget.totalAmount * 100
            : 0)
        .round();

    // Sinkronkan input dengan nilai tersimpan (saat data baru dimuat).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncTargetField(budget.totalAmount);
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: state.refreshAll,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Anggaran Bulanan',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSurface,
                                      letterSpacing: -0.5)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 14, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                      'Periode: ${idMonths[budget.month - 1]} ${budget.year}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.secondary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (budget.totalAmount > 0 && budget.percent >= 0.8)
                      _warningBanner(percentLabel, remaining, budget),
                    const SizedBox(height: 14),
                    _gaugeCard(percent, percentLabel, used, remaining,
                        budget.totalAmount, budget.month, budget.year),
                    const SizedBox(height: 14),
                    _editCard(),
                    const SizedBox(height: 14),
                    _allocationsCard(budget),
                    const SizedBox(height: 14),
                    _tipsCard(remaining),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          ),
          const AppLogo(size: 32, radius: 9),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Pocketly',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                      letterSpacing: 1.2)),
              Text('Budget',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _warningBanner(int percentLabel, int remaining, BudgetData budget) {
    final now = DateTime.now();
    final daysLeft =
        DateTime(budget.year, budget.month + 1, 0).difference(now).inDays;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tertiaryFixed,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: AppColors.tertiaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.warning, size: 20, color: AppColors.tertiary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Perhatian Budget Menipis!',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onTertiaryFixed)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.tertiary,
                          borderRadius: BorderRadius.circular(999)),
                      child: Text('$percentLabel%',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Kamu telah menggunakan $percentLabel% dari total budget bulan ini. Tersisa ${daysLeft < 0 ? 0 : daysLeft} hari lagi sebelum akhir bulan. Yuk, rem pengeluaran impulsif!',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.onTertiaryFixedVariant, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gaugeCard(double percent, int percentLabel, int used, int remaining,
      int target, int month, int year) {
    final critical = percentLabel >= 80 && target > 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(radius: 14),
      child: Column(
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: CustomPaint(
              painter: _GaugePainter(
                progress: percent,
                trackColor: AppColors.surfaceContainer,
                progressColor: critical ? AppColors.tertiary : AppColors.primaryContainer,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('TERPAKAI',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                            letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(
                      '$percentLabel%',
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          letterSpacing: -1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      critical ? 'Status Kritis' : 'Status Aman',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: critical ? AppColors.tertiary : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                  child: _metric('Terpakai', formatCompactRp(used), '$percentLabel%',
                      AppColors.tertiary)),
              const SizedBox(width: 8),
              Expanded(
                  child: _metric('Sisa Saldo', formatCompactRp(remaining),
                      '${100 - percentLabel}% sisa', AppColors.primary, subBold: true)),
              const SizedBox(width: 8),
              Expanded(
                  child: _metric('Total Target', formatCompactRp(target),
                      "${idMonthsShort[month - 1]} '${year % 100}", AppColors.onSurface)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, String sub, Color valueColor,
      {bool subBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: valueColor)),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              fontSize: 11,
              color: subBold ? AppColors.primary : AppColors.secondary,
              fontWeight: subBold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _editCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration:
                    BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.edit_note, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              const Expanded(
                  child: Text('Atur Batas Budget Baru',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
              const Text('Bulanan', style: TextStyle(fontSize: 11, color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Nominal Target Baru',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Text('Rp',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _targetController,
                    focusNode: _targetFocus,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                        letterSpacing: -1),
                    decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        filled: false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _incBtn('+100 rb', 100000),
              const SizedBox(width: 8),
              _incBtn('+250 rb', 250000),
              const SizedBox(width: 8),
              _incBtn('+500 rb', 500000),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: saving ? null : _save,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined, size: 20),
              label: const Text('Simpan Perubahan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _incBtn(String label, int delta) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _addTarget(delta),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(12)),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
        ),
      ),
    );
  }

  Widget _allocationsCard(BudgetData budget) {
    final items = budget.categories;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Alokasi per Kategori',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              Text('${items.length} Kategori Aktif',
                  style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Text(
              'Belum ada alokasi per kategori. Atur batas per kategori lewat tombol di bawah.',
              style: TextStyle(fontSize: 12, color: AppColors.secondary, height: 1.4),
            )
          else
            for (final c in items) ...[
              _allocRow(c),
              if (c != items.last) const SizedBox(height: 16),
            ],
          const SizedBox(height: 16),
          const Text('Atur batas per kategori:',
              style: TextStyle(fontSize: 11, color: AppColors.secondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cat in context.read<AppState>().expenseCategories)
                ActionChip(
                  label: Text(cat.name, style: const TextStyle(fontSize: 12)),
                  avatar: Icon(cat.iconData, size: 16, color: AppColors.primary),
                  backgroundColor: AppColors.surfaceContainerLow,
                  onPressed: () => _quickAddCategory(cat),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _quickAddCategory(CategoryModel cat) async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Budget ${cat.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(
              hintText: '0', prefixText: 'Rp '),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal', style: TextStyle(color: AppColors.secondary))),
          TextButton(
            onPressed: () {
              final v =
                  int.tryParse(controller.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              Navigator.of(ctx).pop(v);
            },
            child: const Text('Simpan',
                style:
                    TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      try {
        await context
            .read<AppState>()
            .saveBudget(amount: result, categoryId: cat.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Budget ${cat.name} tersimpan!'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gagal menyimpan. Periksa koneksi.')));
        }
      }
    }
  }

  Widget _allocRow(CategoryBudget c) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: c.iconBg, shape: BoxShape.circle),
              child: Icon(c.icon, size: 17, color: c.iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(c.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface)),
                      ),
                      if (c.over) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(4)),
                          child: const Text('Over',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                  Text(c.statusText, style: TextStyle(fontSize: 11, color: c.statusColor)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Rp ${formatRupiah(c.used)}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: c.over ? AppColors.tertiary : AppColors.onSurface)),
                Text('dari Rp ${formatRupiah(c.limit)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: c.progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.surfaceContainer,
            valueColor: AlwaysStoppedAnimation(c.barColor),
          ),
        ),
      ],
    );
  }

  Widget _tipsCard(int remaining) {
    final daily = remaining > 0 ? remaining ~/ 10 : 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.tips_and_updates, size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              const Text('Tips Hemat Pocketly',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: 'Sisa anggaran tinggal ',
              style: const TextStyle(fontSize: 12, color: AppColors.secondary, height: 1.5),
              children: [
                TextSpan(
                    text: formatRp(remaining),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                const TextSpan(text: ' untuk 10 hari ke depan. Rata-rata batas belanja harianmu adalah '),
                TextSpan(
                    text: '${formatRp(daily)}/hari',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                const TextSpan(
                    text: '. Coba bawa tumbler dan makan di kantin kampus untuk menghemat budget nongkrong!'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide / 2) - 8;
    const stroke = 12.0;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final bar = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress.clamp(0.0, 1.0),
      false,
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.progress != progress || old.progressColor != progressColor;
}