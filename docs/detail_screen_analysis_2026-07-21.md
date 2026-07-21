# 상세화면 전체 재분석 (2026-07-21)

앱 파서(`job_detail_screen.dart` 미커밋 버전)를 1:1 복제한 분류기로
실제 DB 데이터를 전수/샘플 분석한 결과.

- 분석 대상: 활성+번역 공고 15,891건 (전수 카운트) + 사이트별 샘플 2,166건 (ko) + en 번역 보유분 920건
- 분석 도구: scratchpad/analyze.py (Dart 파서 로직 Python 복제)

## 1. 최대 이슈 — description 번역 커버리지 (크롤러 이슈)

**활성 공고 15,891건 중 13,049건(82%)이 `description_translations` NULL.**
번역이 있는 18%도 사실상 **en 하나만** 존재 (300건 샘플 중 en 274, id 13, si 6, mn 6, zh/ja/vi 등 0).
title_translations는 15개 언어 전부 있는 것과 대조적.

→ 외국인 사용자 대부분이 상세내용을 **한국어 원문**으로 보고 있음 (en 폴백도 없음).

| 사이트 | 활성 공고 | desc 번역 NULL | en 보유율 |
|--------|---------:|---------------:|----------:|
| K-HIRE | 10,107 | 9,717 | 4% |
| KoMate | 1,868 | 1,621 | 13% |
| TalentLink | 1,454 | 259 | 82% |
| K-Work | 784 | 510 | 35% |
| WorkVisa | 613 | 80 | 87% |
| WorkOn | 415 | 357 | 14% |
| Kowork | 384 | 322 | 16% |
| Jobploy | 266 | 183 | 31% |

특이사항:
- TalentLink 2026-05-17 크롤링분 1,576건은 NULL이 아닌 **빈 객체 `{}`**
- 최신 크롤링(7월)도 매일 ~95%가 NULL → 지연이 아니라 파이프라인이 desc를 번역 안 함
- **zh/ja desc 번역은 0건** → 이번에 추가한 zh/ja 섹션 헤더 매칭은 현재 실행될 일 없음 (미래 대비용으로는 유효)

## 2. 파서 렌더링 경로 분석 — ko 원문 (사이트별 샘플 250~400건)

| 사이트 | 구조화 | KV볼드 | plaintext | 빈화면 | 가비지 잔존 |
|--------|-------:|-------:|----------:|-------:|------------:|
| K-HIRE (400) | 83% (ALBA 67%+KV그룹 16%) | 5% | 12.5% | 0 | MD 9건 |
| Jobploy (266) | 100% | — | 0 | 0 | MD 5건 |
| TalentLink (250) | 100% | — | 0 | 0 | MD 6건 |
| WorkOn (250) | 99% | — | 1% | 0 | MD 3건 |
| Kowork (250) | 99.6% | — | 0.4% | 0 | MD 6건 |
| K-Work (250) | 92% | 8% | 0 | 0 | MD 1건 |
| KoMate (250) | 78% | — | **22% (원문 raw)** | 0 | CSS줄 2건+MD 4건 |
| WorkVisa (250) | 21% | 77% | — | 2% | 0 |

- **CSS 잔존 0건** — keyframe 정규식 수정 효과 확인 (기존 11건 이슈 해결)
- KoMate 22% raw는 가비지 없는 일반 텍스트 (klik JSON 가비지 현재 데이터에 0건) — 구조만 없는 상태

## 3. en 번역 뷰 분석 (번역 보유분 920건)

| 사이트 | 구조화 | 문제 |
|--------|-------:|------|
| K-HIRE (188) | 90% | **워터마크 "DESIGNED BY Alba Heaven" 55% (104건) 노출** |
| WorkVisa (200) | 41%+KV 58% | EMPTY 1 |
| TalentLink (123) | 100% | MD 1건 |
| KoMate (200) | 82.5% | raw 17.5% |
| Kowork/Jobploy/WorkOn/K-Work | 100% | MD 소수 |

→ 이번 다국어 헤더 추가 작업으로 en 뷰 구조화율은 높음 (K-HIRE ALBA en 헤더 매칭 정상 동작 확인).

## 4. 앱에서 수정 가능한 버그 (우선순위순)

1. **[K-HIRE] en 워터마크 미제거** (en 보유분의 55%)
   - 원인: `RegExp(r'DESIGNED BY 알바천국\s*')` — 한국어만 매칭
   - 수정: `RegExp(r'DESIGNED BY (알바천국|Alba Heaven)\s*', caseSensitive: false)`
   - 적용 위치 3곳: `_parseKHire`, `_isEmpty`, `_hasSectionFormat`
2. **[공통] Markdown 마커 잔존** (`**볼드**`, `# 헤더` — 사이트당 1~3%)
   - 크롤러가 markdown 흔적이 있는 원문을 저장, `_cleanMarkdown`은 WorkVisa 전용
   - 수정: 볼드/헤더 마커 제거를 공통 전처리로 (K-HIRE/Kowork/Jobploy/KoMate/TalentLink)
3. **[KoMate] 파서 실패 시 원문 raw 폴백** (22%)
   - `_parseKoMate` null 반환 시 클린업 안 된 원문이 그대로 노출됨
   - 현재 데이터는 깨끗하지만 klik JSON 가비지 유입 시 그대로 노출될 위험
   - 수정: null 반환 대신 클린업된 텍스트로 plaintext 렌더링
4. (경미) K-HIRE en 전화안내문 잔존 1/188건

## 5. 크롤러 전달 필요

- **description 번역 파이프라인 확인**: 82% NULL, 번역돼도 en뿐 → 의도된 것인지(비용 절감), 버그인지 확인 필요
- TalentLink 5/17 크롤링분 1,576건 `{}` 정리
- zh/ja 등 다국어 desc 번역이 추가되면 앱 파서는 이미 대응됨 (이번 작업)
