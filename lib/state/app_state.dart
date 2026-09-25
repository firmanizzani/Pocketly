import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_client.dart';

class AppState extends ChangeNotifier {
  final ApiClient api = ApiClient();

  bool ready = false;
  bool isLoggedIn = false;
  bool loading = false;
  String? errorMessage;

  bool balanceVisible = true;
  bool budgetReminder = true;
  bool rememberMe = true;
  String? avatarPath;

  UserProfile? user;
  List<CategoryModel> categories = [];
  List<Trans> recentTransactions = [];
  List<Trans> transactions = [];
  Summary? summary;
  BudgetData? budget;
  StatsData? stats;

  int historyMonth = DateTime.now().month;
  int historyYear = DateTime.now().year;
  String historyFilter = 'Semua';
  String statsPeriod = 'month';

  static const Map<String, String> periodLabels = {
    'week': 'Minggu Ini',
    'month': 'Bulan Ini',
    'year': 'Tahun Ini',
  };

  List<CategoryModel> get expenseCategories =>
      categories.where((c) => !c.isIncome).toList();

  List<CategoryModel> get incomeCategories {
    final list = categories.where((c) => c.isIncome).toList();
    final orangTua = list.where((c) => c.name == 'Orang tua').toList();
    final rest = list.where((c) => c.name != 'Orang tua').toList();
    return [...orangTua, ...rest];
  }

  Future<void> init() async {
    String? token;
    try {
      rememberMe = await api.readRememberMe();
      avatarPath = await api.readAvatarPath();
      token = await api.readToken();
    } catch (_) {
      token = null;
    }

    if (token == null) {
      ready = true;
      notifyListeners();
      return;
    }

    try {
      final res = await api
          .get('/auth/me')
          .timeout(const Duration(seconds: 8));
      user = UserProfile.fromJson(res['user'] as Map<String, dynamic>);
      await api.saveCachedUser(jsonEncode(res['user']));
      isLoggedIn = true;
      await _loadCoreData();
    } on ApiException catch (e) {
      // 401/403/404 = sesi tidak valid (token lama, id berubah, dsb).
      if (e.status == 401 || e.status == 403 || e.status == 404) {
        await _forceLogout();
      } else {
        // Error server (5xx dll) → pertahankan sesi, pakai cache.
        await _restoreCachedSession();
      }
    } catch (_) {
      // Timeout / backend tidak jalan / error jaringan → JANGAN hapus token.
      await _restoreCachedSession();
    } finally {
      ready = true;
      notifyListeners();
    }
  }

  Future<void> _forceLogout() async {
    try {
      await api.clearToken();
    } catch (_) {}
    try {
      await api.saveCachedUser('');
    } catch (_) {}
    isLoggedIn = false;
    user = null;
    categories = [];
    recentTransactions = [];
    transactions = [];
    summary = null;
    budget = null;
    stats = null;
  }

  Future<void> _restoreCachedSession() async {
    isLoggedIn = true;
    if (user == null) {
      try {
        final cached = await api.readCachedUser();
        if (cached != null && cached.isNotEmpty) {
          final decoded = jsonDecode(cached) as Map<String, dynamic>;
          // Abaikan cache lama yang id-nya bukan format baru (user001).
          final id = decoded['id'].toString();
          if (RegExp(r'^user\d{3,}$').hasMatch(id)) {
            user = UserProfile.fromJson(decoded);
          }
        }
      } catch (_) {}
    }
    // Muat data di background agar splash tidak menunggu timeout.
    unawaited(_loadCoreData());
  }

