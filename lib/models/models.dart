import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

int asInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.split('.').first) ?? 0;
  return 0;
}

double asDouble(Object? v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

IconData iconDataFromKey(String key) {
  switch (key) {
    case 'restaurant':
      return Icons.restaurant;
    case 'two_wheeler':
      return Icons.two_wheeler;
    case 'school':
      return Icons.school;
    case 'sports_esports':
      return Icons.sports_esports;
    case 'home':
      return Icons.home;
    case 'payments':
      return Icons.payments;
    case 'family_restroom':
      return Icons.family_restroom;
    case 'storefront':
      return Icons.storefront;
    case 'add_circle':
      return Icons.add_circle;
    case 'more_horiz':
    default:
      return Icons.more_horiz;
  }
}

(Color, Color) paletteFor(String filterKey, bool isIncome) {
  if (isIncome) {
    return (AppColors.primaryFixed, AppColors.onPrimaryFixedVariant);
  }
  switch (filterKey) {
    case 'makan':
      return (AppColors.tertiaryFixed, AppColors.tertiary);
    case 'transport':
      return (AppColors.secondaryContainer, AppColors.secondary);
    case 'kuliah':
      return (AppColors.surfaceContainerHigh, AppColors.primary);
    case 'hiburan':
      return (AppColors.secondaryFixed, AppColors.onSecondaryFixed);
    case 'kos':
      return (AppColors.errorContainer, AppColors.error);
    default:
      return (AppColors.surfaceContainerHigh, AppColors.onSurfaceVariant);
  }
}

class UserProfile {
  const UserProfile({required this.id, required this.name, required this.email});

  final String id;
  final String name;
  final String email;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'].toString(),
        name: json['name'] as String,
        email: json['email'] as String,
      );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(1, 2)).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
  });

  final int id;
  final String name;
  final String type;
  final String icon;

  bool get isIncome => type == 'income';
  IconData get iconData => iconDataFromKey(icon);
  String get filterKey => name.toLowerCase();

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as int,
        name: json['name'] as String,
        type: json['type'] as String,
        icon: json['icon'] as String,
      );
}

class Trans {
  const Trans({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.category,
    required this.amount,
    required this.isIncome,
    required this.date,
    required this.source,
    this.note,
    this.iconKey = 'more_horiz',
  });

  final String? id;
  final int? categoryId;
  final String title;
  final String category;
  final int amount;
  final bool isIncome;
  final DateTime date;
  final String source;
  final String? note;
  final String iconKey;

  String get filterKey => category.toLowerCase();
  IconData get icon => iconDataFromKey(iconKey);
  Color get iconBg => paletteFor(filterKey, isIncome).$1;
  Color get iconColor => paletteFor(filterKey, isIncome).$2;

  factory Trans.fromJson(Map<String, dynamic> json) {
    final category = (json['categoryName'] ?? '') as String;
    final note = json['note'] as String?;
    return Trans(
      id: json['id']?.toString(),
      categoryId: json['categoryId'] as int?,
      title: (note != null && note.isNotEmpty) ? note : category,
      category: category,
      amount: json['amount'] as int,
      isIncome: json['type'] == 'income',
      date: DateTime.parse(json['date'] as String),
      source: (json['source'] ?? 'Tunai') as String,
      note: note,
      iconKey: (json['categoryIcon'] ?? 'more_horiz') as String,
    );
  }
}

class Summary {
  const Summary({
    required this.balance,
    required this.monthIncome,
    required this.monthExpense,
    required this.budgetTarget,
    required this.budgetUsed,
  });

  final int balance;
  final int monthIncome;
  final int monthExpense;
  final int budgetTarget;
  final int budgetUsed;

  int get budgetRemaining => (budgetTarget - budgetUsed).clamp(0, 1 << 31);
  double get budgetPercent =>
      budgetTarget > 0 ? (budgetUsed / budgetTarget).clamp(0.0, 1.0) : 0;

  factory Summary.fromJson(Map<String, dynamic> json) {
    final budget = json['budget'] as Map<String, dynamic>? ?? const {};
    return Summary(
      balance: asInt(json['balance']),
      monthIncome: asInt(json['monthIncome']),
      monthExpense: asInt(json['monthExpense']),
      budgetTarget: asInt(budget['target']),
      budgetUsed: asInt(budget['used']),
    );
  }
}

class CategoryBudget {
  const CategoryBudget({
    required this.categoryId,
    required this.name,
    required this.iconKey,
    required this.limit,
    required this.used,
    required this.over,
    required this.statusText,
    required this.statusColor,
    required this.barColor,
  });

  final int? categoryId;
  final String name;
  final String iconKey;
  final int limit;
  final int used;
  final bool over;
  final String statusText;
  final Color statusColor;
  final Color barColor;

  IconData get icon => iconDataFromKey(iconKey);
  (Color, Color) get palette => paletteFor(name.toLowerCase(), false);
  Color get iconBg => palette.$1;
  Color get iconColor => palette.$2;
  double get progress => limit > 0 ? used / limit : 0;

