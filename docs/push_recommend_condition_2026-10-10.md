# 추천 공고 푸시(19시) — 발송 보류 요청 (2026-10-10, 최종)

기존 핸드오프(push_handoff_crawler_2026-10-09.md) §2의 **19시 추천 공고 푸시를
당분간 발송하지 말아 달라** (크론 배치 비활성 또는 미구현 유지).

## 이유
- 조건(필터/키워드) 없는 사용자에게 임의 공고가 나가는 문제 확인(2026-10-10 19시 발송분 실수신)
- 앱 2.1.6에서 **추천 공고 설정 토글도 제거**함 — 사용자가 끌 방법이 없는 상태로
  발송되면 안 됨

## 유지되는 것 (변경 없음)
- 9시/15시 기본 조건 건수 푸시
- 9시/15시 키워드 조건 건수 푸시 (search_keyword 기반, 신규)
- push_subscriptions.recommend_enabled 컬럼은 그대로 둠 (추후 재도입용)

## 재도입 시 조건 (참고)
재개하게 되면 대상은:
```
enabled=true AND recommend_enabled=true
AND (filter_state IS NOT NULL OR search_keyword IS NOT NULL)
```
