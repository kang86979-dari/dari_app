-- 우편번호 기반 주소 (이력서/간편지원 주입용). 2026-10-05.
-- 기존 addr_sido/addr_sigungu/addr_dong(문자지원 select 매칭용)과 별개:
-- K-HIRE Daum 우편번호 필드(zipcd/addr1/addr2)에 그대로 주입하기 위한 값.
--   addr_zipcd  = 우편번호 (#zipcd)
--   addr_road   = 도로명/지번 주소, 동까지 (#addr1)
--   addr_detail = 상세주소 (#addr2)
alter table public.applicant_profiles
  add column if not exists addr_zipcd  text,
  add column if not exists addr_road   text,
  add column if not exists addr_detail text;
