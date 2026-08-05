import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/job.dart';
import '../data/repositories/job_repository.dart';
import 'language_provider.dart';
import 'test_mode_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchSortProvider = StateProvider<String>((ref) => 'relevance');

final searchResultProvider = FutureProvider<List<Job>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];

  final lang = ref.watch(languageProvider);
  final sortBy = ref.watch(searchSortProvider);
  final repo = ref.watch(_searchRepoProvider);
  final includeTesting = ref.watch(testModeProvider);
  return repo.searchJobs(query, langCode: lang, sortBy: sortBy, includeTesting: includeTesting);
});

final searchTotalCountProvider = FutureProvider<int>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return 0;
  final lang = ref.watch(languageProvider);
  final repo = ref.watch(_searchRepoProvider);
  final includeTesting = ref.watch(testModeProvider);
  return repo.searchJobsCount(query, langCode: lang, includeTesting: includeTesting);
});

final _searchRepoProvider = Provider<JobRepository>((ref) => JobRepository());

// ── 최근 검색어 ──

final recentSearchProvider =
    StateNotifierProvider<RecentSearchNotifier, List<String>>((ref) {
  return RecentSearchNotifier();
});

class RecentSearchNotifier extends StateNotifier<List<String>> {
  static const _prefsKey = 'recent_searches';
  static const _maxItems = 5;

  RecentSearchNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefsKey);
    if (json != null) {
      try {
        state = (jsonDecode(json) as List).map((e) => e.toString()).toList();
      } catch (_) {}
    }
  }

  Timer? _saveTimer;

  void _save() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(state));
    });
  }

  void add(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    final updated = [q, ...state.where((s) => s != q)];
    state = updated.take(_maxItems).toList();
    _save();
  }

  void remove(String query) {
    state = state.where((s) => s != query).toList();
    _save();
  }

  void clear() {
    state = [];
    _save();
  }
}
