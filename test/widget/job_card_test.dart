import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:korea_job/core/l10n/app_strings.dart';
import 'package:korea_job/data/models/job.dart';
import 'package:korea_job/features/home/widgets/job_card.dart';

/// 테스트용 Job 생성 헬퍼
Job _makeJob({
  String title = '개발자 모집',
  String? company = 'ABC회사',
  String? addressDetail = '서울시 강남구 역삼동',
  String? salary,
  String? salaryTypeRaw = 'monthly',
  int? salaryAmount = 2000000,
  String? expiresAt = '2026-04-19',
  List<VisaInfo> visas = const [],
  CategoryInfo? jobCategory,
  EmploymentTypeInfo? employmentType,
  Map<String, dynamic> titleTranslations = const {},
  Map<String, dynamic> addressTranslations = const {},
  bool? housingProvided,
}) {
  return Job(
    id: 'test-job-1',
    siteId: 'site-1',
    siteName: 'TestSite',
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
    addressTranslations: addressTranslations,
    housingProvided: housingProvided,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));
}

void main() {
  // ── 1-13. JobCard 필드 바인딩 ──

  group('JobCard field binding', () {
    testWidgets('1. title is displayed', (tester) async {
      final job = _makeJob(title: '개발자 모집');
      await tester.pumpWidget(_wrap(JobCard(
        job: job,
        langCode: 'ko',
        strings: AppStrings.of('ko'),
        onTap: () {},
      )));
      expect(find.text('개발자 모집'), findsOneWidget);
    });

    testWidgets('2. company is displayed', (tester) async {
      final job = _makeJob(company: 'ABC회사');
      await tester.pumpWidget(_wrap(JobCard(
        job: job,
        langCode: 'ko',
        strings: AppStrings.of('ko'),
        onTap: () {},
      )));
      expect(find.text('ABC회사'), findsOneWidget);
    });

    testWidgets('3. job category tag is displayed', (tester) async {
      final job = _makeJob(
        jobCategory: CategoryInfo(
          id: 'cat-1',
          names: {'name_en': 'Manufacturing', 'name_ko': '제조업'},
        ),
      );
      await tester.pumpWidget(_wrap(JobCard(
        job: job,
        langCode: 'ko',
        strings: AppStrings.of('ko'),
        onTap: () {},
      )));
      // 직종 태그가 표시됨
      expect(find.text(job.getJobType('ko')), findsOneWidget);
    });

    testWidgets('4. salary text appears exactly once (not in tag row)', (tester) async {
      final job = _makeJob(
        salaryTypeRaw: 'monthly',
        salaryAmount: 2000000,
        visas: [const VisaInfo(id: 'v1', code: 'E-9')],
      );
      await tester.pumpWidget(_wrap(JobCard(
        job: job,
        langCode: 'ko',
        strings: AppStrings.of('ko'),
        onTap: () {},
      )));
      final salaryText = '월급 200만원';
      // 급여는 정확히 1번만 표시 (하단에만)
      expect(find.text(salaryText), findsOneWidget);
      // 비자 태그 텍스트와 급여 텍스트는 다른 값
      expect(find.text('E-9'), findsOneWidget);
      // 급여가 태그('E-9')와 같은 위젯에 있지 않음을 확인
      final salaryWidget = tester.widget<Text>(find.text(salaryText));
      final visaWidget = tester.widget<Text>(find.text('E-9'));
      expect(salaryWidget != visaWidget, isTrue);
    });

    testWidgets('5. salary displayed at bottom', (tester) async {
      final job = _makeJob(salaryTypeRaw: 'monthly', salaryAmount: 2000000);
      await tester.pumpWidget(_wrap(JobCard(
        job: job,
        langCode: 'ko',
        strings: AppStrings.of('ko'),
        onTap: () {},
      )));
      expect(find.text('월급 200만원'), findsOneWidget);
    });

    testWidgets('6. visa tags displayed', (tester) async {
      final job = _makeJob(visas: [
        const VisaInfo(id: 'v1', code: 'E-9'),
        const VisaInfo(id: 'v2', code: 'H-2'),
      ]);
      await tester.pumpWidget(_wrap(JobCard(
        job: job,
        langCode: 'ko',
        strings: AppStrings.of('ko'),
        onTap: () {},
      )));
      expect(find.text('E-9'), findsOneWidget);
      expect(find.text('H-2'), findsOneWidget);
    });

    testWidgets('7. deadline format ~M/D', (tester) async {
      final job = _makeJob(expiresAt: '2026-04-19');
      await tester.pumpWidget(_wrap(JobCard(
        job: job,
        langCode: 'ko',
        strings: AppStrings.of('ko'),
        onTap: () {},
      )));
      expect(find.text('~4/19'), findsOneWidget);
    });

    testWidgets('8. no category tag when jobCategory is null', (tester) async {
      final job = _makeJob(jobCategory: null);
      await tester.pumpWidget(_wrap(JobCard(
        job: job,
        langCode: 'ko',
        strings: AppStrings.of('ko'),
        onTap: () {},
      )));
      // 직종 태그가 없어야 함 (빈 문자열이면 표시 안 됨)
      expect(job.getJobType('ko'), isEmpty);
    });

    testWidgets('9. companyRule shows company policy text', (tester) async {
      final job = _makeJob(
        salaryTypeRaw: 'company_rule',
        salaryAmount: null,
      );
      await tester.pumpWidget(_wrap(JobCard(
        job: job,
        langCode: 'ko',
        strings: AppStrings.of('ko'),
        onTap: () {},
      )));
      expect(find.text('회사 내규'), findsOneWidget);
    });

    testWidgets('10. favorite heart toggle calls callback', (tester) async {
      bool tapped = false;
      final job = _makeJob();
      await tester.pumpWidget(_wrap(JobCard(
        job: job,
        langCode: 'ko',
        strings: AppStrings.of('ko'),
        onTap: () {},
        onFavoriteToggle: () => tapped = true,
      )));
      // 하트 아이콘 탭
      await tester.tap(find.byIcon(Icons.favorite_border));
      expect(tapped, isTrue);
    });
  });

  // ── 1-17. 언어 변경 시 JobCard 렌더링 ──

  group('JobCard language switch', () {
    testWidgets('ko shows Korean title', (tester) async {
      final job = _makeJob(
        title: '한국어 제목',
        titleTranslations: {'en': 'English Title', 'vi': 'Tiếng Việt'},
      );
      await tester.pumpWidget(_wrap(JobCard(
        job: job,
        langCode: 'ko',
        strings: AppStrings.of('ko'),
        onTap: () {},
      )));
      expect(find.text('한국어 제목'), findsOneWidget);
    });

    testWidgets('en shows English title', (tester) async {
      final job = _makeJob(
        title: '한국어 제목',
        titleTranslations: {'en': 'English Title', 'vi': 'Tiếng Việt'},
      );
      await tester.pumpWidget(_wrap(JobCard(
        job: job,
        langCode: 'en',
        strings: AppStrings.of('en'),
        onTap: () {},
      )));
      expect(find.text('English Title'), findsOneWidget);
    });

    testWidgets('vi shows Vietnamese title', (tester) async {
      final job = _makeJob(
        title: '한국어 제목',
        titleTranslations: {'en': 'English Title', 'vi': 'Tiếng Việt'},
      );
      await tester.pumpWidget(_wrap(JobCard(
        job: job,
        langCode: 'vi',
        strings: AppStrings.of('vi'),
        onTap: () {},
      )));
      expect(find.text('Tiếng Việt'), findsOneWidget);
    });

    testWidgets('salary changes with language: ko → de', (tester) async {
      final job = _makeJob(salaryTypeRaw: 'monthly', salaryAmount: 2000000);

      // ko
      await tester.pumpWidget(_wrap(JobCard(
        job: job,
        langCode: 'ko',
        strings: AppStrings.of('ko'),
        onTap: () {},
      )));
      expect(find.text('월급 200만원'), findsOneWidget);

      // de
      await tester.pumpWidget(_wrap(JobCard(
        job: job,
        langCode: 'de',
        strings: AppStrings.of('de'),
        onTap: () {},
      )));
      // de는 salaryMonthly에 de키 없음 → en fallback 'Monthly'
      expect(find.text('₩2.000.000 / Monthly'), findsOneWidget);
    });
  });
}
