import 'package:flutter/material.dart';

/// GoRouter의 루트 네비게이터 키.
/// 화면이 pop된 뒤(예: 뒤로가기로 회원가입 이탈) 어느 화면 위에서든
/// 안전하게 팝업을 다시 띄우기 위해 전역으로 노출.
final rootNavigatorKey = GlobalKey<NavigatorState>();