  Future<void> login(String email, String password) async {
    final res = await api.post('/auth/login', {
      'email': email,
      'password': password,
      'rememberMe': rememberMe,
    });
    await api.saveToken(res['token'] as String);
    await api.saveRememberMe(rememberMe);
    await api.saveCachedUser(jsonEncode(res['user']));
    user = UserProfile.fromJson(res['user'] as Map<String, dynamic>);
    isLoggedIn = true;
    await _loadCoreData();
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    final res = await api.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'rememberMe': rememberMe,
    });
    await api.saveToken(res['token'] as String);
    await api.saveRememberMe(rememberMe);
    await api.saveCachedUser(jsonEncode(res['user']));
    user = UserProfile.fromJson(res['user'] as Map<String, dynamic>);
    isLoggedIn = true;
    await _loadCoreData();
    notifyListeners();
  }

  Future<void> logout() async {
    await api.clearToken();
    try {
      await api.saveCachedUser('');
    } catch (_) {}
    isLoggedIn = false;
    user = null;
    avatarPath = null;
    categories = [];
    recentTransactions = [];
    transactions = [];
    summary = null;
    budget = null;
    stats = null;
    notifyListeners();
  }

  Future<void> setAvatarPath(String path) async {
    avatarPath = path;
    await api.saveAvatarPath(path);
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? email}) async {
    final res = await api.put('/auth/me', {
      'name': ?name,
      'email': ?email,
    });
    user = UserProfile.fromJson(res['user'] as Map<String, dynamic>);
    await api.saveCachedUser(jsonEncode(res['user']));
    notifyListeners();
  }

  Future<(dynamic, Object?)> _guard(Future<dynamic> request) async {
    try {
      return (await request, null);
    } catch (e) {
      return (null, e);
    }
  }

  Future<void> _loadCoreData() async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    final now = DateTime.now();
    final results = await Future.wait([
      _guard(api.get('/categories')),
      _guard(api.get('/summary?month=${now.month}&year=${now.year}')),
      _guard(api.get('/transactions?recent=5')),
      _guard(api.get('/transactions?month=$historyMonth&year=$historyYear')),
      _guard(api.get('/budgets?month=${now.month}&year=${now.year}')),
      _guard(api.get('/stats?period=$statsPeriod')),
    ]);

    // Terapkan per-response: satu request gagal tidak menghapus data lain.
    Object? firstError;
    void takeError(int i) {
      final err = results[i].$2;
      if (err != null) firstError ??= err;
    }

    takeError(0);
    if (results[0].$2 == null) {
      categories = ((results[0].$1 as Map)['categories'] as List)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    takeError(1);
    if (results[1].$2 == null) {
      summary = Summary.fromJson(results[1].$1 as Map<String, dynamic>);
    }
    takeError(2);
    if (results[2].$2 == null) recentTransactions = _parseTx(results[2].$1);
    takeError(3);
    if (results[3].$2 == null) transactions = _parseTx(results[3].$1);
    takeError(4);
    if (results[4].$2 == null) {
      budget = BudgetData.fromJson(results[4].$1 as Map<String, dynamic>);
    }
    takeError(5);
    if (results[5].$2 == null) {
      stats = StatsData.fromJson(results[5].$1 as Map<String, dynamic>);
    }

    errorMessage = firstError?.toString();
    loading = false;
    notifyListeners();
  }

  Future<void> refreshAll() => _loadCoreData();

  List<Trans> _parseTx(dynamic res) =>
      ((res as Map)['transactions'] as List)
          .map((e) => Trans.fromJson(e as Map<String, dynamic>))
          .toList();

  Future<void> addTransaction({
    required String type,
    required int amount,
    required int categoryId,
    required DateTime date,
    required String source,
    String? note,
  }) async {
    final res = await api.post('/transactions', {
      'type': type,
      'amount': amount,
      'categoryId': categoryId,
      'date':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'source': source,
      if (note != null && note.isNotEmpty) 'note': note,
    });

    // Optimistic update agar Home langsung menampilkan transaksi baru
    final txMap = (res as Map)['transaction'] as Map<String, dynamic>;
    final newTx = Trans.fromJson(txMap);
    recentTransactions = [
      newTx,
      ...recentTransactions.where((t) => t.id != newTx.id),
    ].take(5).toList();
    transactions = [
      newTx,
      ...transactions.where((t) => t.id != newTx.id),
    ];
    if (type == 'income') {
      summary = summary == null
          ? summary
          : Summary(
              balance: summary!.balance + amount,
              monthIncome: summary!.monthIncome + amount,
              monthExpense: summary!.monthExpense,
              budgetTarget: summary!.budgetTarget,
              budgetUsed: summary!.budgetUsed,
            );
    } else {
      summary = summary == null
          ? summary
          : Summary(
              balance: summary!.balance - amount,
              monthIncome: summary!.monthIncome,
              monthExpense: summary!.monthExpense + amount,
              budgetTarget: summary!.budgetTarget,
              budgetUsed: summary!.budgetUsed + amount,
            );
    }
    notifyListeners();

    // Refresh penuh dari server di background (tanpa memblokir UI)
    unawaited(refreshAll());
  }

  Future<void> updateTransaction({
    required String id,
    required String type,
    required int amount,
    required int categoryId,
    required DateTime date,
    required String source,
    String? note,
  }) async {
    await api.put('/transactions/$id', {
      'type': type,
      'amount': amount,
      'categoryId': categoryId,
      'date':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'source': source,
      'note': note,
    });
    await refreshAll();
  }

  Future<void> deleteTransaction(String id) async {
    await api.delete('/transactions/$id');
    await refreshAll();
  }

  Future<void> saveBudget({required int amount, int? categoryId}) async {
    final now = DateTime.now();
    await api.post('/budgets', {
      'amount': amount,
      'month': now.month,
      'year': now.year,
      'categoryId': categoryId,
    });

    // Optimistic update: UI langsung mencerminkan nilai tersimpan
    // tanpa menunggu refresh penuh (yang bisa gagal sebagian).
    final current = budget;
    if (categoryId == null) {
      budget = BudgetData(
        month: now.month,
        year: now.year,
        totalAmount: amount,
        totalUsed: current?.totalUsed ?? 0,
        categories: current?.categories ?? const [],
      );
      final s = summary;
      if (s != null) {
        summary = Summary(
          balance: s.balance,
          monthIncome: s.monthIncome,
          monthExpense: s.monthExpense,
          budgetTarget: amount,
          budgetUsed: s.budgetUsed,
        );
      }
    } else if (current != null) {
      budget = BudgetData(
        month: current.month,
        year: current.year,
        totalAmount: current.totalAmount,
        totalUsed: current.totalUsed,
        categories: [
          for (final c in current.categories)
            c.categoryId == categoryId ? c.withLimit(amount) : c,
        ],
      );
    }
    notifyListeners();

    // Sinkronkan dengan server di background (tanpa memblokir UI).
    unawaited(refreshAll());
  }

  Future<void> loadHistory(int month, int year) async {
    historyMonth = month;
    historyYear = year;
    notifyListeners();
    try {
      final res = await api.get('/transactions?month=$month&year=$year');
      transactions = _parseTx(res);
    } catch (e) {
      errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadStats(String period) async {
    statsPeriod = period;
    notifyListeners();
    try {
      final res = await api.get('/stats?period=$period');
      stats = StatsData.fromJson(res as Map<String, dynamic>);
    } catch (e) {
      errorMessage = e.toString();
    }
    notifyListeners();
  }

  void toggleBalance() {
    balanceVisible = !balanceVisible;
    notifyListeners();
  }

  void toggleBudgetReminder() {
    budgetReminder = !budgetReminder;
    notifyListeners();
  }

  Future<void> toggleRememberMe() async {
    rememberMe = !rememberMe;
    notifyListeners();
    try {
      await api.saveRememberMe(rememberMe);
    } catch (_) {}
  }

  void setHistoryFilter(String filter) {
    historyFilter = filter;
    notifyListeners();
  }
}
