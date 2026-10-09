import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 공고 메모 — 로컬 저장(2026-10-09, 운영 2.1.6).
/// 공고당 1개. 목록 화면 표시용으로 제목·회사 스냅샷도 함께 저장.
/// 2.2.0 서버화(job_notes) 때 이 로컬 데이터를 병합 업로드할 예정
/// (즐겨찾기 서버화와 동일 패턴).
class JobMemoEntry {
  final String text;
  final String title; // 공고 제목 스냅샷 (목록 표시용)
  final String company;
  final int updatedMs;

  const JobMemoEntry({
    required this.text,
    this.title = '',
    this.company = '',
    required this.updatedMs,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'title': title,
        'company': company,
        'updated_ms': updatedMs,
      };

  factory JobMemoEntry.fromJson(Map<String, dynamic> j) => JobMemoEntry(
        text: j['text'] as String? ?? '',
        title: j['title'] as String? ?? '',
        company: j['company'] as String? ?? '',
        updatedMs: j['updated_ms'] as int? ?? 0,
      );
}

class JobMemoNotifier extends StateNotifier<Map<String, JobMemoEntry>> {
  static const _prefsKey = 'job_memos';

  JobMemoNotifier() : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      state = {
        for (final e in map.entries)
          e.key: JobMemoEntry.fromJson(Map<String, dynamic>.from(e.value)),
      };
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({for (final e in state.entries) e.key: e.value.toJson()}),
    );
  }

  /// 저장 — 빈 텍스트는 삭제와 동일(메모 시트의 '' 반환 규약).
  Future<void> set(String jobId, String text,
      {String title = '', String company = ''}) async {
    final t = text.trim();
    if (t.isEmpty) {
      await remove(jobId);
      return;
    }
    state = {
      ...state,
      jobId: JobMemoEntry(
        text: t,
        title: title,
        company: company,
        updatedMs: DateTime.now().millisecondsSinceEpoch,
      ),
    };
    await _save();
  }

  Future<void> remove(String jobId) async {
    if (!state.containsKey(jobId)) return;
    final next = Map<String, JobMemoEntry>.from(state)..remove(jobId);
    state = next;
    await _save();
  }
}

final jobMemoProvider =
    StateNotifierProvider<JobMemoNotifier, Map<String, JobMemoEntry>>(
        (ref) => JobMemoNotifier());

/// 특정 공고의 메모 텍스트 (없으면 null).
final jobMemoTextProvider = Provider.family<String?, String>(
    (ref, jobId) => ref.watch(jobMemoProvider)[jobId]?.text);
