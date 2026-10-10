import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/colors.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/info_row.dart';
import '../../data/models/resume.dart';
import '../../data/services/khire_resume_codes.dart';
import '../../providers/account_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/resume_provider.dart';
import 'khire_code_labels.dart';
import 'resume_edit_screen.dart';

/// 내 이력서 관리 (마이페이지 → 내 이력서 관리).
///
/// 이력서는 "한 장" — 한 번 작성하면 지원 시 사이트 양식에 맞춰 자동 입력
/// (사이트별 목록 제거, 2026-10-09 사용자 확정). 상태별 화면:
///  - 미작성  : 안내 + 빈 상태 + [이력서 작성하기]
///  - 작성중  : 요약(빈 항목 '미입력') + 미완성 배너 + [이어서 작성하기]
///  - 작성완료: 요약 + 우상단 '수정하기'(회원정보 요약과 동일 패턴)
class ResumeManageScreen extends ConsumerWidget {
  const ResumeManageScreen({super.key});

  static const _site = 'khire';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final s = AppStrings.of(lang);
    final resumeAsync = ref.watch(resumeProvider(_site));
    final profile = ref.watch(accountProvider).profile;
    final resume = resumeAsync.valueOrNull;
    final hasAddress = (profile?.addrRoad ?? '').isNotEmpty;
    final complete = resume != null && resume.isComplete && hasAddress;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 48,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: AppBackButton(),
        ),
        title: Text(
          s.myPageResume,
          style: const TextStyle(
            color: AppColors.black,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          // 작성본이 있을 때만 — 회원정보 요약과 동일한 텍스트 버튼(통일).
          if (resume != null)
            TextButton(
              onPressed: () => ResumeEditScreen.show(context, site: _site),
              style: TextButton.styleFrom(foregroundColor: AppColors.carrot),
              child: Text(
                s.smsEditOnKhire,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: resumeAsync.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.carrot))
            : FutureBuilder<void>(
                // 요약의 코드→이름 변환에 코드표 필요.
                future: KhireResumeCodes.instance.ensureLoaded(),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.carrot));
                  }
                  return resume == null
                      ? _EmptyBody(s: s)
                      : _SummaryBody(
                          s: s,
                          lang: lang,
                          resume: resume,
                          complete: complete,
                          addressText: _addressText(profile),
                        );
                },
              ),
      ),
    );
  }

  static String _addressText(dynamic profile) {
    final road = (profile?.addrRoad ?? '') as String;
    final detail = (profile?.addrDetail ?? '') as String;
    return [road, detail].where((e) => e.isNotEmpty).join(' ');
  }
}

/// 공통 상단 안내 박스 — "한 번만 작성하면 자동 입력".
class _IntroBox extends StatelessWidget {
  final String text;
  const _IntroBox(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.carrotLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13.5,
          height: 1.5,
          fontWeight: FontWeight.w600,
          color: AppColors.carrotDark,
        ),
      ),
    );
  }
}

/// 미작성 — 빈 상태 + 작성하기 버튼.
class _EmptyBody extends StatelessWidget {
  final AppStrings s;
  const _EmptyBody({required this.s});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            children: [
              _IntroBox(s.resumeManageIntro),
              const SizedBox(height: 80),
              const Icon(Icons.description_outlined,
                  size: 52, color: AppColors.gray200),
              const SizedBox(height: 14),
              Text(
                s.resumeEmptyTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.resumeEmptyDesc,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 13.5, color: AppColors.gray300),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: AppPrimaryButton(
            // 공용 CTA 모듈(2026-10-10).
            label: s.resumeCreateButton,
            onTap: () => ResumeEditScreen.show(context, site: 'khire'),
          ),
        ),
      ],
    );
  }
}

/// 작성중/작성완료 — 요약본(InfoRow). 작성중이면 미완성 배너 + 이어서 작성.
class _SummaryBody extends StatelessWidget {
  final AppStrings s;
  final String lang;
  final Resume resume;
  final bool complete;
  final String addressText;
  const _SummaryBody({
    required this.s,
    required this.lang,
    required this.resume,
    required this.complete,
    required this.addressText,
  });

  @override
  Widget build(BuildContext context) {
    final codes = KhireResumeCodes.instance;
    // 표시만 사용자 언어 번역(주입은 한국어 원본 — khire_code_labels).
    String nameOf(List<CodeItem> items, String? cd) {
      if (cd == null) return '';
      for (final c in items) {
        if (c.cd == cd) return khireItemLabel(c, lang);
      }
      return '';
    }

    final edu = nameOf(codes.education, resume.lastEduCd);
    final eduState = resume.lastEduCd == null
        ? ''
        : nameOf(codes.eduStateFor(resume.lastEduCd!), resume.eduStateCd);
    final workParts = [
      nameOf(codes.workPeriod(), resume.workPeriodCd),
      nameOf(codes.workWeek(), resume.workWeekCd),
      ...resume.employmentCds.map((cd) => nameOf(codes.workEmployment(), cd)),
    ].where((e) => e.isNotEmpty).toList();

    // 경력: 신입/경력(회사명 나열).
    final careerText = switch (resume.careerType) {
      'new' => s.resumeCareerNew,
      'exp' => resume.careers.isEmpty
          ? ''
          : resume.careers.map((c) => c.company).join(', '),
      _ => '',
    };

    // (라벨, 값, 필수) — 필수인데 비면 '미입력'(주황)으로 표시.
    final rows = <(String, String, bool)>[
      (s.resumeTitleLabel, resume.title.trim(), true),
      (s.resumeSelfLabel, resume.selfIntro.trim(), true),
      (
        s.resumeEducationLabel,
        [edu, eduState].where((e) => e.isNotEmpty).join(' · '),
        true
      ),
      (s.resumeCareerLabel, careerText, true),
      (
        s.resumeAreaLabel,
        resume.areas.map((a) => '${a.areaNm} ${a.localNm}').join(', '),
        true
      ),
      (
        s.resumeJobKindLabel,
        resume.jobKinds.map((j) => '${j.jk1Nm} > ${j.jk2Nm}').join(', '),
        true
      ),
      (s.resumeWorkConditionLabel, workParts.join(' · '), true),
      (s.resumeKoreanLabel, nameOf(codes.koreanLevel, resume.koreanLevelCd),
          true),
      (s.addressTitle, addressText, true),
      (
        s.resumeLicenseLabel,
        resume.licenses.map((l) => l.name).join(', '),
        false
      ),
    ];

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            children: [
              _IntroBox(s.resumeManageIntro),
              if (!complete) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 17, color: AppColors.carrot),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.resumeIncompleteBanner,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              for (var i = 0; i < rows.length; i++)
                InfoRow(
                  label: rows[i].$1,
                  value: rows[i].$2.isEmpty && rows[i].$3
                      ? s.resumeNotEntered
                      : rows[i].$2,
                  isOrange: rows[i].$2.isEmpty && rows[i].$3,
                  isLast: i == rows.length - 1,
                ),
            ],
          ),
        ),
        if (!complete)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: AppPrimaryButton(
              // 공용 CTA 모듈(2026-10-10).
              label: s.resumeContinueButton,
              onTap: () => ResumeEditScreen.show(context, site: 'khire'),
            ),
          ),
      ],
    );
  }
}
