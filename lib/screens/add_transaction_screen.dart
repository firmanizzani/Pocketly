import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatter.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, this.existing});

  final Trans? existing;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late bool isExpense;
  late String amountText;
  int? selectedCategoryId;
  late final TextEditingController amountController;
  late final TextEditingController noteController;
  late DateTime date;
  late String source;
  bool saving = false;

  bool get isEditing => widget.existing != null;

  int get _amount =>
      int.tryParse(amountText.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  Color get _amountColor => isExpense ? AppColors.tertiary : AppColors.primary;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    isExpense = t == null || !t.isIncome;
    amountText = t == null ? '' : formatRupiah(t.amount);
    amountController = TextEditingController(text: amountText);
    selectedCategoryId = t?.categoryId;
    noteController = TextEditingController(text: t?.note ?? '');
    date = t?.date ?? DateTime.now();
    source = t?.source ?? 'Tunai';
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => date = picked);
  }

  Future<void> _save() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal transaksi!')),
      );
      return;
    }
    final state = context.read<AppState>();
    final categoryId = selectedCategoryId ??
        (isExpense
            ? state.expenseCategories.firstOrNull?.id
            : state.incomeCategories.firstOrNull?.id);
    if (categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu!')),
      );
      return;
    }

    setState(() => saving = true);
    try {
      if (isEditing) {
        await state.updateTransaction(
          id: widget.existing!.id!,
          type: isExpense ? 'expense' : 'income',
          amount: _amount,
          categoryId: categoryId,
          date: date,
          source: source,
          note: noteController.text.trim(),
        );
      } else {
        await state.addTransaction(
          type: isExpense ? 'expense' : 'income',
          amount: _amount,
          categoryId: categoryId,
          date: date,
          source: source,
          note: noteController.text.trim(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Transaksi diperbarui!' : 'Transaksi tersimpan!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan. Periksa koneksi.')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cats =
        isExpense ? state.expenseCategories : state.incomeCategories;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  _segmented(),
                  const SizedBox(height: 14),
                  _amountCard(),
                  const SizedBox(height: 14),
                  _categoryCard(cats),
                  const SizedBox(height: 14),
                  _detailCard(),
                  const SizedBox(height: 14),
                  _sourceCard(),
                  const SizedBox(height: 16),
                  _saveButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          ),
          Expanded(
            child: Text(
              isEditing ? 'Edit Transaksi' : 'Tambah Transaksi',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _segmented() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))
        ],
      ),
      child: Row(
        children: [
          _segBtn(true, Icons.arrow_downward, 'Pengeluaran', AppColors.tertiary),
          _segBtn(false, Icons.arrow_upward, 'Pemasukan', AppColors.primary),
        ],
      ),
    );
  }

  Widget _segBtn(bool expense, IconData icon, String label, Color color) {
    final active = isExpense == expense;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          isExpense = expense;
          selectedCategoryId = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? color : AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: active ? color : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(radius: 14),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -24,
            child: Container(
              width: 96,
              height: 96,
              decoration:
                  BoxDecoration(color: AppColors.surfaceContainerLow, shape: BoxShape.circle),
            ),
          ),
          Column(
            children: [
              const Text('Nominal Transaksi',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('Rp',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w600, color: _amountColor)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: amountController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: _amountColor,
                        letterSpacing: -1,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        hintText: '0',
                      ),
                      onChanged: (v) {
                        final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                        final formatted =
                            digits.isEmpty ? '' : formatRupiah(int.parse(digits));
                        amountText = formatted;
                        amountController.value = TextEditingValue(
                          text: formatted,
                          selection:
                              TextSelection.collapsed(offset: formatted.length),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _preset('+5rb', 5000),
                  const SizedBox(width: 8),
                  _preset('+25rb', 25000),
                  const SizedBox(width: 8),
                  _preset('+50rb', 50000),
                  const SizedBox(width: 8),
                  _preset('+100rb', 100000),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _preset(String label, int value) {
    return GestureDetector(
      onTap: () {
        final formatted = formatRupiah(value);
        setState(() {
          amountText = formatted;
          amountController.text = formatted;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(999)),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
      ),
    );
  }

  Widget _categoryCard(List<CategoryModel> cats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(radius: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pilih Kategori',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              Text('${cats.length} Kategori',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
            children: [for (final c in cats) _catTile(c)],
          ),
        ],
      ),
    );
  }

  Widget _catTile(CategoryModel c) {
    final active = selectedCategoryId == c.id;
    return GestureDetector(
      onTap: () => setState(() => selectedCategoryId = c.id),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: AppColors.primaryContainer.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppColors.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(c.iconData,
                  size: 22, color: active ? Colors.white : AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              c.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? Colors.white : AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(radius: 14),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Waktu Transaksi',
                        style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                  ),
                  Flexible(
                    child: Text(
                      formatDayLabel(date, short: true),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(999)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Ubah',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceVariant)),
                        Icon(Icons.chevron_right,
                            size: 14, color: AppColors.onSurfaceVariant),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Catatan (Opsional)',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: noteController,
            style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
            decoration: const InputDecoration(
              hintText: 'Contoh: Nasi padang & es teh kantin baru',
              prefixIcon: Icon(Icons.edit_note, size: 18, color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourceCard() {
    const sources = ['Tunai', 'Bank', 'E-wallet'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('Sumber Dana:', style: TextStyle(fontSize: 14, color: AppColors.onSurface)),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: source,
                isExpanded: true,
                items: [
                  for (final s in sources)
                    DropdownMenuItem(
                      value: s,
                      child: Text(s,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                ],
                onChanged: (v) => setState(() => source = v ?? 'Tunai'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryContainer.withValues(alpha: 0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 20),
                  SizedBox(width: 8),
                  Text('Simpan Transaksi',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }
}
