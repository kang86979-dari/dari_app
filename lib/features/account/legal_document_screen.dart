import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import 'widgets/account_app_bar.dart';

/// 약관 상세보기 (초안). 실제 법무 검토된 최종본이 아님 — 상단에 항상 안내 배너 표시.
Future<void> showLegalDocument(
  BuildContext context, {
  required String title,
  required String body,
  required String draftNotice,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _LegalDocumentScreen(
        title: title,
        body: body,
        draftNotice: draftNotice,
      ),
    ),
  );
}

class _LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String body;
  final String draftNotice;

  const _LegalDocumentScreen({
    required this.title,
    required this.body,
    required this.draftNotice,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AccountAppBar(title: title),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.carrotLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      draftNotice,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray600,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.black,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
