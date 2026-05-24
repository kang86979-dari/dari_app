import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../core/l10n/l10n_provider.dart';
import '../../providers/language_provider.dart';
import '../../data/services/analytics_service.dart';

class LanguageSelectScreen extends ConsumerWidget {
  const LanguageSelectScreen({super.key});

  static bool _tracked = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLang = ref.watch(languageProvider);
    final s = ref.watch(stringsProvider);
    final languagesAsync = ref.watch(supportedLanguagesProvider);

    if (!_tracked) {
      _tracked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        analytics.screenView('language_select');
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await SystemNavigator.pop();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
                child: Text(
                  s.selectLanguage,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ),
              Expanded(
                child: languagesAsync.when(
                  data: (languages) => ListView.builder(
                    itemCount: languages.length,
                    itemBuilder: (context, index) {
                      final lang = languages[index];
                      final isSelected = lang.code == selectedLang;
                      return GestureDetector(
                        onTap: () => ref
                            .read(languageProvider.notifier)
                            .setLanguage(lang.code),
                        child: Container(
                          color: isSelected
                              ? AppColors.carrotLight
                              : Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lang.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.black,
                                ),
                              ),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppColors.carrot
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.carrot
                                        : const Color(0xFFDDDDDD),
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Center(
                                        child: CircleAvatar(
                                          radius: 4,
                                          backgroundColor: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) =>
                      const Center(child: CircularProgressIndicator()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () async {
                      analytics.languageSelected(selectedLang);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('language', selectedLang);
                      if (context.mounted) {
                        context.push('/onboarding/visa');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      decoration: BoxDecoration(
                        color: AppColors.carrot,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        s.next,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
