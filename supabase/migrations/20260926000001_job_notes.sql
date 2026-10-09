-- 공고 메모 (사용자당·공고당 1개). 2026-09-26.
-- 로그인 전용. 메모 저장 시 앱에서 즐겨찾기 자동 추가(로컬).
create table if not exists public.job_notes (
  user_id uuid not null references auth.users (id) on delete cascade,
  job_id uuid not null references public.jobs (id) on delete cascade,
  note text not null check (char_length(note) <= 500),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, job_id)
);

alter table public.job_notes enable row level security;

create policy "own note select" on public.job_notes
  for select using (auth.uid() = user_id);
create policy "own note insert" on public.job_notes
  for insert with check (auth.uid() = user_id);
create policy "own note update" on public.job_notes
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own note delete" on public.job_notes
  for delete using (auth.uid() = user_id);

-- set_updated_at()은 applicant_profiles 마이그레이션에서 생성됨
create trigger job_notes_updated_at
  before update on public.job_notes
  for each row execute function public.set_updated_at();
