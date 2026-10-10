import 'package:flutter/material.dart';
import 'sheet_handle.dart';

/// 앱 공통 바텀시트 — 모든 하단 시트의 껍데기 통일(2026-10-10).
/// 라운드 20·흰 배경·상단 SheetHandle(드래그 바 + X)·하단 SafeArea를
/// 한 곳에서 관리한다. 내용(child)만 넘기면 됨.
///
/// [title] 주면 핸들 아래 굵은 제목 행을 그린다(정렬/언어 등 선택 시트용).
/// [isScrollControlled] 입력폼(키보드)·긴 목록이면 true.
/// [showHandle] false면 핸들 숨김(전용 레이아웃이 자체 헤더를 가질 때).
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required Widget child,
  String? title,
  bool isScrollControlled = false,
  bool showHandle = true,
  Color barrierColor = const Color(0x8A000000),
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: isScrollControlled,
    barrierColor: barrierColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showHandle)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 12, 0),
                child: SheetHandle(),
              ),
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17171C),
                    ),
                  ),
                ),
              ),
            Flexible(child: child),
          ],
        ),
      ),
    ),
  );
}
