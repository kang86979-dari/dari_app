import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/connectivity_provider.dart';
import '../l10n/l10n_provider.dart';
import '../constants/colors.dart';

/// 오프라인 시 화면 상단에 표시되는 배너
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final s = ref.watch(stringsProvider);

    if (isOnline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: AppColors.gray200,
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 16, color: AppColors.gray500),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              s.noInternet,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.gray500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
