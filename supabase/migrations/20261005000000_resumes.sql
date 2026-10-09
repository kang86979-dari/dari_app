-- 이력서 (사용자당·사이트당 1개). 2026-10-05.
-- Dari가 이력서 원본(source of truth). canonical 포맷을 data(jsonb)에 저장 →
-- 주입 시에만 사이트별 코드/필드로 매핑(한 번 입력 → 전 사이트 재사용).
-- site: 대상 사이트 식별('khire' 등). 이력서는 사이트별로 따로 관리.
create table if not exists public.resumes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  site text not null default 'khire',
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, site)
);

alter table public.resumes enable row level security;

create policy "own resume select" on public.resumes
  for select using (auth.uid() = user_id);
create policy "own resume insert" on public.resumes
  for insert with check (auth.uid() = user_id);
create policy "own resume update" on public.resumes
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own resume delete" on public.resumes
  for delete using (auth.uid() = user_id);

-- set_updated_at()은 applicant_profiles 마이그레이션에서 생성됨
create trigger resumes_updated_at
  before update on public.resumes
  for each row execute function public.set_updated_at();
