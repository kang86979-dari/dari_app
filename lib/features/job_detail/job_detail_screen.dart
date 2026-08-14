import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../core/utils/ad_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../apply/apply_webview_screen.dart';
import '../apply/site_lang.dart';
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

/// K-HIRE 알바천국 브랜드명 — 원문 + 실제 GT 번역 변형 (translate-description 실측 기반)
/// zh 阿尔巴天堂 / ja アルバ天国 / th อัลบาเฮเว่น / uz Alba osmoni
/// hi·ne(अल्बा)·bn(আলবা)은 음차 어근만 매칭 (हेवेन/हेभन/स्वर्ग/হেভেন 등 표기 흔들림 대응)
/// 주의: ja는 アルバ 단독 사용 금지 (アルバイト 오폭)
const _albaBrand =
    r'(알바천국|Alba\s?(Heaven|Surga|osmon\w*)|阿尔巴天堂|アルバ天国|আলবা|अल्बा|อัลบาเฮเว่น)';

/// 워터마크 구문 제거 (접두어 + 브랜드, 같은 줄에 실내용이 붙은 케이스 대응)
final _albaWatermarkRe = RegExp(
  r'(DESIGNED BY|DIRANCANG OLEH|THIẾT KẾ BỞI|រចនាដោយ)\s*' '$_albaBrand' r'\s*',
  caseSensitive: false,
);

/// 구문 제거 후에도 브랜드 언급이 남은 줄 통째 제거
/// (워터마크 변형 + 번역된 전화 안내문: "I saw this on Alba Heaven..." 등)
final _albaWatermarkLineRe = RegExp(
  r'(?:^|\n)[^\n]*' '$_albaBrand' r'[^\n]*(?=\n|$)',
  caseSensitive: false,
);

/// K-HIRE 하단 전화 안내 문구 — 원문 + 영어 번역 변형
final _albaPhoneNoticeRe = RegExp(r'\(전화 문의시.*?\)');
final _albaPhoneNoticeEnRe =
    RegExp(r'\((When|For)[^)]{0,120}(phone|call)[^)]*\)', caseSensitive: false);

/// 벼룩시장(FindJob) 워터마크 브랜드 — GT가 언어별로 브랜드명을 번역함 (실번역 15개 언어 수집으로 확정)
/// 벼룩시장 공고엔 "DESIGNED BY 벼룩시장"(442건)·"DESIGNED BY 알바천국"(184건) 두 종이 있음.
final _fleaBrandRe = RegExp(
  r'(벼룩시장|flea\s?market|ノミ市場|跳蚤市场|Барахолка|ตลาดนัด|पिस्सू\s?बाज़?ार|फ्ली\s?मार्केट|ফ্লি\s?মার্কেট|Buyum\s?bozori|'
  r'알바천국|Alba\s?(Heaven|Surga|osmon\w*)|阿尔巴天堂|アルバ天国|আলবা|अल्बा|อัลบา)',
  caseSensitive: false,
);

/// "DESIGNED BY ..." 워터마크의 언어별 디자인동사 (짧은 단독 줄만 매칭 — 본문 오폭 방지)
final _fleaDesignedLineRe = RegExp(
  r'^.{0,40}(designed\s?by|dirancang oleh|thiết kế bởi|រចនាដោយ|ออกแบบโดย|ဒီဇိုင်းထုတ်|විසින්\s?නිර්මාණය|tomonidan ishlab chiqilgan|зохион байгуулсан|разработка|由.{0,14}设计|द्वारा डिज़?ाइन|দ্বারা ডিজাইন|ডিজাইন করা).{0,40}$',
  caseSensitive: false,
);

/// 벼룩시장 워터마크/출처 안내 줄 제거 (브랜드 언급 줄 + 디자인동사 짧은 줄)
String _stripFleaGarbage(String text) {
  return text
      .split('\n')
      .where((l) => !_fleaBrandRe.hasMatch(l) && !_fleaDesignedLineRe.hasMatch(l.trim()))
      .join('\n');
}

