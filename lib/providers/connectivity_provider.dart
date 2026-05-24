import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 네트워크 연결 상태 프로바이더 (실시간 스트림)
final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();

  final controller = StreamController<bool>();

  // 초기 상태 확인
  connectivity.checkConnectivity().then((results) {
    controller.add(!results.contains(ConnectivityResult.none));
  });

  // 변경 감지
  final sub = connectivity.onConnectivityChanged.listen((results) {
    controller.add(!results.contains(ConnectivityResult.none));
  });

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});

/// 현재 온라인 여부 (동기적 접근용)
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).valueOrNull ?? true;
});
