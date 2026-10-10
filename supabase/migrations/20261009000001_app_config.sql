-- 앱 전역 설정(크롤러가 관리, 앱은 읽기 전용). 2026-10-09.
-- 푸시 발송 시각을 서버에서 받아 설정 화면에 동적 표시 — 시간이 바뀌면
-- 앱 배포 없이 반영. 발송 자체는 크롤러 주관(값도 크롤러가 갱신).
create table if not exists public.app_config (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);
alter table public.app_config enable row level security;
create policy "app_config read" on public.app_config for select using (true);

insert into public.app_config(key, value) values
  ('push_new_times', '["09:00","15:00"]'::jsonb),        -- 신규 공고 알림(배열)
  ('push_recommend_time', '"19:00"'::jsonb)              -- 추천 공고 알림(단일)
on conflict (key) do nothing;
