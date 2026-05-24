import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/l10n_provider.dart';
import '../constants/colors.dart';

/// 에러 발생 시 안내 문구 + 다시 시도 버튼 (Retry 누르면 스피너 표시)
class ErrorRetry extends ConsumerStatefulWidget {
  final VoidCallback? onRetry;

  const ErrorRetry({super.key, this.onRetry});

  @override
  ConsumerState<ErrorRetry> createState() => _ErrorRetryState();
}

class _ErrorRetryState extends ConsumerState<ErrorRetry> {
  bool _isRetrying = false;

  void _handleRetry() {
    if (_isRetrying || widget.onRetry == null) return;
    setState(() => _isRetrying = true);
    widget.onRetry!();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isRetrying) ...[
              const SizedBox(
                width: 32, height: 32,
                child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.carrot),
              ),
              const SizedBox(height: 16),
              Text(
                s.loading,
                style: const TextStyle(fontSize: 14, color: AppColors.gray400),
              ),
            ] else ...[
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.gray300,
              ),
              const SizedBox(height: 16),
              Text(
                s.somethingWentWrong,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                s.noInternet,
                style: const TextStyle(fontSize: 14, color: AppColors.gray400),
                textAlign: TextAlign.center,
              ),
              if (widget.onRetry != null) ...[
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _handleRetry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.carrot,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      s.retry,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
