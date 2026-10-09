import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../data/services/address_service.dart';
import '../../../providers/account_provider.dart';
import '../../../providers/language_provider.dart';
import 'daum_postcode_screen.dart';

/// 주소 입력 화면 (이력서/간편지원 공용).
/// GPS 현재위치 역지오코딩 ① + 다음(카카오) 우편번호 검색 ② 둘 다 제공 →
/// 우편번호(zipcd)+도로명(addr1)+상세(addr2)를 applicant_profiles에 저장.
/// 저장된 값은 전 사이트 주입에 재사용(한 번 입력 → 재사용).
class AddressInputScreen extends ConsumerStatefulWidget {
  const AddressInputScreen({super.key});

  /// 저장 성공 시 true 반환.
  static Future<bool?> show(BuildContext context) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddressInputScreen()),
    );
  }

  @override
  ConsumerState<AddressInputScreen> createState() => _AddressInputScreenState();
}

class _AddressInputScreenState extends ConsumerState<AddressInputScreen> {
  String _zipcd = '';
  String _road = '';
  final _detailCtrl = TextEditingController();
  bool _gpsLoading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(accountProvider).profile;
    _zipcd = p?.addrZipcd ?? '';
    _road = p?.addrRoad ?? '';
    _detailCtrl.text = p?.addrDetail ?? '';
  }

  @override
  void dispose() {
    _detailCtrl.dispose();
    super.dispose();
  }

  bool get _hasAddress => _zipcd.isNotEmpty || _road.isNotEmpty;

  Future<void> _useGps() async {
    final s = AppStrings.of(ref.read(languageProvider));
    setState(() => _gpsLoading = true);
    try {
      final addr = await AddressService.currentAddress();
      if (!mounted) return;
      if (addr.isEmpty) {
        _toast(s.addressErrorNotFound);
      } else {
        setState(() {
          _zipcd = addr.zipcd;
          _road = addr.road;
        });
      }
    } on AddressException catch (e) {
      if (!mounted) return;
      switch (e.error) {
        case AddressError.serviceOff:
          _toast(s.addressErrorService);
        case AddressError.denied:
        case AddressError.deniedForever:
          _toast(s.addressErrorDenied);
        case AddressError.notFound:
          _toast(s.addressErrorNotFound);
      }
    } catch (_) {
      if (mounted) _toast(s.addressErrorNotFound);
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  Future<void> _useSearch() async {
    final lang = ref.read(languageProvider);
    final result = await DaumPostcodeScreen.show(context, lang);
    if (result != null && mounted) {
      setState(() {
        _zipcd = result.zipcd;
        _road = result.road;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(accountProvider.notifier).saveSmsFields(
            addrZipcd: _zipcd,
            addrRoad: _road,
            addrDetail: _detailCtrl.text.trim(),
          );
      // saveSmsFields는 비로그인/프로필 미로드 시 조용히 no-op — 저장된 척
      // pop하지 않도록 반영 여부를 확인한다(침묵 실패 방지).
      final saved =
          ref.read(accountProvider).profile?.addrZipcd == _zipcd &&
              ref.read(accountProvider).profile?.addrRoad == _road;
      if (!mounted) return;
      if (saved) {
        Navigator.of(context).pop(true);
      } else {
        final s = AppStrings.of(ref.read(languageProvider));
        _toast(s.accountSaveFailed);
      }
    } catch (_) {
      if (mounted) {
        final s = AppStrings.of(ref.read(languageProvider));
        _toast(s.accountSaveFailed);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(ref.watch(languageProvider));
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
          s.addressTitle,
          style: const TextStyle(
            color: AppColors.black,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  // 입력 버튼 2종
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.my_location,
                          label: s.addressGpsButton,
                          loading: _gpsLoading,
                          onTap: _gpsLoading ? null : _useGps,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.search,
                          label: s.addressSearchButton,
                          onTap: _useSearch,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_hasAddress) ...[
                    _AddressCard(zipcd: _zipcd, road: _road, zipLabel: s.addressZipLabel),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _detailCtrl,
                      decoration: InputDecoration(
                        hintText: s.addressDetailHint,
                        hintStyle: const TextStyle(color: AppColors.gray300),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.gray100),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.carrot),
                        ),
                      ),
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(
                        s.addressEmptyHint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.gray400, fontSize: 14, height: 1.5),
                      ),
                    ),
                ],
              ),
            ),
            // 저장
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: (!_hasAddress || _saving) ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.carrot,
                    disabledBackgroundColor: AppColors.gray200,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          s.addressSave,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    this.loading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.carrotLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.carrot),
              )
            else
              Icon(icon, size: 18, color: AppColors.carrot),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.carrotDark,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final String zipcd;
  final String road;
  final String zipLabel;
  const _AddressCard(
      {required this.zipcd, required this.road, required this.zipLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (zipcd.isNotEmpty)
            Row(
              children: [
                Icon(Icons.markunread_mailbox_outlined,
                    size: 15, color: AppColors.gray400),
                const SizedBox(width: 6),
                Text(
                  '$zipLabel  $zipcd',
                  style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          if (zipcd.isNotEmpty && road.isNotEmpty) const SizedBox(height: 8),
          if (road.isNotEmpty)
            Text(
              road,
              style: const TextStyle(
                  color: AppColors.gray900,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.4),
            ),
        ],
      ),
    );
  }
}
