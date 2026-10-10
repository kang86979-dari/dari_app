-- 영문 검색어 어간 매칭 (welding→weld) — fuzzy_v2/count_v2 (2026-10-10)
-- 어간은 원단어의 접두사라 결과는 늘기만 함(상위집합). 비영문 미적용.

CREATE OR REPLACE FUNCTION public.search_jobs_fuzzy_v2(search_query text, result_limit integer DEFAULT 20, result_offset integer DEFAULT 0, sort_by text DEFAULT 'relevance'::text, lang_code text DEFAULT 'ko'::text, include_testing boolean DEFAULT false, app_build integer DEFAULT NULL::integer, p_visa_ids uuid[] DEFAULT NULL::uuid[], p_benefit_ids uuid[] DEFAULT NULL::uuid[], p_language_ids bigint[] DEFAULT NULL::bigint[], p_region_ids bigint[] DEFAULT NULL::bigint[], p_category_ids uuid[] DEFAULT NULL::uuid[], p_employment_ids uuid[] DEFAULT NULL::uuid[], p_korean_level_ids bigint[] DEFAULT NULL::bigint[], p_schedule_ids bigint[] DEFAULT NULL::bigint[], p_salary_types text[] DEFAULT NULL::text[], p_gender text DEFAULT NULL::text, p_education text DEFAULT NULL::text, p_experience text DEFAULT NULL::text, p_visa_sponsorship boolean DEFAULT NULL::boolean, p_site_ids uuid[] DEFAULT NULL::uuid[], p_country_ids uuid[] DEFAULT NULL::uuid[])
 RETURNS TABLE(job_data jsonb, similarity_score real)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  -- 공백 분리 → 모든 단어 포함(AND, 순서 무관) — v1(★056)과 동일.
  -- 영문 단어는 흔한 어미(-ing/-ers/-er/-ed/-s)를 뗀 어간으로 매칭(2026-10-10).
  -- 어간은 원단어의 접두사라 '%어간%'은 '%원단어%'의 상위집합 — 결과 감소 없음.
  -- 조건: 영문만·6자 이상·어간 4자 이상일 때만 적용(sing→s 같은 오작동 방지).
  v_pats TEXT[] := ARRAY(
    SELECT '%' || CASE
      WHEN w ~ '^[A-Za-z]+$' AND length(w) >= 6
           AND length(regexp_replace(w, '(ing|ers|er|ed|s)$', '')) >= 4
        THEN regexp_replace(w, '(ing|ers|er|ed|s)$', '')
      ELSE w END || '%'
    FROM regexp_split_to_table(btrim(search_query), '\s+') AS w WHERE w <> '');
  -- 필터 보조 — get_jobs_page와 동일(★049/051, 학력·경력 "이하 포함").
  edu_order TEXT[] := ARRAY['none','middle_school','high_school','college','bachelor','master','doctor'];
  exp_order TEXT[] := ARRAY['none','newcomer','1y','3y','5y','10y'];
  edu_idx INT; exp_idx INT; allowed_edu TEXT[]; allowed_exp TEXT[];
  any_visa_id UUID;
  include_any BOOLEAN := false;
  any_country_id UUID;