/// K-HIRE 워터마크/안내문 일괄 제거
String _stripAlbaGarbage(String text) {
  var cleaned = text;
  cleaned = cleaned.replaceAll(_albaPhoneNoticeRe, '');
  cleaned = cleaned.replaceAll(_albaPhoneNoticeEnRe, '');
  cleaned = cleaned.replaceAll(_albaWatermarkRe, '');
  cleaned = cleaned.replaceAll(_albaWatermarkLineRe, '\n');
  return cleaned;
}

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
      if (result.isNotEmpty) {
        setState(() {
          _translatedHtml = result
              .replaceAll('\\r\\n', '\n')
              .replaceAll('\\n', '\n')
              .replaceAll('\\r', '\n')
              // CSS 제거
              .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
              .replaceAll(RegExp(r'\.[\w-]+\s*\{[^}]*\}'), '')
              .replaceAll(RegExp(r'[.#:*][\w-][^{]*\{[^}]*\}'), '')
              .replaceAll(RegExp(r'@[\w-]+[^{]*\{[^}]*\{[^}]*\}[^}]*\}'), '')
              .replaceAll(RegExp(r'@[\w-]+[^{]*\{[^}]*\}'), '')
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
    } catch (_) {
      // Edge Function 실패 시 DB 캐시 확인 (서버에서 저장 성공했을 수 있음)
      if (!mounted || langCode != widget.langCode) return;
      // 클라이언트 타임아웃이어도 서버는 번역을 완료해 DB에 저장했을 수 있음
      // → 지연을 두고 DB 캐시를 2회 재확인 (3초 후, 8초 후)
      for (final delay in const [Duration(seconds: 3), Duration(seconds: 5)]) {
        await Future.delayed(delay);
        if (!mounted || langCode != widget.langCode) return;
        try {
          final job = await JobRepository().getJobById(widget.job.id);
          if (!mounted || langCode != widget.langCode) return;
          final cached = job?.descriptionTranslations[langCode]?.toString();
          if (cached != null && cached.isNotEmpty) {
            setState(() {
              _translatedHtml = cached;
              _isTranslating = false;
            });
            return;
          }
        } catch (_) {}
      }
    }
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
    final url = _pendingUrl!;
    _pendingUrl = null;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      if (Platform.isIOS) {
        // iOS: 인앱 사파리(SFSafariViewController) — 네이티브 번역(aA→번역)·로그인 세션 정상.
        // URL 로케일 사이트(WorkVisa·Jobploy·WorkOn·Kowork)는 사파리에서도 언어 치환 적용.
        // 쿠키 그룹 사이트는 사파리 쿠키에 접근 불가 → 사이트 자체 언어 UI 사용.
        ChromeSafariBrowser().open(
          url: WebUri(SiteLang.entryUrl(url, widget.langCode)),
          settings: ChromeSafariBrowserSettings(barCollapsingEnabled: true),
        );
      } else {
        // Android: 인앱 WebView — 번역은 각 사이트 자체 다국어 기능 사용 (10개 사이트 전부 보유)
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ApplyWebViewScreen(url: url, langCode: widget.langCode),
        ));
      }
    } else {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool _hasSectionFormat(String? siteName, String text) {
    if (siteName == 'Jobploy') {
      // _parseJobploySections와 동일 필터 적용
      return RegExp(r'[\[【](.+?)[\]】]').allMatches(text).any((m) {
        final t = m.group(1)!.trim();
        return !t.contains('>') && !t.contains(':') && !t.contains('：') && t.length <= 40;
      });
    }
    if (siteName == 'KoMate') {
      return RegExp(r'📋|🏠|🎁|🚀|🛎️|[\[【](모집분야|복리후생|Recruitment field|Welfare benefits|Welfare and Benefits)[\]】]').hasMatch(text);
    }
    if (siteName == 'Kowork') {
      return RegExp(r'[\[【].+[\]】]').hasMatch(text);
    }
    if (siteName == 'WorkOn') return RegExp(r'[\[【](주요업무|자격요건|우대사항|복지혜택|모집직무|모집부문|근무조건|직무소개|기타|Main tasks|Main duties|Qualifications|Qualification|Preferential|Welfare|Working conditions|Recruitment|Job introduction)').hasMatch(text);
    if (siteName == 'TalentLink') return RegExp(r'[\[【](담당업무|Duties|Responsibilities|Company Introduction|Working conditions|Qualifications|Preferential|Recruitment Procedure|Other)').hasMatch(text);
    if (siteName == 'K-Work') return false;
    if (siteName == 'WorkVisa') return false;
    if (siteName == 'K-HIRE') {
      var cleaned = _stripAlbaGarbage(text).trim();
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
                        style: TextStyle(
                          // 카드와 동일 기준: CJK는 크게, 번역으로 길어지는 그 외 언어는 축소
                          fontSize: const {'ko', 'ja', 'zh', 'zh-yue'}.contains(langCode)
                              ? 19.0
                              : 16.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                          (job.company != null && job.company!.isNotEmpty)
                              ? job.company!
                              : s.companyUndisclosed,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: (job.company != null && job.company!.isNotEmpty)
                                  ? AppColors.gray600
                                  : AppColors.gray400)),
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
                          value: job.getBenefits(langCode),
                        ),
                      if (job.visaSponsorship == true)
                        _InfoRow(label: s.tabVisaSponsorship, value: s.visaSponsorshipYes),
                      // 지원방법: 크롤 수집 apply_methods 있을 때만 표시(1단계=표시 전용, 칩 탭 동작 없음).
                      // null/빈 배열/미지 코드뿐이면 위젯이 행 자체를 숨김.
                      if (job.applyMethods.isNotEmpty)
                        _ApplyMethodsRow(
                          label: s.infoApplyMethod,
                          methods: job.applyMethods,
                          strings: s,
                        ),
                      // 사이트명 없으면(RLS로 숨겨진 testing 사이트) 출처 행 생략 — UUID 노출 방지
                      if (job.siteName != null && job.siteName!.isNotEmpty)
                        _SourceRow(
                          label: s.infoSource,
                          siteName: job.siteName!,
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
                    jobUrl: job.url,
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
    // 값이 없거나 '-'면 행 자체를 숨김 (상세 정보 테이블 깔끔하게)
    if (value.trim().isEmpty || value.trim() == '-') {
      return const SizedBox.shrink();
    }
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

// 지원방법 칩 행 (아이콘 + 라벨 Wrap). 정규화 코드 배열을 app_strings로 16개 언어 렌더.
// 1단계=표시 전용(칩 탭 동작 없음). 라벨 없는 미지 코드는 칩 생략, 전부 미지면 행 숨김.
class _ApplyMethodsRow extends StatelessWidget {
  final String label;
  final List<String> methods; // 정규화 코드
  final AppStrings strings;
  const _ApplyMethodsRow({
    required this.label,
    required this.methods,
    required this.strings,
  });

  // 코드 → 아이콘. 라벨은 app_strings(다국어)에서 가져옴.
  static const Map<String, IconData> _icons = {
    'online': Icons.computer_outlined,
    'homepage': Icons.language,
    'email': Icons.email_outlined,
    'phone': Icons.phone_outlined,
    'sms': Icons.sms_outlined,
    'simple': Icons.flash_on,
    'chat': Icons.chat_bubble_outline,
    'visit': Icons.place_outlined,
    'other': Icons.more_horiz,
  };

  @override
  Widget build(BuildContext context) {
    // 서버가 새 코드를 추가해도 정보 공백이 없도록, 모르는 코드는 "기타" 칩으로 표시.
    // (숨기면 그 방법뿐인 공고는 지원방법 행이 통째로 사라짐 — 다음 릴리즈에서 정식 라벨 추가)
    // 모르는 코드 여러 개 → "기타" 칩 중복 방지 (라벨 기준 dedup)
    final seenLabels = <String>{};
    final renderable = <String>[];
    for (final m in methods) {
      final label = strings.applyMethodLabel(m) ?? strings.applyMethodOther;
      if (seenLabels.add(label)) renderable.add(m);
    }
    if (renderable.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF8F8F8))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray300)),
          const SizedBox(width: 16),
          // 칩은 항상 1줄. 적으면 우측 정렬(테이블 값과 일관), 많으면 왼쪽부터 가로 스크롤.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (var i = 0; i < renderable.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        _chip(renderable[i]),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String code) {
    final icon = _icons[code] ?? Icons.more_horiz;
    // 모르는 코드는 "기타" 라벨로 폴백 (16개 언어)
    final text = strings.applyMethodLabel(code) ?? strings.applyMethodOther;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.carrotLight, // 연한 주황 배경 — 회색 정보 속에서 눈에 띄게
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.carrot),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.carrot)),
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
  final String? jobUrl; // 벼룩시장 등 URL 도메인 기반 포맷 판별용 (테스트 모드선 siteName이 null)
  final String titleLabel;
  final bool hasSectionFormat;

  const _DescriptionBlock({
    required this.text,
    required this.titleLabel,
    this.isLoading = false,
    this.siteName,
    this.jobUrl,
    this.hasSectionFormat = false,
  });

  @override
  Widget build(BuildContext context) {
    final descWidget = _DescriptionText(text: text, isLoading: isLoading, siteName: siteName, jobUrl: jobUrl);
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
  final String? jobUrl;

  const _DescriptionText({required this.text, this.isLoading = false, this.siteName, this.jobUrl});

  // 벼룩시장(FindJob 글로벌) 판별 — 테스트 모드에선 sites RLS로 siteName이 null이라 URL 도메인으로도 판별.
  bool get _isFindJob =>
      siteName == '벼룩시장' ||
      siteName == 'FindJob' ||
      (jobUrl?.contains('findjob.co.kr') ?? false);

  /// K-HIRE CSS 제거 후 의미 있는 내용이 없는지 체크
  bool _isEmpty(String text, String? siteName) {
    var cleaned = text;
    // K-HIRE CSS/가비지 제거
    if (siteName == 'K-HIRE') {
      cleaned = _stripAlbaGarbage(cleaned);
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
    if (_isApplyOnly(meaningful)) return true;
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
    if (_isFindJob) {
      final sections = _parseFindJob(_stripFleaGarbage(text));
      if (sections != null) return _buildSections(sections);
    }
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
    if (siteName == 'JobnShop') {
      // 키:값 줄 구조 → 키 볼드 + 값 회색 (다른 사이트 공통 렌더러 재사용)
      // 값 없이 구분자로 끝나는 "라벨만" 줄은 정보가 없어 제거.
      //   전 언어 대응: 콜론(:／：), 하이픈(-–—), 슬래시(/) 등 어떤 구분자로 끝나든 제거
      //   예: "문의:", "Contact us:", "お問い合わせ：", 미얀마어 "…ပါ-", "문의: /"
      final kept = _stripMdText(text).split('\n').where((line) {
        final l = line.trim();
        if (l.isEmpty) return true; // 빈 줄은 아래 정규화에서 정리
        // 뒤쪽 공백+구분자(:：/-–— · •)를 제거한 본문
        final body = l.replaceAll(RegExp(r'[\s:：/·•\-–—]+$'), '');
        if (body.isEmpty) return false; // 구분자만 있는 줄
        // 잘려나간 꼬리에 실제 구분자가 있으면(=값 없는 라벨) 제거
        final tail = l.substring(body.length);
        return !RegExp(r'[:：/·•\-–—]').hasMatch(tail);
      }).join('\n');
      final cleaned = kept.replaceAll(RegExp(r'\n{2,}'), '\n').trim();
      if (cleaned.isEmpty) return const SizedBox.shrink();
      return _buildSectionContent(cleaned);
    }
    if (siteName == 'WorkVisa') {
      // 섹션 파서 시도 → 실패 시 key:value 볼드 렌더링
      final wvResult = _parseWorkVisa(text);
      if (wvResult != null) return wvResult;
      final wvCleaned = _cleanMarkdown(text).replaceAll(RegExp(r'\n{2,}'), '\n').trim();
      if (wvCleaned.isEmpty) return const SizedBox.shrink();
      return _buildSectionContent(wvCleaned);
    }

    // 자유형: Markdown 클린업 + 연속 빈 줄 제거
    var cleaned = siteName == 'WorkVisa' ? _cleanMarkdown(text) : _stripMdText(text);
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

  /// Jobploy [섹션명] / 【섹션명】 파싱
  List<_DescSection>? _parseJobploySections(String text) {
    final pattern = RegExp(r'[\[【](.+?)[\]】]');
    // NCS 스킬코드(> 포함), 콜론 포함, 40자 초과는 섹션 헤더가 아님
    final matches = pattern.allMatches(text)
        .where((m) {
          final t = m.group(1)!.trim();
          return !t.contains('>') && !t.contains(':') && !t.contains('：') && t.length <= 40;
        })
        .toList();
    if (matches.isEmpty) return null;

    final sections = <_DescSection>[];
    // 첫 인정 헤더 이전 텍스트 보존 (번역 헤더가 필터 탈락해도 본문 유실 방지)
    final before = text.substring(0, matches.first.start).trim();
    if (before.isNotEmpty) {
      sections.add(_DescSection(title: '', content: before.replaceAll(RegExp(r'\n{2,}'), '\n')));
    }
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

  /// Workon 서브 헤더 목록 (한국어 + 번역)
  static const _workonSubHeaders = {
    // 한국어
    '직무내용', '상세 근무시간', '조직소개', '직무상세', '우대사항',
    '자격요건', '지원 자격', '전형단계', '근무 예정지', '담당업무',
    '모집직무', '주요업무', '전형방법', '접수방법', '제출서류',
    '제출 서류', '접수 방법', '기타', '교대제',
    // 영어
    'Job description', 'Job Description', 'Detailed working hours',
    'Shift system', 'Organization introduction', 'Job details',
    'Preferential treatment', 'Qualifications', 'Eligibility to apply',
    'Selection stage', 'Place of work', 'Responsibilities',
    'Recruitment job', 'Main tasks', 'Selection method',
    'How to apply', 'Documents to be submitted', 'Etc', 'Others',
    // 중국어
    '职位描述', '详细工作时间', '轮班制度', '组织介绍', '职位详情',
    '优惠待遇', '资格', '申请资格', '选拔阶段', '工作地点',
    '职责', '招聘职位', '主要任务', '选型方法', '如何申请',
    '需提交的文件', '其他',
    // 일본어
    '職務内容', '詳細な勤務時間', '交代制', '組織紹介', '職務詳細',
    '優遇事項', '資格要件', '選考段階', '勤務予定地', '担当業務',
    '募集職務', '主な仕事', '選考方法', '受付方法', '提出書類', 'その他',
    // 기타 타깃 언어 (직무내용 / 상세 근무시간 계열 — GT 추정 표기)
    'Nội dung công việc', 'Thời gian làm việc chi tiết',           // vi
    'รายละเอียดงาน', 'เวลาทำงานโดยละเอียด',                          // th
    'কাজের বিবরণ', 'বিস্তারিত কাজের সময়',                            // bn
    'රැකියා විස්තර', 'සවිස්තරාත්මක වැඩ කරන වේලාව',                    // si
    'လုပ်ငန်းအကြောင်းအရာ', 'အသေးစိတ်အလုပ်ချိန်',                        // my
    'ខ្លឹមសារការងារ', 'ម៉ោងធ្វើការលម្អិត',                              // km
    'कामको विवरण', 'विस्तृत काम गर्ने समय',                            // ne
    'Ish mazmuni', 'Batafsil ish vaqti',                            // uz
    'Ажлын агуулга', 'Дэлгэрэнгүй ажиллах цаг',                     // mn
    'Deskripsi pekerjaan', 'Jam kerja terperinci',                  // id
    'Содержание работы', 'Подробное рабочее время',                 // ru
  };

  /// Workon [섹션명] / 【섹션명】 파싱 (중국어/일본어 번역 대응)
  List<_DescSection>? _parseWorkon(String text) {
    final pattern = RegExp(r'[\[【](.+?)[\]】]');
    final matches = pattern.allMatches(text).toList();
    if (matches.isEmpty) return null;

    final sections = <_DescSection>[];
    for (int i = 0; i < matches.length; i++) {
      final title = matches[i].group(1)!;
      final start = matches[i].end;
      final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
      var content = text.substring(start, end).trim().replaceAll(RegExp(r'\n{2,}'), '\n');
      // 빈 섹션 (`-`/`None`/`없음`만) 숨김 — 크롤러가 빈 필드를 'None' 문자열로 저장하는 케이스 포함
      if (content == '-' || content == 'None' || content == '없음' || content.isEmpty) continue;
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3, height: 16,
                    margin: const EdgeInsets.only(right: 8, top: 2),
                    decoration: BoxDecoration(
                      color: AppColors.carrot,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // 번역된 긴 제목 오버플로우 방지 — 줄바꿈 허용
                  Expanded(
                    child: Text(section.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.black)),
                  ),
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
      final line = _stripMdLine(lines[i].trim()).trim();
      if (line.isEmpty) continue;

      if (i > 0 && spans.isNotEmpty) spans.add(const TextSpan(text: '\n'));

      // 접두 기호 제거 후 체크
      final stripped = line.replaceFirst(RegExp(r'^[◇◆○●▶※·•⦁◎■◈☆★▷→►□▣▲△\-\*\s]+'), '').trim();

      // 서브 헤더 체크 (대소문자 무시)
      if (_workonSubHeaders.any((h) => h.toLowerCase() == line.toLowerCase() || h.toLowerCase() == stripped.toLowerCase())) {
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
    // JSON 상태 덤프 줄 제거 ("key":숫자/불리언 등 패턴이 3개 이상인 줄 — React Query 덤프)
    cleaned = cleaned
        .split('\n')
        .where((l) => RegExp(r'"[a-zA-Z_]+"\s*:').allMatches(l).length < 3)
        .join('\n');
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
    if (matches.isEmpty) {
      // 구조 없음 → 원문 raw 노출 대신 클린업된 텍스트로 렌더링
      return SelectableText(
        cleaned,
        style: const TextStyle(fontSize: 14, color: AppColors.gray500, height: 1.8),
      );
    }

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

    if (sections.isEmpty) {
      // 헤더만 있고 내용 없음 → 클린업된 텍스트로 렌더링
      return SelectableText(
        cleaned,
        style: const TextStyle(fontSize: 14, color: AppColors.gray500, height: 1.8),
      );
    }
    return _buildSections(sections);
  }

  /// Kowork 파싱 ([직무 설명], [자격 요건] 등 브래킷 섹션)
  List<_DescSection>? _parseKowork(String text) {
    var cleaned = text;
    // $hex 가비지 제거 ($2d, $33 등)
    cleaned = cleaned.replaceAll(RegExp(r'\$[0-9a-fA-F]{2,}'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\n{2,}'), '\n').trim();

    if (cleaned.isEmpty) return null;

    // [섹션명] / 【섹션명】 패턴 파싱
    final pattern = RegExp(r'[\[【]([^\]】]+)[\]】]');
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

    // [자격요건]/[Qualifications] 이후 전부 제거 (100% 가비지, zh/ja 번역 포함)
    final qualPattern = RegExp(r'\[(자격요건|Qualifications|资格要求|資格要件)\]');
    final qualMatch = qualPattern.firstMatch(cleaned);
    if (qualMatch != null && qualMatch.start > 0) cleaned = cleaned.substring(0, qualMatch.start).trim();

    // 가비지 제거 — ※ 괄호 작성 안내문은 언어 무관 제거 (번역판 대응)
    cleaned = cleaned.replaceAll(RegExp(r'\(※\s*각 항목에 대해 상세히 작성.*?바랍니다\.\)\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[（(]\s*※[^)）]*[)）]\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'(매칭지원센터|기업인력애로센터)\s*[:：]\s*1899-3001[^\n]*\n?'), '');
    cleaned = cleaned.replaceAll(RegExp(r'매칭플랫폼\s*(채널|채팅)?\s*URL\s*[:：][^\n]*\n?'), '');
    cleaned = cleaned.replaceAll(RegExp(r'문의처\s*\n'), '');
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]+>'), '');
    // 빈 유의사항 제거
    cleaned = cleaned.replaceAll(RegExp(r'□\s*유의사항\s*\n?(?=□|\n*$)', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();

    if (cleaned.isEmpty) return null;

    // [담당업무]/[Duties in charge]/[Duties]로 헤더/본문 분리
    final bodyPattern = RegExp(r'\[(담당업무|Duties in charge|Duties|负责业务|担当業務)\]');
    var bodyMatch = bodyPattern.firstMatch(cleaned);
    // 다른 언어로 번역된 브래킷: 첫 브래킷 뒤에 □ 구조가 있으면 분리점으로 사용 (□는 언어 무관)
    if (bodyMatch == null) {
      final anyBracket = RegExp(r'\[[^\]]{1,25}\]').firstMatch(cleaned);
      if (anyBracket != null && cleaned.substring(anyBracket.end).contains('□')) {
        bodyMatch = anyBracket;
      }
    }
    if (bodyMatch == null) {
      return _buildSectionContent(cleaned.replaceAll(RegExp(r'\n{2,}'), '\n'));
    }

    // 매칭된 브래킷 텍스트를 기본 섹션 제목으로 (번역된 언어 유지)
    final bodyTitle = cleaned.substring(bodyMatch.start + 1, bodyMatch.end - 1).trim();
    final header = cleaned.substring(0, bodyMatch.start).trim();
    var body = cleaned.substring(bodyMatch.end).trim();
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
      // □ 없으면 담당업무(번역 제목) 하나로
      if (body.isNotEmpty) {
        sections.add(_DescSection(title: bodyTitle, content: body));
      }
    } else {
      // □ 첫 번째 전 텍스트 → 담당업무(번역 제목)
      final before = body.substring(0, sectionMatches.first.start).trim();
      if (before.isNotEmpty) {
        sections.add(_DescSection(title: bodyTitle, content: before));
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

    // 헤더 블록 제거 (첫 번째 [ 이전의 key:value 블록) — GT가 전각 【 로 바꾸는 케이스 포함
    final firstBracket = RegExp(r'[\[【]').firstMatch(cleaned);
    if (firstBracket != null && firstBracket.start > 0) {
      cleaned = cleaned.substring(firstBracket.start).trim();
    }

    if (cleaned.isEmpty) return null;

    // [섹션] / 【섹션】 파싱
    final pattern = RegExp(r'[\[【]([^\]】]*)[\]】]');
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
    // 이미지 제거 ![alt](url) + 불완전 이미지 태그
    s = s.replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '');
    s = s.replaceAll(RegExp(r'!\['), '');
    // 이스케이프 해제
    s = s.replaceAllMapped(RegExp(r'\\([,\-\(\)\.\+\*\_\>\!\|\#])'), (m) => m.group(1)!);
    // 헤더 마커 제거 (텍스트 유지, 앞 공백 포함)
    s = s.replaceAllMapped(RegExp(r'^\s*#{1,6}\s*', multiLine: true), (m) => '');
    // 볼드/이탤릭 마커 제거 (***bold italic***, **bold**, *italic*)
    s = s.replaceAllMapped(RegExp(r'\*{1,3}([^\*]+)\*{1,3}'), (m) => m.group(1)!);
    // 잔여 연속 * 제거
    s = s.replaceAll(RegExp(r'\*{2,}'), '');
    // 수평선 제거
    s = s.replaceAll(RegExp(r'^[\*\-]{3,}\s*$', multiLine: true), '');
    // Markdown 테이블 구분선 제거 (| ---- | ---- |)
    s = s.replaceAll(RegExp(r'^\s*\|[\s\-:]+\|\s*$', multiLine: true), '');
    // Markdown 테이블 데이터 줄 → 파이프 제거 (| cell | cell | → cell  cell)
    s = s.replaceAllMapped(RegExp(r'^\s*\|(.+)\|\s*$', multiLine: true), (m) {
      return m.group(1)!.replaceAll('|', '  ').trim();
    });
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
    // 번호 헤더는 콜론 포함 줄(1. 근무지 : 이천) 및 25자 초과 제외 — key:value/본문 줄이 삼켜지는 유실 방지
    final headerPattern = RegExp(
      r'(?:^|\n)\s*(?:'
      r'(◈)\s*(.+)'          // ◈ 마커
      r'|'
      r'(✅|💼|🎁|📌|🏠|🚀|🛎️|📋|📝|⭐)\s*(.+)'  // 이모지 마커
      r'|'
      r'(※)\s*(.+)'          // ※ 마커
      r'|'
      r'(▶)\s*(.+)'          // ▶ 마커
      r'|'
      r'(\d+)\.\s*([^:：\n]{1,25})'  // 번호 마커 (콜론 없는 짧은 제목만)
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

      // 내용이 없어도 제목은 유지 (※ 안내문 등 헤더 자체가 정보인 경우 유실 방지)
      if (content.isNotEmpty || title.isNotEmpty) {
        sections.add(_DescSection(title: title, content: content));
      }
    }

    if (sections.isEmpty) return null;
    return _buildSections(sections);
  }

  /// K-HIRE 파싱 (알바천국 템플릿 / key:value / 자유형)
  Widget? _parseKHire(String text) {
    // 알바천국 워터마크(다국어 변형) + 하단 안내 문구 제거
    var cleaned = _stripAlbaGarbage(text);
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
    if (meaningful.isEmpty || _isApplyOnly(meaningful)) {
      return const SizedBox.shrink();
    }

    // 알바천국 템플릿: 채용정보/근무조건/접수내용 섹션 (독립된 줄에서만 매칭)
    // 한국어 + 15개 언어 번역 헤더
    final albaSections = [
      // 채용정보
      '채용정보', 'Recruitment information', '招聘信息', 'Thông tin tuyển dụng',
      'ข้อมูลการรับสมัคร', 'भर्ती की जानकारी', 'බඳවා ගැනීමේ තොරතුරු',
      'စုဆောင်းရေးအချက်အလက်', 'ព័ត៌មានជ្រើសរើសបុគ្គលិក', 'নিয়োগের তথ্য',
      'भर्ती जानकारी', 'Ажилд авах мэдээлэл', '採用情報',
      'Информация о наборе персонала', 'Informasi perekrutan',
      'බඳවා ගැනීම් පිළිබඳ තොරතුරු', 'សហការ បដិវត្តន៍ គោលនយោបាយ',
      "Ishga qabul qilish haqida ma'lumot", "Ishga qabul qilish ma'lumotlari",
      // 근무조건
      '근무조건', 'working conditions', 'Working conditions', '工作条件',
      'điều kiện làm việc', 'สภาพการทำงาน', 'काम करने की स्थिति',
      'සේවා කොන්දේසි', 'အလုပ်အခြေအနေများ', 'លក្ខខណ្ឌការងារ',
      'কাজের অবস্থা', 'काम गर्ने अवस्था', 'ажлын нөхцөл',
      '労働条件', 'условия труда', 'kondisi kerja',
      'လုပ်ငန်းခွင်အခြေအနေများ', 'Ish sharoitlari',
      // 접수내용 및 문의
      '접수내용 및 문의', 'Application details and inquiries', '申请详情及查询',
      'Chi tiết ứng dụng và yêu cầu', 'รายละเอียดการสมัครและสอบถามข้อมูล',
      'आवेदन विवरण और पूछताछ', 'අයදුම්පත් විස්තර සහ විමසීම්',
      'ព័ត៌មានលម្អិតនៃការដាក់ពាក្យ និងការសាកសួរ', 'আবেদন বিবরণ এবং অনুসন্ধান',
      'आवेदन विवरण र सोधपुछ', 'Өргөдлийн дэлгэрэнгүй мэдээлэл, лавлагаа',
      '受付内容およびお問い合わせ', 'Детали заявки и вопросы', 'Detail aplikasi dan pertanyaan',
      'Nội dung tiếp nhận và thắc mắc', 'လျှောက်လွှာအသေးစိတ်နှင့် စုံစမ်းမေးမြန်းမှုများ',
      "Ariza tafsilotlari va so'rovlar",
      // 접수내용
      '접수내용', 'Application details', '申请详情',
      'Chi tiết ứng dụng', 'รายละเอียดการสมัคร',
      'आवेदन विवरण', 'අයදුම්පත් විස්තර',
      'လျှောက်လွှာအသေးစိတ်', 'ព័ត៌មានលម្អិតអំពីកម្មវិធី',
      'আবেদন বিবরণ', 'Өргөдлийн дэлгэрэнгүй',
      '受付内容', 'Детали приложения', 'Detail aplikasi',
    ];
    // 긴 키워드 먼저 매칭 (접수내용 및 문의 > 접수내용)
    albaSections.sort((a, b) => b.length.compareTo(a.length));
    final pattern = RegExp('(?:^|\\n)\\s*(${albaSections.map((s) => RegExp.escape(s)).join('|')})\\s*(?=\\n|\$)', multiLine: true, caseSensitive: false);
    final matches = pattern.allMatches(cleaned).toList();
    final hasAlbaFormat = matches.isNotEmpty;

    if (hasAlbaFormat) {
      final sections = <_DescSection>[];
      final hasKorean = RegExp(r'[\uAC00-\uD7AF]').hasMatch(cleaned);

      // 섹션 헤더 전 텍스트 (매장명/제목 등)
      if (matches.isNotEmpty) {
        final before = cleaned.substring(0, matches.first.start).trim();
        if (before.isNotEmpty) {
          final beforeCleaned = before.replaceAll(RegExp(r'\n{2,}'), '\n');
          sections.add(_DescSection(title: '', content: beforeCleaned));
        }
      }

      for (int i = 0; i < matches.length; i++) {
        final title = _normalizeAlbaTitle(matches[i].group(1)!, isKorean: hasKorean);
        final start = matches[i].end;
        final end = i + 1 < matches.length ? matches[i + 1].start : cleaned.length;
        var content = cleaned.substring(start, end).trim();
        content = content.replaceAll(RegExp(r'\n{2,}'), '\n');
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
      final grouped = _groupKvIntoSections(cleaned);
      if (grouped != null) return _buildSections(grouped);
      return _buildKeyValueText(cleaned);
    }

    // 자유형: 클린업된 텍스트로 표시 (원문 raw 폴백 시 워터마크/CSS 재노출 방지)
    final plain = _stripMdText(cleaned).replaceAll(RegExp(r'\n{2,}'), '\n').trim();
    if (plain.isEmpty) return const SizedBox.shrink();
    return SelectableText(
      plain,
      style: const TextStyle(fontSize: 14, color: AppColors.gray500, height: 1.8),
    );
  }

  /// 번역된 알바천국 섹션 헤더를 정규화 (한국어/비한글 구분)
  static String _normalizeAlbaTitle(String title, {bool isKorean = true}) {
    final t = title.trim().toLowerCase();
    // 채용정보 계열
    if (t == '채용정보' || t.contains('recruitment') || t.contains('招聘') ||
        t.contains('tuyển dụng') || t.contains('รับสมัคร') || t.contains('भर्ती') ||
        t.contains('බඳවා') || t.contains('စုဆောင်း') || t.contains('ជ្រើសរើស') ||
        t.contains('নিয়োগ') || t.contains('採用') || t.contains('набор') ||
        t.contains('perekrutan') || t.contains('авах')) {
      return isKorean ? '채용정보' : title.trim();
    }
    // 근무조건 계열
    if (t == '근무조건' || t.contains('working condition') || t.contains('工作条件') ||
        t.contains('điều kiện làm việc') || t.contains('สภาพการทำงาน') ||
        t.contains('काम करने') || t.contains('සේවා කොන්දේසි') ||
        t.contains('အလုပ်အခြေအနေ') || t.contains('លក្ខខណ្ឌការងារ') ||
        t.contains('কাজের অবস্থা') || t.contains('काम गर्ने') ||
        t.contains('нөхцөл') || t.contains('労働条件') ||
        t.contains('условия труда') || t.contains('kondisi kerja')) {
      return isKorean ? '근무조건' : title.trim();
    }
    // 접수내용 및 문의 계열
    if (t == '접수내용 및 문의' || t == '접수내용' ||
        t.contains('application detail') || t.contains('申请详情') ||
        t.contains('ứng dụng') || t.contains('การสมัคร') ||
        t.contains('आवेदन विवरण') || t.contains('අයදුම්පත්') ||
        t.contains('លម្អិត') || t.contains('আবেদন') ||
        t.contains('Өргөдлийн') || t.contains('受付') ||
        t.contains('заявк') || t.contains('aplikasi')) {
      return isKorean ? '접수내용' : title.trim();
    }
    return title.trim();
  }

  // 접두 기호 제거 패턴
  static final _prefixRe = RegExp(r'^[-·•■◈●◇◦▪◎※＊▶★☆▷→►◆□▣▲△]\s*');

  /// 줄에서 접두 기호 제거 후 key 추출
  static String _stripPrefix(String line) => line.replaceFirst(_prefixRe, '');

  /// key:value를 채용정보/근무조건/기타 섹션으로 그룹핑
  List<_DescSection>? _groupKvIntoSections(String text) {
    const recruitKeys = {
      // 한국어
      '모집마감', '학력', '모집인원', '우대조건', '기타조건',
      '성별', '경력', '나이', '연령', '지원자격', '자격요건',
      '접수방법', '담당자', '담당자명',
      // 영어
      'Recruitment deadline', 'deadline', 'Education', 'Educational background',
      'Number of recruits', 'Number of people recruited', 'Preferential conditions',
      'Preferences', 'Other conditions', 'Gender', 'Experience', 'Age',
      'Qualifications', 'Qualifications for application', 'Eligibility',
      'How to apply', 'Contact', 'contact information', 'Manager',
      // 중국어
      '招聘截止日期', '学历', '招聘人数', '招募人数', '优先条件', '其他条件',
      '性别', '经验', '年龄', '申请资格', '如何申请', '联系方式',
      // 일본어
      '募集締め切り', '学歴', '募集人数', '優遇事項', '応募資格', '支援方法', '連絡先',
    };
    const workKeys = {
      // 한국어
      '근무기간', '근무요일', '근무시간', '고용형태', '복리후생', '급여',
      '시급', '월급', '담당업무', '업무',
      // 영어
      'Working period', 'Period of work', 'Working days', 'Working hours',
      'Work hours', 'Employment type', 'Welfare benefits', 'Benefits',
      'Welfare and benefits', 'Salary', 'Hourly wage', 'Monthly salary',
      'Work details', 'Duties',
      // 중국어
      '工作期限', '工作天数', '工作时间', '就业类型', '用工类型', '福利待遇', '工资', '薪资',
      // 일본어
      '勤務期間', '勤務曜日', '勤務時間', '雇用形態', '福利厚生', '給与', '時給', '月給',
    };
    const etcKeys = {
      // 한국어
      '모집직종', '모집부문', '모집분야', '태그',
      // 영어
      'Recruitment type', 'Job type', 'Tag', 'Tags',
      // 중국어
      '招聘类型', '标签',
      // 일본어
      '募集職種', 'タグ',
    };

    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final recruit = <String>[];
    final work = <String>[];
    final etc = <String>[];
    final rest = <String>[];

    // 대소문자 무시 매칭용 lowercase 셋
    final recruitLower = recruitKeys.map((k) => k.toLowerCase()).toSet();
    final workLower = workKeys.map((k) => k.toLowerCase()).toSet();
    final etcLower = etcKeys.map((k) => k.toLowerCase()).toSet();

    for (final line in lines) {
      final stripped = _stripPrefix(line.trim());
      final m = RegExp('(^.+?)[:：៖]\\s*').firstMatch(stripped);
      final key = m?.group(1)?.trim().toLowerCase() ?? '';
      if (recruitLower.contains(key)) {
        recruit.add(line.trim());
      } else if (workLower.contains(key)) {
        work.add(line.trim());
      } else if (etcLower.contains(key)) {
        etc.add(line.trim());
      } else {
        rest.add(line.trim());
      }
    }

    // 최소 2개 섹션에 데이터가 있어야 그룹핑 의미 있음
    final filled = [recruit, work, etc].where((s) => s.isNotEmpty).length;
    if (filled < 2) return null;

    final isKorean = RegExp(r'[\uAC00-\uD7AF]').hasMatch(text);
    final sections = <_DescSection>[];
    if (recruit.isNotEmpty) {
      sections.add(_DescSection(title: isKorean ? '채용정보' : 'Recruitment Info', content: recruit.join('\n')));
    }
    if (work.isNotEmpty) {
      sections.add(_DescSection(title: isKorean ? '근무조건' : 'Working Conditions', content: work.join('\n')));
    }
    if (etc.isNotEmpty) {
      sections.add(_DescSection(title: isKorean ? '기타' : 'Others', content: etc.join('\n')));
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
  /// "지원하기" 또는 그 번역만 반복되는 텍스트인지 판별
  static bool _isApplyOnly(String text) {
    const applyWords = {
      '지원하기', 'apply', 'áp dụng', '申请', 'นำมาใช้',
      'आवेदन करना', 'අයදුම් කරන්න', 'လျှောက်ထားပါ။', 'អនុវត្ត',
      'আবেদন করুন', 'आवेदन दिनुहोस्', 'өргөдөл гаргах', 'murojaat qiling',
      'サポートする', 'применять', 'menerapkan',
    };
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    return words.every((w) => w.isEmpty || applyWords.any((a) => a == w || w.contains(a)));
  }

  static bool _isCssLine(String line) {
    if (RegExp(r'[\uAC00-\uD7AF]').hasMatch(line)) return false;
    if (line.contains('{') && (line.contains(';') || line.contains('}'))) return true;
    if (line.startsWith('/*') || line.startsWith('@font-face') || line.startsWith('@media')) return true;
    if (RegExp(r'^\.[a-zA-Z_].*\{').hasMatch(line)) return true;
    return false;
  }

  /// \uD45C\uC2DC\uC6A9 Markdown \uB9C8\uCEE4 \uC81C\uAC70 (\uC904 \uB2E8\uC704) \u2014 **\uBCFC\uB4DC**, \uC904 \uC120\uB450 # \uD5E4\uB354, \uC794\uC5EC **, \uACE0\uC544 # \uC904
  static String _stripMdLine(String line) {
    var s = line.replaceAllMapped(RegExp(r'\*{1,3}([^*]+)\*{1,3}'), (m) => m.group(1)!);
    s = s.replaceFirst(RegExp(r'^#{1,6}\s+'), '');
    s = s.replaceFirst(RegExp(r'^#{1,6}\s*$'), '');
    return s.replaceAll(RegExp(r'\*{2,}'), '');
  }

  /// \uD45C\uC2DC\uC6A9 Markdown \uB9C8\uCEE4 \uC81C\uAC70 (\uD14D\uC2A4\uD2B8 \uC804\uCCB4)
  static String _stripMdText(String text) =>
      text.split('\n').map(_stripMdLine).join('\n');

  Widget _buildSectionContent(String content) {
    final lines = content.split('\n');
    final rows = <InlineSpan>[]; // 한 줄 단위
    for (int i = 0; i < lines.length; i++) {
      final line = _stripMdLine(lines[i].trim()).trim();
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
        final cleanValue = value.replaceFirst(RegExp(r'^[·\*:：]\s*'), '');
        if (cleanValue.isEmpty) {
          // 값 없는 라벨: 다음 줄에 불릿 값이 오는 서브헤더면 볼드 표시, 아니면 숨김 (빈 필드)
          final p = prefix.trim();
          String next = '';
          for (int j = i + 1; j < lines.length; j++) {
            final t = lines[j].trim();
            if (t.isNotEmpty) { next = t; break; }
          }
          // 다음 줄이 불릿(①-⑳ 포함)이거나 key:value면 그룹핑 서브헤더로 판단
          final nextIsBullet = RegExp(r'^[ㆍ·•\-–—◦○▪*①-⑳❶-❿]').hasMatch(next) ||
              RegExp(r'^[^:：]{1,20}[:：]').hasMatch(next);
          if (p == '◦' || p == '○' || nextIsBullet) {
            rows.add(TextSpan(
              text: '$prefix$key',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.black, height: 2.0),
            ));
          }
          continue;
        }
        // "직종 1 : 생산직" 같은 번호+콜론 값은 원줄 그대로 (이중 콜론 방지)
        // 시간 값(05:30)은 제외 — 콜론 앞 공백이 있는 경우만
        if (RegExp(r'^\d+\s+[:：]').hasMatch(cleanValue)) {
          rows.add(TextSpan(
            text: line,
            style: const TextStyle(fontSize: 14, color: AppColors.gray500, height: 1.8),
          ));
          continue;
        }
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

  /// 벼룩시장(FindJob) 파서: 상단 key:value 블록 + [상세요강] 등 브래킷 섹션 구조.
  /// - 상단 kv(근무요일/모집분야/주요업무/가능조건/지원가능비자 등 100~46%)는 제목 없는 첫 섹션으로
  ///   → _buildSectionContent가 콜론 기반으로 key 볼드 처리 (언어 무관 = 번역문도 동일 작동)
  /// - `[상세요강]` 단독 줄(번역 시 [Detailed description]·【…】 변형 포함)은 섹션 제목으로 승격
  /// - ＊헤더는 4%뿐이고 비정형이라 구조화하지 않음 (본문 그대로)
  List<_DescSection>? _parseFindJob(String text) {
    final lines = text.split('\n');
    // 브래킷 단독 줄 = 섹션 경계 (GT가 [를 【로 바꾸는 케이스 포함)
    final bracketRe = RegExp(r'^\s*[\[【]\s*([^\]】]{1,40})\s*[\]】]\s*$');
    final sections = <_DescSection>[];
    var currentTitle = '';
    var buf = <String>[];
    void flush() {
      final content = buf.join('\n').trim();
      // 내용 없는 제목도 유지 — 연속 브래킷(가게명·모집 포지션명 나열)이 유실되지 않게.
      if (content.isNotEmpty || currentTitle.isNotEmpty) {
        sections.add(_DescSection(title: currentTitle, content: content));
      }
      buf = [];
    }

    for (final line in lines) {
      final m = bracketRe.firstMatch(line);
      if (m != null) {
        flush();
        currentTitle = m.group(1)!.trim();
      } else {
        buf.add(line);
      }
    }
    flush();

    if (sections.isEmpty) return null; // 내용 없음 → 자유형 폴백
    return sections;
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    margin: const EdgeInsets.only(right: 8, top: 2),
                    decoration: BoxDecoration(
                      color: AppColors.carrot,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // 번역된 긴 제목 오버플로우 방지 — 줄바꿈 허용
                  Expanded(
                    child: Text(
                      section.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
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