  factory CategoryBudget.fromJson(Map<String, dynamic> json) {
    final limit = asInt(json['amount']);
    final used = asInt(json['used']);
    final percent = limit > 0 ? used / limit : 0.0;
    final pctLabel = limit > 0 ? (percent * 100).round() : 0;
    final over = limit > 0 && used > limit;

    String statusText;
    Color statusColor;
    Color barColor;

    if (limit == 0) {
      statusText = 'Belum ada batas';
      statusColor = AppColors.secondary;
      barColor = AppColors.surfaceContainer;
    } else if (used == 0) {
      statusText = '0% terpakai (Utuh)';
      statusColor = AppColors.primary;
      barColor = AppColors.primaryContainer;
    } else if (used == limit) {
      statusText = '100% pas (terpenuhi)';
      statusColor = AppColors.secondary;
      barColor = AppColors.secondary;
    } else if (over) {
      statusText = '$pctLabel% terpakai (+${formatCompactNumber(used - limit)})';
      statusColor = AppColors.error;
      barColor = AppColors.error;
    } else if (percent >= 0.8) {
      statusText = '$pctLabel% terpakai';
      statusColor = AppColors.tertiary;
      barColor = AppColors.tertiaryContainer;
    } else {
      statusText = '$pctLabel% terpakai (Aman)';
      statusColor = AppColors.primary;
      barColor = AppColors.primaryContainer;
    }

    return CategoryBudget(
      categoryId: json['categoryId'] as int?,
      name: (json['name'] ?? 'Tanpa Kategori') as String,
      iconKey: (json['icon'] ?? 'more_horiz') as String,
      limit: limit,
      used: used,
      over: over,
      statusText: statusText,
      statusColor: statusColor,
      barColor: barColor,
    );
  }

  CategoryBudget withLimit(int newLimit) => CategoryBudget.fromJson({
        'categoryId': categoryId,
        'name': name,
        'icon': iconKey,
        'amount': newLimit,
        'used': used,
      });
}

String formatCompactNumber(int amount) {
  if (amount >= 1000) {
    final v = amount ~/ 1000;
    return '$v rb';
  }
  return '$amount';
}

class BudgetData {
  const BudgetData({
    required this.month,
    required this.year,
    required this.totalAmount,
    required this.totalUsed,
    required this.categories,
  });

  final int month;
  final int year;
  final int totalAmount;
  final int totalUsed;
  final List<CategoryBudget> categories;

  int get remaining => (totalAmount - totalUsed).clamp(0, 1 << 31);
  double get percent =>
      totalAmount > 0 ? (totalUsed / totalAmount).clamp(0.0, 1.0) : 0;
  int get percentLabel => (totalAmount > 0 ? totalUsed / totalAmount : 0) * 100 ~/ 1;

  factory BudgetData.fromJson(Map<String, dynamic> json) {
    final total = json['total'] as Map<String, dynamic>? ?? const {};
    return BudgetData(
      month: asInt(json['month']),
      year: asInt(json['year']),
      totalAmount: asInt(total['amount']),
      totalUsed: asInt(total['used']),
      categories: ((json['categories'] as List?) ?? const [])
          .map((e) => CategoryBudget.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StatSlice {
  const StatSlice({
    required this.label,
    required this.amount,
    required this.percent,
    required this.color,
    required this.iconBg,
    required this.icon,
  });

  final String label;
  final int amount;
  final double percent;
  final Color color;
  final Color iconBg;
  final IconData icon;

  int get percentLabel => (percent * 100).round();

  factory StatSlice.fromJson(Map<String, dynamic> json) => StatSlice(
        label: json['name'] as String,
        amount: asInt(json['amount']),
        percent: asDouble(json['percent']),
        color: _colorFromHex(json['color'] as String),
        iconBg: _colorFromHex(json['iconBg'] as String),
        icon: iconDataFromKey(json['icon'] as String),
      );
}

class MonthBar {
  const MonthBar({
    required this.label,
    required this.income,
    required this.expense,
    this.current = false,
  });

  final String label;
  final int income;
  final int expense;
  final bool current;
}

class StatsData {
  const StatsData({
    required this.balance,
    required this.income,
    required this.expense,
    required this.byCategory,
    required this.monthly,
    required this.avgSavings,
    required this.savingsRate,
    required this.budgetPercent,
    required this.insight,
  });

  final int balance;
  final int income;
  final int expense;
  final List<StatSlice> byCategory;
  final List<MonthBar> monthly;
  final int avgSavings;
  final double savingsRate;
  final double budgetPercent;
  final String insight;

  factory StatsData.fromJson(Map<String, dynamic> json) {
    final monthlyRaw =
        ((json['monthly'] as List?) ?? const []).cast<Map<String, dynamic>>();
    final monthly = monthlyRaw
        .map((m) => MonthBar(
              label: m['label'] as String? ?? '',
              income: asInt(m['income']),
              expense: asInt(m['expense']),
              current: m == monthlyRaw.last,
            ))
        .toList();
    final budget = json['budget'] as Map<String, dynamic>? ?? const {};
    return StatsData(
      balance: asInt(json['balance']),
      income: asInt(json['income']),
      expense: asInt(json['expense']),
      byCategory: ((json['byCategory'] as List?) ?? const [])
          .map((e) => StatSlice.fromJson(e as Map<String, dynamic>))
          .toList(),
      monthly: monthly,
      avgSavings: asInt(json['avgSavings']),
      savingsRate: asDouble(json['savingsRate']),
      budgetPercent: asDouble(budget['percent']),
      insight: json['insight'] as String? ?? '',
    );
  }
}

Color _colorFromHex(String hex) {
  var h = hex.replaceAll('#', '');
  if (h.startsWith('rgba') || h.startsWith('rgb')) {
    final nums = h
        .replaceAll(RegExp(r'rgba?\(|\)'), '')
        .split(',')
        .map((s) => double.tryParse(s.trim()) ?? 0)
        .toList();
    if (nums.length >= 4) {
      return Color.fromARGB(
        (nums[3] * 255).round(),
        nums[0].round(),
        nums[1].round(),
        nums[2].round(),
      );
    }
    if (nums.length == 3) {
      return Color.fromARGB(255, nums[0].round(), nums[1].round(), nums[2].round());
    }
    return AppColors.secondary;
  }
  if (h.length == 6) h = 'FF$h';
  final value = int.tryParse(h, radix: 16);
  return value == null ? AppColors.secondary : Color(value);
}