BEGIN
  IF p_education IS NOT NULL THEN edu_idx := array_position(edu_order, p_education);
    IF edu_idx IS NOT NULL THEN allowed_edu := edu_order[1:edu_idx]; END IF; END IF;
  IF p_experience IS NOT NULL THEN exp_idx := array_position(exp_order, p_experience);
    IF exp_idx IS NOT NULL THEN allowed_exp := exp_order[1:exp_idx]; END IF; END IF;

  SELECT id INTO any_visa_id FROM visa_master WHERE code = 'ANY';
  IF p_visa_ids IS NOT NULL THEN
    SELECT EXISTS (SELECT 1 FROM visa_master vm WHERE vm.id = ANY(p_visa_ids) AND vm.any_applicable)
      INTO include_any;
    IF COALESCE(p_visa_sponsorship, false) THEN include_any := true; END IF;
  END IF;
  SELECT id INTO any_country_id FROM countries WHERE code = 'ANY';

  RETURN QUERY
  SELECT to_jsonb(j.*),
    GREATEST(
      similarity(COALESCE(j.title, ''), search_query),
      similarity(COALESCE(j.company, ''), search_query),
      similarity(COALESCE(j.title_translations->>'en', ''), search_query),
      similarity(COALESCE(j.title_translations->>'ko', ''), search_query),
      similarity(COALESCE(j.title_translations->>lang_code, ''), search_query)
    )::float4 AS score
  FROM jobs j
  WHERE j.is_active = true
    AND j.is_translated = true
    AND (include_testing OR j.site_id IN (
      SELECT s.id FROM sites s WHERE s.status = 'live'
        AND (s.min_app_build IS NULL OR s.min_app_build <= COALESCE(app_build, 0))))
    AND (j.expires_at IS NULL OR j.expires_at >= CURRENT_DATE)
    AND (
      j.search_text ILIKE ALL(v_pats)
      OR (j.search_text || ' ' || COALESCE(j.title_translations->>lang_code, '')) ILIKE ALL(v_pats)
    )
    -- ── 필터 (get_jobs_page와 동일) ──
    AND (p_visa_ids IS NULL OR j.id IN (
      SELECT jv.job_id FROM job_visas jv
      WHERE jv.visa_id = ANY(p_visa_ids) OR (include_any AND jv.visa_id = any_visa_id)))
    AND (p_benefit_ids IS NULL OR j.id IN (
      SELECT jb.job_id FROM job_benefits jb WHERE jb.benefit_id = ANY(p_benefit_ids)))
    AND (p_language_ids IS NULL OR j.id IN (
      SELECT jl.job_id FROM job_languages jl WHERE jl.language_id = ANY(p_language_ids)))
    AND (p_country_ids IS NULL OR j.id IN (
      SELECT jc.job_id FROM job_countries jc
      WHERE jc.country_id = ANY(p_country_ids) OR jc.country_id = any_country_id))
    AND (p_region_ids IS NULL OR j.region_id = ANY(p_region_ids))
    AND (p_category_ids IS NULL OR j.job_category_id = ANY(p_category_ids))
    AND (p_employment_ids IS NULL OR j.employment_type_id = ANY(p_employment_ids))
    AND (p_korean_level_ids IS NULL OR j.korean_level_id = ANY(p_korean_level_ids))
    AND (p_schedule_ids IS NULL OR j.work_schedule_id = ANY(p_schedule_ids))
    AND (p_salary_types IS NULL OR j.salary_type = ANY(p_salary_types))
    AND (p_visa_sponsorship IS NULL OR j.visa_sponsorship = p_visa_sponsorship)
    AND (p_gender IS NULL OR j.gender IS NULL OR j.gender = 'any' OR j.gender = p_gender)
    AND (p_education IS NULL OR j.education IS NULL OR j.education = ANY(allowed_edu))
    AND (p_experience IS NULL OR j.experience IS NULL OR j.experience = ANY(allowed_exp))
    AND (p_site_ids IS NULL OR j.site_id = ANY(p_site_ids)
         OR (include_testing AND j.site_id IN (SELECT s.id FROM sites s WHERE s.status = 'testing')))
  ORDER BY
    CASE WHEN sort_by = 'salary_desc' THEN j.salary_amount END DESC NULLS LAST,
    CASE WHEN sort_by NOT IN ('latest', 'salary_desc') THEN
      GREATEST(
        similarity(COALESCE(j.title, ''), search_query),
        similarity(COALESCE(j.company, ''), search_query),
        similarity(COALESCE(j.title_translations->>'en', ''), search_query),
        similarity(COALESCE(j.title_translations->>'ko', ''), search_query),
        similarity(COALESCE(j.title_translations->>lang_code, ''), search_query)
      ) END DESC NULLS LAST,
    j.crawled_at DESC
  LIMIT result_limit OFFSET result_offset;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.search_jobs_count_v2(search_query text, lang_code text DEFAULT 'ko'::text, include_testing boolean DEFAULT false, app_build integer DEFAULT NULL::integer, p_visa_ids uuid[] DEFAULT NULL::uuid[], p_benefit_ids uuid[] DEFAULT NULL::uuid[], p_language_ids bigint[] DEFAULT NULL::bigint[], p_region_ids bigint[] DEFAULT NULL::bigint[], p_category_ids uuid[] DEFAULT NULL::uuid[], p_employment_ids uuid[] DEFAULT NULL::uuid[], p_korean_level_ids bigint[] DEFAULT NULL::bigint[], p_schedule_ids bigint[] DEFAULT NULL::bigint[], p_salary_types text[] DEFAULT NULL::text[], p_gender text DEFAULT NULL::text, p_education text DEFAULT NULL::text, p_experience text DEFAULT NULL::text, p_visa_sponsorship boolean DEFAULT NULL::boolean, p_site_ids uuid[] DEFAULT NULL::uuid[], p_country_ids uuid[] DEFAULT NULL::uuid[])
 RETURNS integer
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  -- 영문 단어는 흔한 어미(-ing/-ers/-er/-ed/-s)를 뗀 어간으로 매칭(2026-10-10).
  -- 어간은 원단어의 접두사라 '%어간%'은 '%원단어%'의 상위집합 — 결과 감소 없음.
  -- 조건: 영문만·6자 이상·어간 4자 이상일 때만 적용(sing→s 같은 오작동 방지).
  v_pats TEXT[] := ARRAY(
    SELECT '%' || CASE
      WHEN w ~ '^[A-Za-z]+$' AND length(w) >= 6
           AND length(regexp_replace(w, '(ing|ers|er|ed|s)$', '')) >= 4
        THEN regexp_replace(w, '(ing|ers|er|ed|s)$', '')
      ELSE w END || '%'
    FROM regexp_split_to_table(btrim(search_query), '\s+') AS w WHERE w <> '');
  edu_order TEXT[] := ARRAY['none','middle_school','high_school','college','bachelor','master','doctor'];
  exp_order TEXT[] := ARRAY['none','newcomer','1y','3y','5y','10y'];
  edu_idx INT; exp_idx INT; allowed_edu TEXT[]; allowed_exp TEXT[];
  any_visa_id UUID;
  include_any BOOLEAN := false;
  any_country_id UUID;
  result_count INTEGER;
