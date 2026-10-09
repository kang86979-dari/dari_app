-- 문자 지원(K-HIRE TalkApply)용 프로필 확장. 2026-10-04.
-- 비자 발급/만료일 + 주소 3단계. TalkApply 폼이 요구하는 just-in-time 수집값을 프로필에 영속.
alter table public.applicant_profiles
  add column if not exists visa_issued_at date,
  add column if not exists visa_expires_at date,
  add column if not exists visa_no_expiry boolean not null default false,
  add column if not exists addr_sido text,
  add column if not exists addr_sigungu text,
  add column if not exists addr_dong text,
  -- 문자 지원 문구(칩 설정) — 기기 간 유지 위해 서버 저장(2026-10-05)
  add column if not exists sms_compose jsonb;
