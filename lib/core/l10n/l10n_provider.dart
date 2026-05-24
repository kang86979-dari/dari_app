import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/language_provider.dart';
import 'app_strings.dart';

final stringsProvider = Provider<AppStrings>((ref) {
  final langCode = ref.watch(languageProvider);
  return AppStrings.of(langCode);
});