BEGIN
  IF p_education IS NOT NULL THEN edu_idx := array_position(edu_order, p_education);
    IF edu_idx IS NOT NULL THEN allowed_edu := edu_order[1:edu_idx]; END IF; END IF;
  IF p_experience IS NOT NULL THEN exp_idx := array_position(exp_order, p_experience);
    IF exp_idx IS NOT NULL THEN allowed_exp := exp_order[1:exp_idx]; END IF; END IF;

  SELECT id INTO any_visa_id FROM visa_master WHERE code = 'ANY';
  IF p_visa_ids IS NOT NULL THEN
    SELECT EXISTS (SELECT 1 FROM visa_master vm WHERE vm.id = ANY(p_visa_ids) AND vm.any_applicable)
      INTO include_any;
    IF COALESCE(p_visa_sponsorship, false) THEN include_any := true; END IF;
  END IF;
  SELECT id INTO any_country_id FROM countries WHERE code = 'ANY';

  SELECT COUNT(*) INTO result_count
  FROM jobs j
  WHERE j.is_active = true
    AND j.is_translated = true
    AND (include_testing OR j.site_id IN (
      SELECT s.id FROM sites s WHERE s.status = 'live'
        AND (s.min_app_build IS NULL OR s.min_app_build <= COALESCE(app_build, 0))))
    AND (j.expires_at IS NULL OR j.expires_at >= CURRENT_DATE)
    AND (
      j.search_text ILIKE ALL(v_pats)
      OR (j.search_text || ' ' || COALESCE(j.title_translations->>lang_code, '')) ILIKE ALL(v_pats)
    )
    AND (p_visa_ids IS NULL OR j.id IN (
      SELECT jv.job_id FROM job_visas jv
      WHERE jv.visa_id = ANY(p_visa_ids) OR (include_any AND jv.visa_id = any_visa_id)))
    AND (p_benefit_ids IS NULL OR j.id IN (
      SELECT jb.job_id FROM job_benefits jb WHERE jb.benefit_id = ANY(p_benefit_ids)))
    AND (p_language_ids IS NULL OR j.id IN (
      SELECT jl.job_id FROM job_languages jl WHERE jl.language_id = ANY(p_language_ids)))
    AND (p_country_ids IS NULL OR j.id IN (
      SELECT jc.job_id FROM job_countries jc
      WHERE jc.country_id = ANY(p_country_ids) OR jc.country_id = any_country_id))
    AND (p_region_ids IS NULL OR j.region_id = ANY(p_region_ids))
    AND (p_category_ids IS NULL OR j.job_category_id = ANY(p_category_ids))
    AND (p_employment_ids IS NULL OR j.employment_type_id = ANY(p_employment_ids))
    AND (p_korean_level_ids IS NULL OR j.korean_level_id = ANY(p_korean_level_ids))
    AND (p_schedule_ids IS NULL OR j.work_schedule_id = ANY(p_schedule_ids))
    AND (p_salary_types IS NULL OR j.salary_type = ANY(p_salary_types))
    AND (p_visa_sponsorship IS NULL OR j.visa_sponsorship = p_visa_sponsorship)
    AND (p_gender IS NULL OR j.gender IS NULL OR j.gender = 'any' OR j.gender = p_gender)
    AND (p_education IS NULL OR j.education IS NULL OR j.education = ANY(allowed_edu))
    AND (p_experience IS NULL OR j.experience IS NULL OR j.experience = ANY(allowed_exp))
    AND (p_site_ids IS NULL OR j.site_id = ANY(p_site_ids)
         OR (include_testing AND j.site_id IN (SELECT s.id FROM sites s WHERE s.status = 'testing')));
  RETURN result_count;
END;
$function$
;
