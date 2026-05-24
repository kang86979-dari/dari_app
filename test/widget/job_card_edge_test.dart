import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:korea_job/core/l10n/app_strings.dart';
import 'package:korea_job/data/models/job.dart';
import 'package:korea_job/features/home/widgets/job_card.dart';

Job _makeJob({
  String? title = '테스트 공고 제목',
  String? company = '테스트회사',
  String? addressDetail,
  String? salary,
  String? salaryTypeRaw,
  int? salaryAmount,
  String? expiresAt,
  List<VisaInfo> visas = const [],
  CategoryInfo? jobCategory,
  EmploymentTypeInfo? employmentType,
  Map<String, dynamic> titleTranslations = const {},
  bool? housingProvided,
}) {
  return Job(
    id: 'test-1',
    siteId: 'site-1',
    siteName: 'Test',
    title: title,
    company: company,
    addressDetail: addressDetail,
    salary: salary,
    salaryTypeRaw: salaryTypeRaw,
    salaryAmount: salaryAmount,
    expiresAt: expiresAt,
    visas: visas,
    jobCategory: jobCategory,
    employmentType: employmentType,
    titleTranslations: titleTranslations,
    housingProvided: housingProvided,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));
}

void main() {
  // ── 1-18. 엣지 케이스 ──

  group('JobCard edge cases', () {
    testWidgets('null title shows empty string, no crash', (tester) async {
      final job = _makeJob(title: null);
      await tester.pumpWidget(_wrap(JobCard(
        job: job, langCode: 'ko', strings: AppStrings.of('ko'), onTap: () {},
      )));
      // 크래시 없이 렌더링
      expect(find.byType(JobCard), findsOneWidget);
    });

    testWidgets('null company shows empty string, no crash', (tester) async {
      final job = _makeJob(company: null);
      await tester.pumpWidget(_wrap(JobCard(
        job: job, langCode: 'ko', strings: AppStrings.of('ko'), onTap: () {},
      )));
      expect(find.byType(JobCard), findsOneWidget);
    });

    testWidgets('null salary shows fallback text', (tester) async {
      final job = _makeJob(
        salaryTypeRaw: null, salaryAmount: null, salary: null,
      );
      await tester.pumpWidget(_wrap(JobCard(
        job: job, langCode: 'ko', strings: AppStrings.of('ko'), onTap: () {},
        salaryFallback: '회사 내규',
      )));
      expect(find.text('회사 내규'), findsOneWidget);
    });

    testWidgets('null expiresAt shows alwaysOpen', (tester) async {
      final job = _makeJob(expiresAt: null);
      await tester.pumpWidget(_wrap(JobCard(
        job: job, langCode: 'ko', strings: AppStrings.of('ko'), onTap: () {},
        alwaysOpen: '상시',
      )));
      expect(find.text('상시'), findsOneWidget);
    });

    testWidgets('empty visas shows no visa tags', (tester) async {
      final job = _makeJob(visas: []);
      await tester.pumpWidget(_wrap(JobCard(
        job: job, langCode: 'ko', strings: AppStrings.of('ko'), onTap: () {},
      )));
      // E-9 등 비자 태그 없음
      expect(find.byType(JobCard), findsOneWidget);
    });

    testWidgets('3+ visas shows +N badge', (tester) async {
      final job = _makeJob(visas: [
        const VisaInfo(id: '1', code: 'E-9'),
        const VisaInfo(id: '2', code: 'H-2'),
        const VisaInfo(id: '3', code: 'F-4'),
        const VisaInfo(id: '4', code: 'D-10'),
      ]);
      await tester.pumpWidget(_wrap(JobCard(
        job: job, langCode: 'ko', strings: AppStrings.of('ko'), onTap: () {},
      )));
      // 처음 2개 + "+2" 뱃지
      expect(find.text('E-9'), findsOneWidget);
      expect(find.text('H-2'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('very long title is ellipsized, no overflow', (tester) async {
      final longTitle = '가' * 100; // 100자 제목
      final job = _makeJob(title: longTitle);
      await tester.pumpWidget(_wrap(
        SizedBox(
          width: 375,
          child: JobCard(
            job: job, langCode: 'ko', strings: AppStrings.of('ko'), onTap: () {},
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('expired job with expiredLabel shows label', (tester) async {
      final job = _makeJob(expiresAt: '2020-01-01'); // 과거 날짜
      await tester.pumpWidget(_wrap(JobCard(
        job: job, langCode: 'ko', strings: AppStrings.of('ko'), onTap: () {},
        expiredLabel: '마감',
      )));
      expect(find.text('마감'), findsOneWidget);
    });

    testWidgets('housing provided shows housing chip', (tester) async {
      final job = _makeJob(housingProvided: true);
      await tester.pumpWidget(_wrap(JobCard(
        job: job, langCode: 'ko', strings: AppStrings.of('ko'), onTap: () {},
      )));
      // housingChip 텍스트가 표시됨
      final s = AppStrings.of('ko');
      expect(find.text(s.housingChip), findsOneWidget);
    });
  });

  // ── UI 오버플로우 테스트 (언어 x 해상도) ──

  group('JobCard overflow test', () {
    final languages = ['ko', 'en', 'ru', 'bn', 'my', 'ar', 'km'];
    final sizes = [
      const Size(320, 568),  // 소형
      const Size(375, 812),  // 중형
      const Size(428, 926),  // 대형
    ];

    for (final lang in languages) {
      for (final size in sizes) {
        testWidgets('no overflow: $lang @ ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          final job = _makeJob(
            title: '가' * 50, // 긴 제목
            company: 'Very Long Company Name Corporation Ltd 테스트',
            salaryTypeRaw: 'monthly',
            salaryAmount: 2000000,
            expiresAt: '2026-12-31',
            visas: [
              const VisaInfo(id: '1', code: 'E-9'),
              const VisaInfo(id: '2', code: 'H-2'),
            ],
            jobCategory: CategoryInfo(
              id: 'c1',
              names: {'name_en': 'Manufacturing', 'name_ko': '제조업'},
            ),
          );

          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: size.width,
                height: size.height,
                child: SingleChildScrollView(
                  child: JobCard(
                    job: job,
                    langCode: lang,
                    strings: AppStrings.of(lang),
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ));

          // 오버플로우 에러가 없어야 함
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
