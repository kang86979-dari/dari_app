-- 지원자 프로필 (SNS 로그인 사용자 1:1). 2026-09-24 프로필 서버 저장 전환.
-- birth_date는 앱 입력 형식(YYYYMMDD 8자리 문자열) 그대로 저장.
create table if not exists public.applicant_profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  sns_provider text not null default '',
  email text not null,
  name text not null,
  birth_date text not null,
  gender text not null check (gender in ('male', 'female')),
  nationality_code text not null,
  nationality_label text not null,
  visa_code text not null,
  visa_label text not null,
  phone text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.applicant_profiles enable row level security;

-- 본인 행만 접근 가능 (anon 차단, authenticated는 자기 것만)
create policy "own profile select" on public.applicant_profiles
  for select using (auth.uid() = user_id);
create policy "own profile insert" on public.applicant_profiles
  for insert with check (auth.uid() = user_id);
create policy "own profile update" on public.applicant_profiles
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own profile delete" on public.applicant_profiles
  for delete using (auth.uid() = user_id);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

create trigger applicant_profiles_updated_at
  before update on public.applicant_profiles
  for each row execute function public.set_updated_at();
