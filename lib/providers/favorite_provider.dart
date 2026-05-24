import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteItem {
  final String jobId;
  final DateTime addedAt;

  const FavoriteItem({required this.jobId, required this.addedAt});

  Map<String, dynamic> toJson() => {
        'jobId': jobId,
        'addedAt': addedAt.toIso8601String(),
      };

  factory FavoriteItem.fromJson(Map<String, dynamic> json) => FavoriteItem(
        jobId: json['jobId'] as String,
        addedAt: DateTime.parse(json['addedAt'] as String),
      );
}

final favoriteProvider =
    StateNotifierProvider<FavoriteNotifier, List<FavoriteItem>>((ref) {
  return FavoriteNotifier();
});

/// 특정 jobId가 즐겨찾기인지 확인하는 편의 프로바이더
final isFavoriteProvider = Provider.family<bool, String>((ref, jobId) {
  final favorites = ref.watch(favoriteProvider);
  return favorites.any((f) => f.jobId == jobId);
});

class FavoriteNotifier extends StateNotifier<List<FavoriteItem>> {
  static const _prefsKey = 'favorites';

  FavoriteNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefsKey);
    if (json != null) {
      try {
        final list = jsonDecode(json) as List;
        state = list.map((e) => FavoriteItem.fromJson(e)).toList();
      } catch (_) {}
    }
  }

  Timer? _saveTimer;

  void _save() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _prefsKey, jsonEncode(state.map((e) => e.toJson()).toList()));
    });
  }

  void toggle(String jobId) {
    final exists = state.any((f) => f.jobId == jobId);
    if (exists) {
      state = state.where((f) => f.jobId != jobId).toList();
    } else {
      state = [
        ...state,
        FavoriteItem(jobId: jobId, addedAt: DateTime.now()),
      ];
    }
    _save();
  }

  void remove(String jobId) {
    state = state.where((f) => f.jobId != jobId).toList();
    _save();
  }

  void removeMultiple(Set<String> jobIds) {
    state = state.where((f) => !jobIds.contains(f.jobId)).toList();
    _save();
  }

  bool isFavorite(String jobId) => state.any((f) => f.jobId == jobId);
}
