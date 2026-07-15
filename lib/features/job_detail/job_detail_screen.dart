import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/utils/ad_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/colors.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../data/models/job.dart';
import '../../providers/job_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../data/repositories/job_repository.dart';
import '../../data/services/analytics_service.dart';
import '../../core/widgets/error_retry.dart';

class JobDetailScreen extends ConsumerWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final langCode = ref.watch(languageProvider);
    final jobAsync = ref.watch(jobDetailProvider(jobId));

    return Scaffold(
      body: SafeArea(
        child: jobAsync.when(
          data: (job) {
            if (job == null) return _buildNotFound(context, s);
            final isFav = ref.watch(isFavoriteProvider(job.id));
            return _DetailBody(
              job: job, s: s, langCode: langCode,
              isFavorite: isFav,
              onFavoriteToggle: () {
                if (isFav) {
                  analytics.favoriteRemoved(job.id);
                } else {
                  analytics.favoriteAdded(job.id, 'detail');
                }
                ref.read(favoriteProvider.notifier).toggle(job.id);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isFav ? s.favoriteRemovedMsg : s.favoriteAddedMsg),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ));
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorRetry(
            onRetry: () => ref.invalidate(jobDetailProvider(jobId)),
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context, AppStrings s) {
    return Column(
      children: [
        _TopBar(onBack: () => context.pop(), title: s.jobDetail),
        Expanded(child: Center(child: Text(s.jobNotFound))),
      ],
    );
  }
}

class _DetailBody extends StatefulWidget {
  final Job job;
  final AppStrings s;
  final String langCode;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  const _DetailBody({
    required this.job, required this.s, required this.langCode,
    required this.isFavorite, required this.onFavoriteToggle,
  });

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> {
  InterstitialAd? _interstitialAd;
  String? _pendingUrl;
  bool _showKoreanAddress = false;

  // 지원하기 광고: 공고별 클릭 횟수 추적
  // 다른 공고 → 무조건 광고, 같은 공고 → 최초 1번 + 이후 3번마다
  static final Map<String, int> _applyCountPerJob = {};
  static void clearApplyCount() => _applyCountPerJob.clear();
  int _adApplyInterval = 3; // 기본값
  bool _configLoaded = false;

  // 번역 상태
  bool _isTranslating = false;
  String? _translatedHtml;


  @override
  void initState() {
    super.initState();
    analytics.jobDetailView(widget.job.id, 'detail');
    _loadInterstitialAd();
    _loadAdConfig();
    _autoTranslate();

  }

  @override
  void didUpdateWidget(covariant _DetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.langCode != widget.langCode) {
      _translatedHtml = null;
      _showKoreanAddress = false;
      _autoTranslate();
    }
  }

  /// 상세 화면 진입 시 번역이 없으면 자동으로 Edge Function 호출
  Future<void> _autoTranslate() async {
    final langCode = widget.langCode;
    if (langCode == 'ko') return;
    // DB에 번역이 있으면 불필요 (getDescriptionHtml이 이미 처리)
    final t = widget.job.descriptionTranslations[langCode]?.toString();
    if (t != null && t.isNotEmpty) return;

    setState(() => _isTranslating = true);

    try {
      final result = await JobRepository().translateDescription(widget.job.id, langCode);
      if (!mounted || langCode != widget.langCode) return;
      if (result.isNotEmpty && result != widget.job.description) {
        setState(() {
          _translatedHtml = result
              .replaceAll('\\r\\n', '\n')
              .replaceAll('\\n', '\n')
              .replaceAll('\\r', '\n')
              // 알바천국 워터마크 제거 (첫 줄에서만)
              .replaceFirst(RegExp(r'^\s*(DESIGNED BY 알바천국|DESIGNED BY[^\n]*|ĐƯỢC THIẾT KẾ BỞI[^\n]*|THIẾT KẾ B[YỞ][^\n]*|ออกแบบโดย[^\n]*|由[^\n]*设计[^\n]*|ДИЗАЙН BY[^\n]*)\s*\n?', caseSensitive: false), '')
              .replaceFirst(RegExp(r'^\s*(Alba\s*Heaven|アルバ天国|알바천국|अल्बा हेवन|আলবা হেভেন|அல்பா ஹெவன்|අල්බා හෙවන්|अल्बा स्वर्ग)[^\n]*\n?'), '')
              .replaceFirst(RegExp(r'^\s*(විසින් නිර්මාණය කරන ලද[ීැ]?|द्वारा डिज़?ाइन[^\n]*|द्वारा डिजाइन[^\n]*|দ্বারা ডিজাইন[^\n]*)\s*\n?'), '')
              // 번역 마커 → 실제 문자 변환
              .replaceAll(RegExp(r'‖[^‖]*‖'), '\n')
              .replaceAll(RegExp(r'‖(?:NL)+\s*'), '\n')
              .replaceAll(RegExp(r'‖[A-Z]?\s*'), '')
              .replaceAll(RegExp('["\u201C\u201D]NL["\u201C\u201D]'), '\n')
              .replaceAll(RegExp('["\u201C\u201D]TILDE["\u201C\u201D]'), '~')
              .replaceAll(RegExp(r'(?<![A-Za-z])NL(?![A-Za-z])'), '\n')
              .replaceAll(RegExp(r'(?<![A-Za-z])TILDE(?![A-Za-z])'), '~')
              .replaceAll(RegExp(r'\n{3,}'), '\n\n');
          _isTranslating = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _isTranslating = false);
  }


  Future<void> _loadAdConfig() async {
    if (_configLoaded) return;
    try {
      final data = await Supabase.instance.client
          .from('app_config')
          .select('value')
          .eq('key', 'ad_apply_interval')
          .maybeSingle();
      if (data != null) {
        _adApplyInterval = int.tryParse(data['value'] as String) ?? 3;
      }
      _configLoaded = true;
    } catch (_) {}
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) { ad.dispose(); return; }
          _interstitialAd = ad;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              if (!mounted) return;
              _loadInterstitialAd();
              _navigateToUrl();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              if (!mounted) return;
              _loadInterstitialAd();
              _navigateToUrl();
            },
          );
        },
        onAdFailedToLoad: (_) {
          _interstitialAd = null;
        },
      ),
    );
  }

  void _onApplyTap(String? url) {
    analytics.applyTap(widget.job.id, widget.job.siteName);
    _pendingUrl = _validateJobUrl(url, widget.job.siteUrl);
    final jobId = widget.job.id;
    final count = (_applyCountPerJob[jobId] ?? 0) + 1;
    _applyCountPerJob[jobId] = count;
    // 다른 공고(count==1): 무조건 광고 / 같은 공고: 최초 1번 + 이후 3번마다
    final showAd = count == 1 || (_adApplyInterval > 0 && count % _adApplyInterval == 1);
    if (showAd && _interstitialAd != null) {
      analytics.applyAdShown(widget.job.id);
      _interstitialAd!.show();
    } else {
      _navigateToUrl();
    }
  }

  /// job.url 도메인이 sites.url 도메인과 다르면 사이트 홈페이지로 폴백
  String? _validateJobUrl(String? jobUrl, String? siteUrl) {
    if (jobUrl == null || jobUrl.isEmpty) return siteUrl;
    if (siteUrl == null || siteUrl.isEmpty) return jobUrl;

    final jobHost = Uri.tryParse(jobUrl)?.host ?? '';
    final siteHost = Uri.tryParse(siteUrl)?.host ?? '';

    if (jobHost.isEmpty || siteHost.isEmpty) return siteUrl;

    // 서브도메인 포함 비교 (예: m.alba.co.kr vs alba.co.kr)
    if (jobHost.endsWith(siteHost) || siteHost.endsWith(jobHost)) {
      return jobUrl;
    }
    return siteUrl;
  }

  void _onSourceTap(String url) {
    _pendingUrl = url;
    // TODO: 프로덕션에서 전면 광고 복원
    // if (_interstitialAd != null) {
    //   _interstitialAd!.show();
    // } else {
    //   _navigateToUrl();
    // }
    _navigateToUrl();
  }

  void _navigateToUrl() {
    if (_pendingUrl == null || _pendingUrl!.isEmpty) return;
    final uri = Uri.tryParse(_pendingUrl!);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    _pendingUrl = null;
  }

  bool _hasSectionFormat(String? siteName, String text) {
    if (siteName == 'Jobploy') {
      // _parseJobploySections와 동일 필터 적용
      return RegExp(r'\[(.+?)\]').allMatches(text).any((m) {
        final t = m.group(1)!;
        return !t.contains('>') && !t.contains(':') && !t.contains('：') && t.length <= 15;
      });
    }
    if (siteName == 'KoMate') {
      return RegExp(r'📋|🏠|🎁|🚀|🛎️|\[모집분야\]|\[복리후생\]').hasMatch(text);
    }
    if (siteName == 'Kowork') {
      return RegExp(r'\[.+\]').hasMatch(text);
    }
    if (siteName == 'WorkOn') return text.contains('[모집부문') || text.contains('[근무조건') || text.contains('[복지혜택');
    if (siteName == 'TalentLink') return text.contains('[담당업무]');
    if (siteName == 'K-Work') return false;
    if (siteName == 'WorkVisa') return false;
    if (siteName == 'K-HIRE') {
      var cleaned = text;
      cleaned = cleaned.replaceAll(RegExp(r'DESIGNED BY 알바천국\s*'), '');
      cleaned = cleaned.replaceAll(RegExp(r"\(전화 문의시.*?\)"), '').trim();
      // 알바천국 템플릿 (독립된 줄에서만 매칭)
      const albaSections = ['채용정보', '근무조건', '접수내용 및 문의', '접수내용'];
      final albaPattern = RegExp('(?:^|\\n)\\s*(${albaSections.join('|')})\\s*(?=\\n|\$)', multiLine: true);
      if (albaPattern.hasMatch(cleaned)) return true;
      // key:value (콜론 줄 3개 이상 + 그룹핑 가능)
      final lines = cleaned.split('\n').where((l) => l.trim().isNotEmpty).toList();
      final kvCount = lines.where((l) => RegExp(r'^.+[:：]\s*.+').hasMatch(l.trim())).length;
      if (kvCount < 3) return false;
      // 그룹핑 가능 여부까지 체크 (2개 이상 섹션에 매칭)
      const allGroupKeys = {
        '모집마감', '학력', '모집인원', '우대조건', '기타조건',
        '성별', '경력', '나이', '연령', '지원자격', '자격요건',
        '접수방법', '담당자', '담당자명',
        '근무기간', '근무요일', '근무시간', '고용형태', '복리후생', '급여',
        '시급', '월급', '담당업무', '업무',
        '모집직종', '모집부문', '모집분야', '태그',
      };
      final matchedKeys = <String>{};
      for (final line in lines) {
        final stripped = line.trim().replaceFirst(RegExp(r'^[-·•■◈●◇▪◎※＊▶★☆▷→►◆□▣▲△]\s*'), '');
        final m = RegExp(r'^(.+?)[:：]\s*').firstMatch(stripped);
        final key = m?.group(1)?.trim() ?? '';
        if (allGroupKeys.contains(key)) matchedKeys.add(key);
      }
      return matchedKeys.length >= 2;
    }
    return false;
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  /// salary 원문에서 금액 파싱 → 다국어 범위 포맷
  /// 예: "₩25,160,000 ~ ₩35,000,000 / year (협의가능)" → "연봉 2,516만 ~ 3,500만"
  static String? _formatSalaryRange(String salary, String salaryType, AppStrings s) {
    // 괄호 내용 제거 (협의가능, 직접입력 등)
    var cleaned = salary.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    // 금액 추출 (₩ 또는 숫자,숫자 패턴)
    final amounts = RegExp(r'[\₩]?\s*([\d,]+)')
        .allMatches(cleaned)
        .map((m) => int.tryParse(m.group(1)!.replaceAll(',', '')))
        .where((v) => v != null && v > 0)
        .map((v) => v!)
        .toList();

    if (amounts.isEmpty) return null;

    if (amounts.length == 1) {
      return s.formatSalary(salaryType, amounts[0]);
    }

    // 범위: min ~ max
    final min = amounts.reduce((a, b) => a < b ? a : b);
    final max = amounts.reduce((a, b) => a > b ? a : b);
    if (min == max) return s.formatSalary(salaryType, min);

    // 금액만 포맷 (타입 라벨 없이)
    final minAmount = s.formatSalaryAmount(min);
    final maxAmount = s.formatSalaryAmount(max);
    final typeLabel = switch (salaryType) {
      'hourly' => s.salaryHourly,
      'daily' => s.salaryDaily,
      'weekly' => s.salaryWeekly,
      'monthly' => s.salaryMonthly,
      'annual' => s.salaryAnnual,
      _ => '',
    };

    // ko/ja/zh/ar/he: "타입 금액 ~ 금액", 그 외: "₩금액 ~ ₩금액 / 타입"
    return s.formatSalaryRangeDisplay(typeLabel, minAmount, maxAmount);
  }

  static String _displaySalary(Job job, AppStrings s) {
    // 상세화면: salary 원문에서 범위 파싱 → 다국어 포맷
    if (job.salary != null && job.salary!.isNotEmpty && job.salaryTypeRaw != null) {
      final formatted = _formatSalaryRange(job.salary!, job.salaryTypeRaw!, s);
      if (formatted != null) return formatted;
    }
    if (job.salaryAmount != null && job.salaryTypeRaw != null) {
      return s.formatSalary(job.salaryTypeRaw!, job.salaryAmount!);
    }
    switch (job.salaryType) {
      case SalaryType.companyRule:
        return s.salaryByCompany;
      case SalaryType.negotiable:
        return s.salaryNegotiable;
      default:
        return s.salaryByCompany;
    }
  }

  static String _displayWorkTime(Job job, String langCode) {
    final time = job.getWorkTime(langCode);
    return time.isEmpty ? '-' : time;
  }

  static String _formatDeadline(String? expiresAt, String alwaysOpen) {
    if (expiresAt == null) return alwaysOpen;
    final date = DateTime.tryParse(expiresAt);
    if (date == null) return alwaysOpen;
    return '~${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final s = widget.s;
    final langCode = widget.langCode;
    final isFavorite = widget.isFavorite;
    final onFavoriteToggle = widget.onFavoriteToggle;

    return Column(
      children: [
        _TopBar(
          onBack: () => context.pop(),
          title: s.jobDetail,
          trailing: GestureDetector(
            onTap: onFavoriteToggle,
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: 22,
              color: isFavorite ? AppColors.carrot : AppColors.gray300,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 광고 배너 (AdMob)
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: _DetailBannerAd(),
                ),

                // 회사 섹션
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.getTitle(langCode),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(job.company ?? '',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.gray600)),
                      if (job.visas.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6, runSpacing: 6,
                          children: job.visas
                              .map((v) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.tagBlue,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                        v.code == 'ANY' ? s.visaGroupAny : v.code,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.tagBlueTxt)),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFF5F5F5)),

                // 핵심 정보 테이블
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                  child: Column(
                    children: [
                      _InfoRow(label: s.infoSalary, value: _displaySalary(job, s), isOrange: true),
                      _InfoRow(
                        label: s.infoWorkDays,
                        value: job.getWorkSchedule(langCode).isEmpty
                            ? (langCode == 'ko' ? (job.workDays ?? '-') : '-')
                            : job.getWorkSchedule(langCode),
                      ),
                      _InfoRow(
                        label: s.infoWorkTime,
                        value: _displayWorkTime(job, langCode),
                      ),
                      _InfoRow(
                        label: s.infoEmployType,
                        value: job.getEmploymentType(langCode).isEmpty
                            ? '-' : job.getEmploymentType(langCode),
                      ),
                      _InfoRow(
                        label: s.infoJobType,
                        value: job.getJobType(langCode).isEmpty
                            ? '-' : job.getJobType(langCode),
                      ),
                      _InfoRow(
                        label: s.infoDeadline,
                        value: _formatDeadline(job.expiresAt, s.alwaysOpen),
                      ),
                      _AddressRow(
                        label: s.infoWorkplace,
                        job: job,
                        langCode: langCode,
                        showKorean: _showKoreanAddress,
                        toggleLabel: _showKoreanAddress ? s.translateToEnglish : s.translateToKorean,
                        onToggle: langCode != 'ko'
                            ? () {
                                setState(() => _showKoreanAddress = !_showKoreanAddress);
                                analytics.addressTranslateToggled(_showKoreanAddress);
                              }
                            : null,
                      ),
                      if (job.getKoreanLevel(langCode).isNotEmpty)
                        _InfoRow(
                          label: s.tabKoreanLevel,
                          value: job.getKoreanLevel(langCode),
                        ),
                      if (job.benefits.isNotEmpty)
                        _InfoRow(
                          label: s.tabBenefits,
                          value: job.benefits.map((b) => b.getName(langCode)).join(', '),
                        ),
                      if (job.visaSponsorship == true)
                        _InfoRow(label: s.tabVisaSponsorship, value: 'Yes'),
                        _SourceRow(
                          label: s.infoSource,
                          siteName: job.siteName ?? job.siteId,
                          url: job.siteUrl,
                          onTap: job.siteUrl != null
                              ? () => _onSourceTap(job.siteUrl!)
                              : null,
                        ),
                    ],
                  ),
                ),

                // 상세 내용
                if (job.getDescription().isNotEmpty)
                  _DescriptionBlock(
                    text: _translatedHtml ?? job.getDescriptionText(langCode),
                    isLoading: _isTranslating,
                    siteName: job.siteName,
                    titleLabel: s.detailContent,
                    hasSectionFormat: _hasSectionFormat(job.siteName, _translatedHtml ?? job.getDescriptionText(langCode)),
                  ),

                const Divider(height: 1, color: Color(0xFFF5F5F5)),

                // 면책고지
                SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                    child: Text(s.disclaimer,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFBBBBBB), height: 1.7)),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 하단 지원하기 버튼
        Container(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF0F0F0)))),
          child: Builder(builder: (context) {
            final isExpired = job.expiresAt != null &&
                (DateTime.tryParse(job.expiresAt!)?.isBefore(DateUtils.dateOnly(DateTime.now())) ?? false);
            return SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: isExpired
                    ? null
                    : () => _onApplyTap(job.url),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                      color: isExpired ? AppColors.gray300 : AppColors.carrot,
                      borderRadius: BorderRadius.circular(16)),
                  child: Text(
                      isExpired ? s.expired : s.apply,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final String title;
  final Widget? trailing;
  const _TopBar({required this.onBack, this.title = '공고 상세', this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onBack,
            child: const SizedBox(
                width: 40, height: 40,
                child: Icon(Icons.arrow_back_ios_new, size: 20)),
          ),
          Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black)),
          SizedBox(width: 40, child: trailing != null ? Center(child: trailing!) : null),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isOrange;
  final bool isRed;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isOrange = false,
    this.isRed = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF8F8F8))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray300)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value,
                style: TextStyle(
                  fontSize: isOrange ? 15 : 14,
                  fontWeight: FontWeight.w600,
                  color: isOrange
                      ? AppColors.carrot
                      : isRed
                          ? AppColors.urgent
                          : AppColors.black,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final String label;
  final Job job;
  final String langCode;
  final bool showKorean;
  final String? toggleLabel;
  final VoidCallback? onToggle;

  const _AddressRow({
    required this.label,
    required this.job,
    required this.langCode,
    required this.showKorean,
    this.toggleLabel,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final displayLang = showKorean ? 'ko' : langCode;
    final address = job.getAddress(displayLang);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF8F8F8))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray300)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  address.isEmpty ? '-' : address,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          if (onToggle != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.carrot.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    toggleLabel ?? '',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.carrot,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  final String label;
  final String siteName;
  final String? url;
  final VoidCallback? onTap;

  const _SourceRow({
    required this.label,
    required this.siteName,
    this.url,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray300)),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onTap,
                child: Text(
                  siteName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                    decoration: url != null ? TextDecoration.underline : null,
                    decorationColor: AppColors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MultiSourceRow extends StatelessWidget {
  final String label;
  final List<DuplicateSource> sources;
  final void Function(String url) onSourceTap;

  const _MultiSourceRow({
    required this.label,
    required this.sources,
    required this.onSourceTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF8F8F8))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray300)),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              runSpacing: 4,
              children: [
                for (int i = 0; i < sources.length; i++) ...[
                  GestureDetector(
                    onTap: () {
                      final url = sources[i].siteUrl.isNotEmpty
                          ? sources[i].siteUrl
                          : sources[i].jobUrl;
                      if (url.isNotEmpty) onSourceTap(url);
                    },
                    child: Text(
                      sources[i].siteName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.black,
                      ),
                    ),
                  ),
                  if (i < sources.length - 1)
                    const Text(', ',
                        style: TextStyle(fontSize: 14, color: AppColors.gray400)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 미사용 — 이전 세로 레이아웃 (삭제 예정)
class _MultiSourceSection_unused extends StatelessWidget {
  final String label;
  final List<DuplicateSource> sources;
  final void Function(String url) onSourceTap;

  const _MultiSourceSection_unused({
    required this.label,
    required this.sources,
    required this.onSourceTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray300)),
          const SizedBox(height: 8),
          ...sources.map((source) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GestureDetector(
              onTap: () {
                final url = source.siteUrl.isNotEmpty ? source.siteUrl : source.jobUrl;
                if (url.isNotEmpty) onSourceTap(url);
              },
              child: Row(
                children: [
                  const Icon(Icons.open_in_new, size: 14, color: AppColors.gray400),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      source.siteName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}

const _allowedImageDomains = [
  'kowork.kr', 'klik.co.kr', 'saramin.co.kr', 'jobploy.kr',
  'workvisa.co.kr', 'khire.co.kr', 'k-work.or.kr', 'work24.go.kr',
];

bool _isAllowedImageDomain(String? src) {
  if (src == null) return false;
  final host = Uri.tryParse(src)?.host ?? '';
  return _allowedImageDomains.any((d) => host == d || host.endsWith('.$d'));
}

class _DescriptionBlock extends StatelessWidget {
  final String text;
  final bool isLoading;
  final String? siteName;
  final String titleLabel;
  final bool hasSectionFormat;

  const _DescriptionBlock({
    required this.text,
    required this.titleLabel,
    this.isLoading = false,
    this.siteName,
    this.hasSectionFormat = false,
  });

  @override
  Widget build(BuildContext context) {
    final descWidget = _DescriptionText(text: text, isLoading: isLoading, siteName: siteName);
    // _DescriptionText가 SizedBox.shrink()를 반환하면 블록 전체 숨김
    if (!isLoading && text.isNotEmpty && descWidget._isEmpty(text, siteName)) {
      return const SizedBox.shrink();
    }
    return Column(children: [
      const Divider(height: 1, color: Color(0xFFF5F5F5)),
      Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!hasSectionFormat) ...[
              Row(children: [
                Container(
                  width: 3, height: 16,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.carrot,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(titleLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.black)),
              ]),
              const SizedBox(height: 4),
              const Divider(color: Color(0xFFEEEEEE), height: 1),
              const SizedBox(height: 10),
            ],
            descWidget,
          ],
        ),
      ),
    ]);
  }
}

class _DescriptionText extends StatelessWidget {
  final String text;
  final bool isLoading;
  final String? siteName;

  const _DescriptionText({required this.text, this.isLoading = false, this.siteName});

  /// K-HIRE CSS 제거 후 의미 있는 내용이 없는지 체크
  bool _isEmpty(String text, String? siteName) {
    var cleaned = text;
    // K-HIRE CSS/가비지 제거
    if (siteName == 'K-HIRE') {
      cleaned = cleaned.replaceAll(RegExp(r'DESIGNED BY 알바천국\s*'), '');
      cleaned = cleaned.replaceAll(RegExp(r"\(전화 문의시.*?\)"), '');
      cleaned = cleaned.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
      cleaned = cleaned.replaceAll(RegExp(r'\.[\w-]+[^{]*\{[^}]*\}'), '');
      cleaned = cleaned.replaceAll(RegExp(r'@[\w-]+[^{]*\{[^}]*\{[^}]*\}[^}]*\}'), '');
      cleaned = cleaned.replaceAll(RegExp(r'@[\w-]+[^{]*\{[^}]*\}'), '');
      // CSS keyframe 퍼센트 블록 제거 (50% { color:#fff; } 등)
      cleaned = cleaned.replaceAll(RegExp(r'\d+%\s*\{[^}]*\}'), '');
      cleaned = cleaned.split('\n').where((l) => !_isCssLine(l.trim())).join('\n').trim();
    }
    // WorkVisa Markdown 제거
    if (siteName == 'WorkVisa') {
      cleaned = _cleanMarkdown(cleaned);
    }
    final meaningful = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (meaningful.isEmpty) return true;
    if (RegExp(r'^(지원하기\s*)+$').hasMatch(meaningful)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.carrot),
          ),
        ),
      );
    }

    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    // 사이트별 구조화된 렌더링 시도
    if (siteName == 'Jobploy') {
      final sections = _parseJobploySections(text);
      if (sections != null) return _buildSections(sections);
    }
    if (siteName == 'K-HIRE') {
      final result = _parseKHire(text);
      if (result != null) return result;
    }
    if (siteName == 'KoMate') {
      final result = _parseKoMate(text);
      if (result != null) return result;
    }
    if (siteName == 'Kowork') {
      final sections = _parseKowork(text);
      if (sections != null) return _buildSections(sections);
    }
    if (siteName == 'K-Work') {
      final result = _parseKWork(text);
      if (result != null) return result;
    }
    if (siteName == 'TalentLink') {
      final result = _parseTalentLink(text);
      if (result != null) return result;
    }
    if (siteName == 'WorkOn') {
      final sections = _parseWorkon(text);
      if (sections != null) return _buildWorkonSections(sections);
    }
    if (siteName == 'WorkVisa') {
      // Markdown 클린업 후 자유형으로 표시
      final wvCleaned = _cleanMarkdown(text).replaceAll(RegExp(r'\n{2,}'), '\n').trim();
      if (wvCleaned.isEmpty) return const SizedBox.shrink();
      return SelectableText(
        wvCleaned,
        style: const TextStyle(fontSize: 14, color: AppColors.gray500, height: 1.8),
      );
    }

    // 자유형: Markdown 클린업 + 연속 빈 줄 제거
    var cleaned = siteName == 'WorkVisa' ? _cleanMarkdown(text) : text;
    cleaned = cleaned.replaceAll(RegExp(r'\n{2,}'), '\n').trim();
    return SelectableText(
      cleaned,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.gray500,
        height: 1.8,
      ),
    );
  }

  /// Jobploy [섹션명] 파싱
  List<_DescSection>? _parseJobploySections(String text) {
    final pattern = RegExp(r'\[(.+?)\]');
    // NCS 스킬코드(> 포함), 콜론 포함, 15자 초과는 섹션 헤더가 아님
    final matches = pattern.allMatches(text)
        .where((m) {
          final t = m.group(1)!;
          return !t.contains('>') && !t.contains(':') && !t.contains('：') && t.length <= 15;
        })
        .toList();
    if (matches.isEmpty) return null;

    final sections = <_DescSection>[];
    for (int i = 0; i < matches.length; i++) {
      final title = matches[i].group(1)!;
      final start = matches[i].end;
      final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
      final content = text.substring(start, end).trim().replaceAll(RegExp(r'\n{2,}'), '\n');
      if (content.isNotEmpty) {
        sections.add(_DescSection(title: title, content: content));
      }
    }
    return sections.isEmpty ? null : sections;
  }

  /// Workon 서브 헤더 목록
  static const _workonSubHeaders = {
    '직무내용', '상세 근무시간', '조직소개', '직무상세', '우대사항',
    '자격요건', '지원 자격', '전형단계', '근무 예정지', '담당업무',
    '모집직무', '주요업무', '전형방법', '접수방법', '제출서류',
    '제출 서류', '접수 방법', '기타', '교대제',
  };

  /// Workon [섹션명] 파싱
  List<_DescSection>? _parseWorkon(String text) {
    final pattern = RegExp(r'\[(.+?)\]');
    final matches = pattern.allMatches(text).toList();
    if (matches.isEmpty) return null;

    final sections = <_DescSection>[];
    for (int i = 0; i < matches.length; i++) {
      final title = matches[i].group(1)!;
      final start = matches[i].end;
      final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
      var content = text.substring(start, end).trim().replaceAll(RegExp(r'\n{2,}'), '\n');
      // 빈 섹션 (`-`만) 숨김
      if (content == '-' || content.isEmpty) continue;
      sections.add(_DescSection(title: title, content: content));
    }
    return sections.isEmpty ? null : sections;
  }

  /// Workon용 섹션 빌드 (서브 헤더 지원)
  Widget _buildWorkonSections(List<_DescSection> sections) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (section.title.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    width: 3, height: 16,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.carrot,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(section.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.black)),
                ],
              ),
              const SizedBox(height: 4),
              const Divider(color: Color(0xFFEEEEEE), height: 1),
              const SizedBox(height: 10),
            ],
            _buildWorkonContent(section.content),
          ],
        ),
      )).toList(),
    );
  }

  /// Workon 내용 빌드 (서브 헤더 + key:value 처리)
  Widget _buildWorkonContent(String content) {
    final lines = content.split('\n');
    final spans = <InlineSpan>[];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (i > 0 && spans.isNotEmpty) spans.add(const TextSpan(text: '\n'));

      // 접두 기호 제거 후 체크
      final stripped = line.replaceFirst(RegExp(r'^[◇◆○●▶※·•⦁◎■◈☆★▷→►□▣▲△\-\*\s]+'), '').trim();

      // 서브 헤더 체크 (정확 매칭)
      if (_workonSubHeaders.contains(line) || _workonSubHeaders.contains(stripped)) {
        if (spans.isNotEmpty) spans.add(const TextSpan(text: '\n'));
        spans.add(TextSpan(
          text: stripped,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.black, height: 2.0),
        ));
        continue;
      }

      // 콜론 패턴 분석
      final colonIdx = stripped.indexOf(RegExp(r'[:：]'));
      final isTimePattern = colonIdx > 0 && RegExp(r'\d$').hasMatch(stripped.substring(0, colonIdx).trim());
      if (!isTimePattern && colonIdx > 0) {
        final key = stripped.substring(0, colonIdx).trim();
        final value = stripped.substring(colonIdx + 1).trim();

        // 콜론 뒤 값 없음 → 서브 헤더
        if (value.isEmpty) {
          if (spans.isNotEmpty) spans.add(const TextSpan(text: '\n'));
          spans.add(TextSpan(
            text: key,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.black, height: 2.0),
          ));
          continue;
        }

        // 콜론 뒤 값 있음 → key:value
        spans.add(TextSpan(children: [
          TextSpan(text: '$key:', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.black, height: 1.8)),
          TextSpan(text: ' $value', style: const TextStyle(fontSize: 14, color: AppColors.gray500, height: 1.8)),
        ]));
        continue;
      }

      // 일반 텍스트
      spans.add(TextSpan(
        text: line,
        style: const TextStyle(fontSize: 14, color: AppColors.gray500, height: 1.8),
      ));
    }
    return SelectableText.rich(TextSpan(children: spans));
  }

  /// KoMate 파싱 (이모지/브래킷 섹션 헤더 기반)
  Widget? _parseKoMate(String text) {
    var cleaned = text;
    // JSON/API 가비지 제거
    cleaned = cleaned.replaceAll(RegExp(r'"[a-zA-Z_]+"\s*:\s*"[^"]*"'), '');
    cleaned = cleaned.replaceAll(RegExp(r'"type"\s*:\s*"template"'), '');
    // HTML 태그 잔해 제거 (" style="...", " style='...', class="..." 등)
    cleaned = cleaned.replaceAll(RegExp(r'''"\s*style=["'][^"']*["'][^>]*>'''), '');
    cleaned = cleaned.replaceAll(RegExp(r'''"\s*class=["'][^"']*["'][^>]*>'''), '');
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]+>'), '');
    // 유니코드 이스케이프 디코딩 (\u0026 → &)
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\\u([0-9a-fA-F]{4})'),
      (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
    );
    // CSS 제거
    cleaned = cleaned.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'\.[\w-]+[^{]*\{[^}]*\}'), '');
    cleaned = cleaned.replaceAll(RegExp(r'@[\w-]+[^{]*\{[^}]*\{[^}]*\}[^}]*\}'), '');
    cleaned = cleaned.replaceAll(RegExp(r'@[\w-]+[^{]*\{[^}]*\}'), '');
    // CSS keyframe 퍼센트 블록 제거 (50% { color:#fff; } 등)
    cleaned = cleaned.replaceAll(RegExp(r'\d+%\s*\{[^}]*\}'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\n{2,}'), '\n').trim();

    if (cleaned.isEmpty) return const SizedBox.shrink();

    // 이모지/브래킷 섹션 헤더 패턴
    // [모집분야], [복리후생] + 📋 주요업무, 📋 자격요건, 📋 우대사항, 🏠 근무조건, 🎁 복지 및 혜택, 🚀 채용절차, 🛎️ 유의사항
    final headerPattern = RegExp(
      r'(?:^|\n)\s*(?:'
      r'\[([^\]]+)\]'           // [브래킷 헤더]
      r'|'
      r'(📋|🏠|🎁|🚀|🛎️)\s*(.+)'  // 이모지 헤더
      r')\s*(?=\n|$)',
      multiLine: true,
    );

    final matches = headerPattern.allMatches(cleaned).toList();
    if (matches.isEmpty) return null;

    final sections = <_DescSection>[];

    // 첫 헤더 전 텍스트
    final before = cleaned.substring(0, matches.first.start).trim();
    if (before.isNotEmpty) {
      sections.add(_DescSection(title: '', content: before));
    }

    for (int i = 0; i < matches.length; i++) {
      // 브래킷 헤더 또는 이모지 헤더
      final bracketTitle = matches[i].group(1);
      final emoji = matches[i].group(2);
      final emojiTitle = matches[i].group(3);
      final title = bracketTitle ?? emojiTitle?.trim() ?? '';

      final start = matches[i].end;
      final end = i + 1 < matches.length ? matches[i + 1].start : cleaned.length;
      var content = cleaned.substring(start, end).trim();
      content = content.replaceAll(RegExp(r'\n{2,}'), '\n');

      if (title.isNotEmpty && content.isNotEmpty) {
        final displayTitle = emoji != null ? '$emoji $title' : title;
        sections.add(_DescSection(title: displayTitle, content: content));
      } else if (content.isNotEmpty) {
        sections.add(_DescSection(title: '', content: content));
      }
    }

    if (sections.isEmpty) return null;
    return _buildSections(sections);
  }

  /// Kowork 파싱 ([직무 설명], [자격 요건] 등 브래킷 섹션)
  List<_DescSection>? _parseKowork(String text) {
    var cleaned = text;
    // $hex 가비지 제거 ($2d, $33 등)
    cleaned = cleaned.replaceAll(RegExp(r'\$[0-9a-fA-F]{2,}'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\n{2,}'), '\n').trim();

    if (cleaned.isEmpty) return null;

    // [섹션명] 패턴 파싱
    final pattern = RegExp(r'\[([^\]]+)\]');
    final matches = pattern.allMatches(cleaned).toList();
    if (matches.isEmpty) return null;

    final sections = <_DescSection>[];

    // 첫 헤더 전 텍스트
    final before = cleaned.substring(0, matches.first.start).trim();
    if (before.isNotEmpty) {
      sections.add(_DescSection(title: '', content: before));
    }

    for (int i = 0; i < matches.length; i++) {
      final title = matches[i].group(1)!;
      final start = matches[i].end;
      final end = i + 1 < matches.length ? matches[i + 1].start : cleaned.length;
      var content = cleaned.substring(start, end).trim();
      content = content.replaceAll(RegExp(r'\n{2,}'), '\n');
      if (content.isNotEmpty) {
        sections.add(_DescSection(title: title, content: content));
      }
    }

    return sections.isEmpty ? null : sections;
  }

  /// K-Work 파싱 (헤더 key:value + □ 섹션 분할 + ◦ key:value + 가비지 제거)
  Widget? _parseKWork(String text) {
    var cleaned = text;
    cleaned = cleaned.replaceAll('\r\n', '\n');
    cleaned = cleaned.replaceAll('\xa0', ' ');

    // [자격요건] 이후 전부 제거 (100% 가비지)
    final qualIdx = cleaned.indexOf('[자격요건]');
    if (qualIdx > 0) cleaned = cleaned.substring(0, qualIdx).trim();

    // 가비지 제거
    cleaned = cleaned.replaceAll(RegExp(r'\(※\s*각 항목에 대해 상세히 작성.*?바랍니다\.\)\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'(매칭지원센터|기업인력애로센터)\s*[:：]\s*1899-3001[^\n]*\n?'), '');
    cleaned = cleaned.replaceAll(RegExp(r'매칭플랫폼\s*(채널|채팅)?\s*URL\s*[:：][^\n]*\n?'), '');
    cleaned = cleaned.replaceAll(RegExp(r'문의처\s*\n'), '');
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]+>'), '');
    // 빈 유의사항 제거
    cleaned = cleaned.replaceAll(RegExp(r'□\s*유의사항\s*\n?(?=□|\n*$)', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();

    if (cleaned.isEmpty) return null;

    // [담당업무]로 헤더/본문 분리
    final bodyIdx = cleaned.indexOf('[담당업무]');
    if (bodyIdx < 0) {
      return _buildSectionContent(cleaned.replaceAll(RegExp(r'\n{2,}'), '\n'));
    }

    final header = cleaned.substring(0, bodyIdx).trim();
    var body = cleaned.substring(bodyIdx + '[담당업무]'.length).trim();
    body = body.replaceAll(RegExp(r'\n{2,}'), '\n');

    // ◦ 서브헤더 + 고아 값 병합 (◦ 급여정보 \n - 협의 → ◦ 급여정보 : 협의)
    body = body.replaceAllMapped(RegExp(r'\n\s*[:：]\s*'), (m) => ' : ');
    final bodyLines = body.split('\n');
    final merged = <String>[];
    for (int i = 0; i < bodyLines.length; i++) {
      final line = bodyLines[i].trim();
      if (RegExp(r'^[◦○]\s*.+$').hasMatch(line) && !line.contains(':') && !line.contains('：')) {
        if (i + 1 < bodyLines.length) {
          final next = bodyLines[i + 1].trim();
          if (next.startsWith('-') || next.startsWith(':') || next.startsWith('：')) {
            merged.add('$line : ${next.replaceFirst(RegExp(r'^[-:：]\s*'), '')}');
            i++;
            continue;
          }
        }
      }
      merged.add(line);
    }
    body = merged.join('\n');

    // □ 로 섹션 분할
    final sections = <_DescSection>[];

    // 헤더 key:value
    if (header.isNotEmpty) {
      sections.add(_DescSection(title: '', content: header));
    }

    // □ 섹션 분할
    final sectionPattern = RegExp(r'(?:^|\n)\s*□\s*(.+)', multiLine: true);
    final sectionMatches = sectionPattern.allMatches(body).toList();

    if (sectionMatches.isEmpty) {
      // □ 없으면 담당업무 하나로
      if (body.isNotEmpty) {
        sections.add(_DescSection(title: '담당업무', content: body));
      }
    } else {
      // □ 첫 번째 전 텍스트 → 담당업무
      final before = body.substring(0, sectionMatches.first.start).trim();
      if (before.isNotEmpty) {
        sections.add(_DescSection(title: '담당업무', content: before));
      }
      for (int i = 0; i < sectionMatches.length; i++) {
        final title = sectionMatches[i].group(1)!.trim();
        final start = sectionMatches[i].end;
        final end = i + 1 < sectionMatches.length ? sectionMatches[i + 1].start : body.length;
        final content = body.substring(start, end).trim();
        if (content.isNotEmpty) {
          sections.add(_DescSection(title: title, content: content));
        } else if (title.contains(':') || title.contains('：')) {
          // □ 제출서류 : 이력서 같은 한 줄 형태
          sections.add(_DescSection(title: title.split(RegExp(r'[:：]'))[0].trim(),
              content: title.split(RegExp(r'[:：]')).skip(1).join(':').trim()));
        }
      }
    }

    if (sections.isEmpty) return null;
    return _buildSections(sections);
  }

  /// TalentLink 파싱 (헤더 제거 + [섹션] 파싱)
  Widget? _parseTalentLink(String text) {
    var cleaned = text;
    // 특수 문자 제거
    cleaned = cleaned.replaceAll('\u200B', ''); // 제로 폭 공백
    cleaned = cleaned.replaceAll('\uFEFF', ''); // BOM
    cleaned = cleaned.replaceAll('\u200D', ''); // 제로 폭 접합자
    cleaned = cleaned.replaceAll('\u00A0', ' '); // 비표시 공백 → 일반 공백

    // 불릿 앞 줄바꿈 삽입 (• 항목이 가로로 이어진 경우)
    // · 는 단어 구분자(초·중·고)와 불릿 둘 다 쓰이므로 • 만 처리
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([^\n])(•)'),
      (m) => '${m.group(1)}\n${m.group(2)}',
    );

    // 헤더 블록 제거 (첫 번째 [ 이전의 key:value 블록)
    final firstBracket = cleaned.indexOf('[');
    if (firstBracket > 0) {
      cleaned = cleaned.substring(firstBracket).trim();
    }

    if (cleaned.isEmpty) return null;

    // [섹션] 파싱
    final pattern = RegExp(r'\[([^\]]*)\]');
    final matches = pattern.allMatches(cleaned).toList();
    if (matches.isEmpty) return null;

    final sections = <_DescSection>[];

    for (int i = 0; i < matches.length; i++) {
      final title = matches[i].group(1)?.trim() ?? '';
      final start = matches[i].end;
      final end = i + 1 < matches.length ? matches[i + 1].start : cleaned.length;
      var content = cleaned.substring(start, end).trim();
      content = content.replaceAll(RegExp(r'\n{3,}'), '\n\n');

      // 빈 섹션명은 스킵
      if (title.isEmpty && content.isEmpty) continue;
      // 빈 섹션명이지만 내용 있으면 내용만 표시
      if (title.isEmpty && content.isNotEmpty) {
        sections.add(_DescSection(title: '', content: content));
        continue;
      }

      if (content.isNotEmpty) {
        sections.add(_DescSection(title: title, content: content));
      }
    }

    if (sections.isEmpty) return null;
    return _buildSections(sections);
  }

  /// Markdown 클린업 (WorkVisa용)
  static String _cleanMarkdown(String text) {
    var s = text;
    // 이미지 제거 ![alt](url)
    s = s.replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '');
    // 이스케이프 해제
    s = s.replaceAllMapped(RegExp(r'\\([,\-\(\)\.\+\*\_\>\!\|\#])'), (m) => m.group(1)!);
    // 헤더 마커 제거 (텍스트 유지)
    s = s.replaceAllMapped(RegExp(r'^#{1,6}\s*', multiLine: true), (m) => '');
    // 볼드 마커 제거
    s = s.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m.group(1)!);
    // 수평선 제거
    s = s.replaceAll(RegExp(r'^[\*\-]{3,}\s*$', multiLine: true), '');
    // 연속 빈 줄 정리
    s = s.replaceAll(RegExp(r'\n{2,}'), '\n');
    return s.trim();
  }

  /// WorkVisa 파싱 (Markdown + 다양한 템플릿)
  Widget? _parseWorkVisa(String text) {
    var cleaned = _cleanMarkdown(text);
    if (cleaned.isEmpty) return null;

    // 섹션 헤더 패턴들:
    // ◈ 헤더, ✅/💼/🎁 이모지 헤더, ※ 헤더, ▶ 헤더, 1. 번호 헤더
    final headerPattern = RegExp(
      r'(?:^|\n)\s*(?:'
      r'(◈)\s*(.+)'          // ◈ 마커
      r'|'
      r'(✅|💼|🎁|📌|🏠|🚀|🛎️|📋)\s*(.+)'  // 이모지 마커
      r'|'
      r'(※)\s*(.+)'          // ※ 마커
      r'|'
      r'(▶)\s*(.+)'          // ▶ 마커
      r'|'
      r'(\d+)\.\s*(.+)'      // 번호 마커
      r')\s*(?=\n|$)',
      multiLine: true,
    );

    final matches = headerPattern.allMatches(cleaned).toList();
    if (matches.length < 2) return null; // 섹션 2개 미만이면 자유형

    final sections = <_DescSection>[];

    // 첫 헤더 전 텍스트
    final before = cleaned.substring(0, matches.first.start).trim();
    if (before.isNotEmpty) {
      sections.add(_DescSection(title: '', content: before));
    }

    for (int i = 0; i < matches.length; i++) {
      final m = matches[i];
      // 어떤 그룹이 매칭됐는지 확인
      String title;
      if (m.group(1) != null) {
        title = m.group(2)!.trim(); // ◈
      } else if (m.group(3) != null) {
        title = '${m.group(3)} ${m.group(4)!.trim()}'; // 이모지
      } else if (m.group(5) != null) {
        title = m.group(6)!.trim(); // ※
      } else if (m.group(7) != null) {
        title = m.group(8)!.trim(); // ▶
      } else {
        title = m.group(10)!.trim(); // 번호
      }

      final start = m.end;
      final end = i + 1 < matches.length ? matches[i + 1].start : cleaned.length;
      var content = cleaned.substring(start, end).trim();
      content = content.replaceAll(RegExp(r'\n{2,}'), '\n');

      if (content.isNotEmpty) {
        sections.add(_DescSection(title: title, content: content));
      }
    }

    if (sections.isEmpty) return null;
    return _buildSections(sections);
  }

  /// K-HIRE 파싱 (알바천국 템플릿 / key:value / 자유형)
  Widget? _parseKHire(String text) {
    var cleaned = text;

    // 알바천국 워터마크 제거
    cleaned = cleaned.replaceAll(RegExp(r'DESIGNED BY 알바천국\s*'), '');
    // 하단 안내 문구 제거
    cleaned = cleaned.replaceAll(RegExp(r"\(전화 문의시.*?\)"), '');
    // CSS 블록 통째 제거 (한 줄 인라인 CSS 포함)
    // /* 주석 */ 제거
    cleaned = cleaned.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
    // .class { ... } 패턴 반복 제거
    cleaned = cleaned.replaceAll(RegExp(r'\.[\w-]+[^{]*\{[^}]*\}'), '');
    // @media 등 중첩 블록 제거
    cleaned = cleaned.replaceAll(RegExp(r'@[\w-]+[^{]*\{[^}]*\{[^}]*\}[^}]*\}'), '');
    cleaned = cleaned.replaceAll(RegExp(r'@[\w-]+[^{]*\{[^}]*\}'), '');
    // CSS keyframe 퍼센트 블록 제거 (50% { color:#fff; } 등)
    cleaned = cleaned.replaceAll(RegExp(r'\d+%\s*\{[^}]*\}'), '');
    // CSS/스타일 코드 줄 제거
    cleaned = cleaned.split('\n').where((l) => !_isCssLine(l.trim())).join('\n').trim();

    // CSS 제거 후 의미 있는 내용이 없으면 빈 위젯
    final meaningful = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (meaningful.isEmpty || RegExp(r'^(지원하기\s*)+$').hasMatch(meaningful)) {
      return const SizedBox.shrink();
    }

    // 알바천국 템플릿: 채용정보/근무조건/접수내용 섹션 (독립된 줄에서만 매칭)
    final albaSections = ['채용정보', '근무조건', '접수내용 및 문의', '접수내용'];
    // 줄 시작(또는 앞 공백) + 키워드 + 줄 끝(또는 뒤 공백/줄바꿈) — 다른 한글이 붙으면 매칭 안 됨
    final pattern = RegExp('(?:^|\\n)\\s*(${albaSections.join('|')})\\s*(?=\\n|\$)', multiLine: true);
    final matches = pattern.allMatches(cleaned).toList();
    final hasAlbaFormat = matches.isNotEmpty;

    if (hasAlbaFormat) {
      final sections = <_DescSection>[];

      // 섹션 헤더 전 텍스트 (매장명/제목 등)
      if (matches.isNotEmpty) {
        final before = cleaned.substring(0, matches.first.start).trim();
        if (before.isNotEmpty) {
          final beforeCleaned = before.replaceAll(RegExp(r'\n{2,}'), '\n');
          sections.add(_DescSection(title: '상세내용', content: beforeCleaned));
        }
      }

      for (int i = 0; i < matches.length; i++) {
        final title = matches[i].group(1)!;
        final start = matches[i].end;
        final end = i + 1 < matches.length ? matches[i + 1].start : cleaned.length;
        var content = cleaned.substring(start, end).trim();
        content = content.replaceAll(RegExp(r'\n{2,}'), '\n');
        // 앞의 줄바꿈/공백 정리
        content = content.replaceFirst(RegExp(r'^[\n\s]+'), '');
        if (content.isNotEmpty) {
          sections.add(_DescSection(title: title, content: content));
        }
      }
      if (sections.isNotEmpty) return _buildSections(sections);
    }

    // key:value 포맷: 콜론이 있는 줄이 3개 이상 → 섹션 그룹핑
    // 시간 패턴(숫자:숫자), 괄호 시작((07:30)은 제외
    final lines = cleaned.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final kvLines = lines.where((l) {
      final t = l.trim();
      // 콜론 계열 (: ： ៖) 또는 미얀마어 하이픈 구분
      if (RegExp('^.+[:：៖]\\s*.+').hasMatch(t)) {
        final ci = t.indexOf(RegExp('[:：៖]'));
        if (ci > 0 && RegExp(r'\d$').hasMatch(t.substring(0, ci).trim())) return false;
        return true;
      }
      if (RegExp('[\u1000-\u109F]-\\s.+').hasMatch(t)) return true;
      return false;
    }).length;
    // # 마커가 있으면 자유형으로 처리 (markdown 스타일 공고)
    final hasHashHeader = RegExp(r'(?:^|\n)\s*#\s+\S', multiLine: true).hasMatch(cleaned);
    if (!hasHashHeader && kvLines >= 3) {
      // 비한글 텍스트(번역)는 그룹핑 키가 매칭 안 되므로 바로 key 볼드 렌더링
      final hasKorean = RegExp(r'[\uAC00-\uD7AF]').hasMatch(cleaned);
      if (hasKorean) {
        final grouped = _groupKvIntoSections(cleaned);
        if (grouped != null) return _buildSections(grouped);
      }
      return _buildKeyValueText(cleaned);
    }

    return null; // 자유형 → 기본 plaintext
  }

  // 접두 기호 제거 패턴
  static final _prefixRe = RegExp(r'^[-·•■◈●◇◦▪◎※＊▶★☆▷→►◆□▣▲△]\s*');

  /// 줄에서 접두 기호 제거 후 key 추출
  static String _stripPrefix(String line) => line.replaceFirst(_prefixRe, '');

  /// key:value를 채용정보/근무조건/기타 섹션으로 그룹핑
  List<_DescSection>? _groupKvIntoSections(String text) {
    const recruitKeys = {
      '모집마감', '학력', '모집인원', '우대조건', '기타조건',
      '성별', '경력', '나이', '연령', '지원자격', '자격요건',
      '접수방법', '담당자', '담당자명',
    };
    const workKeys = {
      '근무기간', '근무요일', '근무시간', '고용형태', '복리후생', '급여',
      '시급', '월급', '담당업무', '업무',
    };
    const etcKeys = {'모집직종', '모집부문', '모집분야', '태그'};

    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final recruit = <String>[];
    final work = <String>[];
    final etc = <String>[];
    final rest = <String>[];

    for (final line in lines) {
      final stripped = _stripPrefix(line.trim());
      final m = RegExp(r'^(.+?)[:：]\s*').firstMatch(stripped);
      final key = m?.group(1)?.trim() ?? '';
      if (recruitKeys.contains(key)) {
        recruit.add(line.trim());
      } else if (workKeys.contains(key)) {
        work.add(line.trim());
      } else if (etcKeys.contains(key)) {
        etc.add(line.trim());
      } else {
        rest.add(line.trim());
      }
    }

    // 최소 2개 섹션에 데이터가 있어야 그룹핑 의미 있음
    final filled = [recruit, work, etc].where((s) => s.isNotEmpty).length;
    if (filled < 2) return null;

    final sections = <_DescSection>[];
    if (recruit.isNotEmpty) {
      sections.add(_DescSection(title: '채용정보', content: recruit.join('\n')));
    }
    if (work.isNotEmpty) {
      sections.add(_DescSection(title: '근무조건', content: work.join('\n')));
    }
    if (etc.isNotEmpty) {
      sections.add(_DescSection(title: '기타', content: etc.join('\n')));
    }
    if (rest.isNotEmpty) {
      sections.add(_DescSection(title: '', content: rest.join('\n')));
    }
    return sections;
  }

  /// key:value 텍스트를 key 볼드로 렌더링 (그룹핑 실패 시 폴백)
  Widget _buildKeyValueText(String text) {
    // _buildSectionContent와 동일 로직 사용
    return _buildSectionContent(text);
  }

  // 섹션 내부 key 패턴 (공백 구분 — 알바천국 + K-HIRE + Jobploy)
  static const _sectionKeys = {
    // 알바천국
    '업무내용', '지원자격', '우대사항', '지원방법', '마감일', '연락처', '기타사항',
    '면접장소', '급여조건', '직원혜택',
    // K-HIRE 추가
    '모집부문', '모집분야', '전형절차', '접수방법', '담당업무', '담당자', '담당자명',
    '경력', '시급', '월급', '나이', '연령', '통근버스', '기숙사', '급여일',
    '상세요강', '근무장소', '근무위치', '자격요건', '기타', '수습기간', '근무환경', '상여금',
    // 공통
    '근무요일', '근무시간', '근무기간', '급여', '고용형태', '복리후생',
    '모집인원', '학력', '모집마감', '기타조건', '우대조건', '모집직종', '성별',
    // KoMate
    '접수기간', '급여제도',
    // WorkVisa
    '하는일', '인원', '국적', '복지', '지역',
    // K-Work
    '직종', '급여정보', '필요학력', '근무일시 및 시간', '근무일시',
    '자격요건 및 우대사항', '근무형태(수습기간 포함)',
    '접수기간 및 방법', '지원방법절차', '근무장소(여러 직무인 경우 복수 기재)',
    // Jobploy
    '직무', '필요조건', '4대보험', '보너스', '언어능력', '비자',
    '휴게시간', '연령대', '식사/식대', '직무내용', '숙소', '휴가',
    '우대국가', '근무지', '근무형태', '점심시간', '야간', '교통편',
    '주간', '임금', '근무지역', '근무내용',
    '주요업무', '주요 업무', '문의', '잔업', '주소',
  };

  // CSS/스타일 코드 줄 판별 (한글 포함 줄은 실제 콘텐츠이므로 제외)
  static bool _isCssLine(String line) {
    if (RegExp(r'[\uAC00-\uD7AF]').hasMatch(line)) return false;
    if (line.contains('{') && (line.contains(';') || line.contains('}'))) return true;
    if (line.startsWith('/*') || line.startsWith('@font-face') || line.startsWith('@media')) return true;
    if (RegExp(r'^\.[a-zA-Z_].*\{').hasMatch(line)) return true;
    return false;
  }

  Widget _buildSectionContent(String content) {
    final lines = content.split('\n');
    final rows = <InlineSpan>[]; // 한 줄 단위
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      if (_isCssLine(line)) continue;

      // 접두 마커 추출 (렌더링에 유지)
      final prefixMatch = _prefixRe.firstMatch(line);
      final prefix = prefixMatch?.group(0) ?? '';
      final cleaned = _stripPrefix(line)
          .replaceFirst(RegExp(r',\s*주\s*\d일\s*근무,\s*평균근무시간\s*[:：]\s*\d+'), '')
          .trim();

      if (cleaned.isEmpty) continue;

      // URL 줄은 일반 텍스트로
      if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
        rows.add(TextSpan(
          text: line,
          style: const TextStyle(fontSize: 14, color: AppColors.gray500, height: 1.8),
        ));
        continue;
      }

      // 1) 콜론 구분 key:value (시간 패턴 제외, 크메르 ៖ 포함)
      final colonIdx = cleaned.indexOf(RegExp('[:：៖]'));
      final isTimePattern = colonIdx > 0 && RegExp(r'\d$').hasMatch(cleaned.substring(0, colonIdx).trim());
      // 미얀마어: 콜론 없고 "key- value" 패턴 (미얀마 문자 뒤 하이픈)
      final myDashMatch = colonIdx < 0 ? RegExp('([\u1000-\u109F\u1050-\u109F])-\\s').firstMatch(cleaned) : null;
      final sepIdx = colonIdx > 0 ? colonIdx : myDashMatch != null ? myDashMatch.start + 1 : -1;
      if (!isTimePattern && sepIdx > 0 && sepIdx < cleaned.length - 1) {
        final key = cleaned.substring(0, sepIdx + 1);
        final value = cleaned.substring(sepIdx + 1).trim().replaceFirst(RegExp(r'^[·\*]\s*'), '');
        if (value.isEmpty) continue;
        rows.add(TextSpan(children: [
          TextSpan(text: '$prefix$key', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.black, height: 1.8)),
          TextSpan(text: ' $value', style: const TextStyle(fontSize: 14, color: AppColors.gray500, height: 1.8)),
        ]));
      }
      // 2) 공백 구분 key value
      else if (_matchSectionKey(cleaned) case (final key, final value)?) {
        final cleanValue = value.replaceFirst(RegExp(r'^[·\*]\s*'), '');
        if (cleanValue.isEmpty) continue;
        rows.add(TextSpan(children: [
          TextSpan(text: '$prefix$key:', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.black, height: 1.8)),
          TextSpan(text: ' $cleanValue', style: const TextStyle(fontSize: 14, color: AppColors.gray500, height: 1.8)),
        ]));
      }
      // 3) 일반 텍스트
      else {
        rows.add(TextSpan(
          text: line,
          style: const TextStyle(fontSize: 14, color: AppColors.gray500, height: 1.8),
        ));
      }
    }
    final spans = <InlineSpan>[];
    for (int i = 0; i < rows.length; i++) {
      spans.add(rows[i]);
      if (i < rows.length - 1) spans.add(const TextSpan(text: '\n'));
    }
    return SelectableText.rich(TextSpan(children: spans));
  }

  // _sectionKeys를 길이 내림차순으로 정렬 (긴 키 우선 매칭)
  static final _sortedSectionKeys = _sectionKeys.toList()..sort((a, b) => b.length.compareTo(a.length));

  static (String, String)? _matchSectionKey(String line) {
    for (final key in _sortedSectionKeys) {
      if (line.startsWith(key)) {
        // key 바로 뒤가 한글이면 부분 매칭이므로 스킵 (경력자→경력 매칭 방지)
        if (line.length > key.length && RegExp(r'[\uAC00-\uD7AF]').hasMatch(line[key.length])) continue;
        final rest = line.substring(key.length).trim();
        return (key, rest);
      }
    }
    return null;
  }

  Widget _buildSections(List<_DescSection> sections) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 (title이 있을 때만)
            if (section.title.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.carrot,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    section.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Divider(color: Color(0xFFEEEEEE), height: 1),
              const SizedBox(height: 10),
            ],
            // 내용: key:value 패턴이면 key 볼드 처리
            _buildSectionContent(section.content),
          ],
        ),
      )).toList(),
    );
  }
}

class _DescSection {
  final String title;
  final String content;
  const _DescSection({required this.title, required this.content});
}

class _DetailBannerAd extends StatefulWidget {
  const _DetailBannerAd();

  @override
  State<_DetailBannerAd> createState() => _DetailBannerAdState();
}

class _DetailBannerAdState extends State<_DetailBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      height: AdSize.banner.height.toDouble(),
      child: Center(child: AdWidget(ad: _bannerAd!)),
    );
  }
}
