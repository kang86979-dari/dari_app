# 추천 공고 푸시(19시) 발송 조건 변경 요청 (2026-10-10)

기존 핸드오프(push_handoff_crawler_2026-10-09.md) §2의 추천 푸시 대상 조건을 변경한다.

## 변경 내용

**변경 전**:
```
enabled=true AND recommend_enabled=true
(※ "당일 미진입" 조건은 이미 제거 합의됨)
```

**변경 후 (A안 확정)**:
```
enabled=true AND recommend_enabled=true
AND (filter_state IS NOT NULL OR search_keyword IS NOT NULL)
```

## 이유
필터도 키워드도 없는 사용자에겐 "추천"의 근거가 없어 임의 공고가 나감 —
실사용자 수신 확인(2026-10-10 19시 발송분). 스팸으로 느껴질 수 있어
**조건(필터 또는 키워드)이 있는 사용자에게만 발송**으로 좁힌다.

## 참고
- 추천 공고 선택 로직(조건에 맞는 상세 공고 1건)은 기존 스펙 그대로
- 9시/15시 기본·키워드 푸시는 변경 없음
- app_config(push_recommend_time) 변경 없음
