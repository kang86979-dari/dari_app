-- 지원 기록 + 즐겨찾기 서버화 + 마감 공고 정리 cron (2026-09-26).
-- 참고: 홈 목록 RPC(get_jobs_page)가 이미 expires_at/is_active를 걸러서
-- 마감 공고는 목록에서 자동 비노출 — 여기서는 6개월 지난 것만 실삭제.

-- 1) 지원 기록: 방법별 1행(같은 방법 재지원도 별도 행 = 이력).
--    공고 실삭제 시 job_id는 null로 남고 스냅샷으로 목록 유지.
create table if not exists public.applied_jobs (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  job_id uuid references public.jobs (id) on delete set null,
  method text not null,
  applied_at timestamptz not null default now(),
  seen_at timestamptz, -- null = 미확인(N 뱃지), 지원내역 화면 이탈 시 일괄 기록
  -- 스냅샷
  title text not null default '',
  company text not null default '',
  site_name text not null default '',
  location text not null default ''
);

create index if not exists applied_jobs_user_idx
  on public.applied_jobs (user_id, applied_at desc);

alter table public.applied_jobs enable row level security;
create policy "own applied select" on public.applied_jobs
  for select using (auth.uid() = user_id);
create policy "own applied insert" on public.applied_jobs
  for insert with check (auth.uid() = user_id);
create policy "own applied update" on public.applied_jobs
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own applied delete" on public.applied_jobs
  for delete using (auth.uid() = user_id);

-- 2) 즐겨찾기 (로그인 사용자 서버 저장, 비로그인은 앱 로컬 유지)
create table if not exists public.favorites (
  user_id uuid not null references auth.users (id) on delete cascade,
  job_id uuid not null references public.jobs (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, job_id)
);

alter table public.favorites enable row level security;
create policy "own favorite select" on public.favorites
  for select using (auth.uid() = user_id);
create policy "own favorite insert" on public.favorites
  for insert with check (auth.uid() = user_id);
create policy "own favorite delete" on public.favorites
  for delete using (auth.uid() = user_id);

-- 3) 마감 6개월 지난 공고 실삭제 (매일 KST 03:00 = UTC 18:00).
--    favorites/job_notes는 cascade 삭제, applied_jobs는 스냅샷 유지(set null).
create extension if not exists pg_cron;
select cron.schedule(
  'purge-expired-jobs',
  '0 18 * * *',
  $$ delete from public.jobs
     where expires_at is not null
       and expires_at < now() - interval '6 months' $$
);
