import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../data/models/resume.dart';
import '../../../data/services/khire_resume_codes.dart';

/// 이력서 입력용 피커 모음 (바텀시트/다이얼로그). 앱 공통 스타일 준수.
class ResumePickers {
  ResumePickers._();

  /// 코드 단일 선택 (학력·졸업상태·한국어·근무기간/요일).
  static Future<String?> pickCode(
    BuildContext context, {
    required String title,
    required List<CodeItem> items,
    String? selected,
    String Function(CodeItem)? labelOf, // 사용자 언어 표시(주입은 nm 원본)
    String Function(CodeItem)? subtitleOf, // 부가 설명 (한국어 수준 등)
  }) {
    return _showSheet<String>(
      context,
      title: title,
      child: (close) => ListView(
        shrinkWrap: true,
        children: items.map((c) {
          final on = c.cd == selected;
          final sub = subtitleOf?.call(c) ?? '';
          return _row(
            text: labelOf?.call(c) ?? c.nm,
            subtitle: sub.isEmpty ? null : sub,
            selected: on,
            onTap: () => close(c.cd),
          );
        }).toList(),
      ),
    );
  }

  /// 희망 근무지: 시도 → 시군구 2단계.
  static Future<ResumeArea?> pickArea(
    BuildContext context,
    String lang,
    KhireResumeCodes codes,
  ) async {
    final s = AppStrings.of(lang);
    final sido = await _showSheet<AreaItem>(
      context,
      title: s.resumeAreaLabel,
      child: (close) => ListView(
        shrinkWrap: true,
        children: codes.sido
            .map((a) => _row(text: a.areaNm, onTap: () => close(a)))
            .toList(),
      ),
    );
    if (sido == null || !context.mounted) return null;
    final locals = codes.localsOf(sido.areaCd);
    final local = await _showSheet<AreaItem>(
      context,
      title: sido.areaNm,
      child: (close) => ListView(
        shrinkWrap: true,
        children: locals
            .map((a) => _row(text: a.localNm, onTap: () => close(a)))
            .toList(),
      ),
    );
    if (local == null) return null;
    return ResumeArea(
        sido.areaCd, sido.areaNm, local.localCd, local.localNm);
  }

  /// 희망 업직종: 대분류 → 중분류 2단계.
  static Future<ResumeJobKind?> pickJobKind(
    BuildContext context,
    String lang,
    KhireResumeCodes codes,
  ) async {
    final s = AppStrings.of(lang);
    final jk1 = await _showSheet<CodeItem>(
      context,
      title: s.resumeJobKindLabel,
      child: (close) => ListView(
        shrinkWrap: true,
        children: codes.jobkind1
            .map((c) => _row(text: c.nm, onTap: () => close(c)))
            .toList(),
      ),
    );
    if (jk1 == null || !context.mounted) return null;
    final jk2s = codes.jobkind2Of(jk1.cd);
    final jk2 = await _showSheet<CodeItem>(
      context,
      title: jk1.nm,
      child: (close) => ListView(
        shrinkWrap: true,
        children: jk2s
            .map((c) => _row(text: c.nm, onTap: () => close(c)))
            .toList(),
      ),
    );
    if (jk2 == null) return null;
    return ResumeJobKind(jk1.cd, jk1.nm, jk2.cd, jk2.nm, false);
  }

  /// 자격증 직접 입력 (K-HIRE licensecd 99999 = 직접입력).
  static Future<ResumeLicense?> inputLicense(
      BuildContext context, String lang) {
    final s = AppStrings.of(lang);
    final nameCtrl = TextEditingController();
    final organCtrl = TextEditingController();
    final yearCtrl = TextEditingController();
    return showDialog<ResumeLicense>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.resumeLicenseLabel,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(nameCtrl, s.resumeLicenseName),
            const SizedBox(height: 10),
            _dialogField(organCtrl, s.resumeLicenseOrgan),
            const SizedBox(height: 10),
            _dialogField(yearCtrl, s.resumeLicenseYear,
                keyboard: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.cancel,
                style: const TextStyle(color: AppColors.gray400)),
          ),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.of(ctx).pop(ResumeLicense(
                name: name,
                organ: organCtrl.text.trim(),
                year: yearCtrl.text.trim(),
              ));
            },
            child: Text(s.resumeAdd,
                style: const TextStyle(
                    color: AppColors.carrot, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── 내부 공통 ──
  static Future<T?> _showSheet<T>(
    BuildContext context, {
    required String title,
    required Widget Function(void Function(T) close) child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        void close(T v) => Navigator.of(ctx).pop(v);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: child(close),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _row({
    required String text,
    String? subtitle,
    bool selected = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      color: selected ? AppColors.carrot : AppColors.gray900,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.gray300),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check, size: 20, color: AppColors.carrot),
          ],
        ),
      ),
    );
  }

  static Widget _dialogField(TextEditingController ctrl, String hint,
      {TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.gray300, fontSize: 14),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.gray100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.carrot),
        ),
      ),
    );
  }
}
