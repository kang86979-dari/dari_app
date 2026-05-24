CREATE OR REPLACE FUNCTION public.get_jobs_page(
  p_lang text DEFAULT 'ko'::text,
  p_limit integer DEFAULT 20,
  p_offset integer DEFAULT 0,
  p_sort_by text DEFAULT 'latest'::text,
  p_visa_ids uuid[] DEFAULT NULL::uuid[],
  p_benefit_ids uuid[] DEFAULT NULL::uuid[],
  p_language_ids integer[] DEFAULT NULL::integer[],
  p_region_ids integer[] DEFAULT NULL::integer[],
  p_category_ids uuid[] DEFAULT NULL::uuid[],
  p_employment_ids uuid[] DEFAULT NULL::uuid[],
  p_korean_level_ids integer[] DEFAULT NULL::integer[],
  p_schedule_ids integer[] DEFAULT NULL::integer[],
  p_salary_types text[] DEFAULT NULL::text[],
  p_gender text DEFAULT NULL::text,
  p_education text DEFAULT NULL::text,
  p_experience text DEFAULT NULL::text,
  p_visa_sponsorship boolean DEFAULT NULL::boolean,
  p_site_ids uuid[] DEFAULT NULL::uuid[],
  p_country_ids uuid[] DEFAULT NULL::uuid[]
)
 RETURNS TABLE(job_data jsonb)
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  edu_order TEXT[] := ARRAY['none','middle_school','high_school','college','bachelor','master','doctor'];
  exp_order TEXT[] := ARRAY['none','newcomer','1y','3y','5y','10y'];
  edu_idx INT; exp_idx INT; allowed_edu TEXT[]; allowed_exp TEXT[];
  any_visa_id UUID;
  any_country_id UUID;
BEGIN
  IF p_education IS NOT NULL THEN edu_idx := array_position(edu_order, p_education);
    IF edu_idx IS NOT NULL THEN allowed_edu := edu_order[1:edu_idx]; END IF; END IF;
  IF p_experience IS NOT NULL THEN exp_idx := array_position(exp_order, p_experience);
    IF exp_idx IS NOT NULL THEN allowed_exp := exp_order[1:exp_idx]; END IF; END IF;

  SELECT id INTO any_visa_id FROM visa_master WHERE code = 'ANY';
  SELECT id INTO any_country_id FROM countries WHERE code = 'ANY';

  RETURN QUERY
  SELECT
    (jsonb_build_object(
      'id', j.id, 'site_id', j.site_id, 'title', j.title, 'company', j.company,
      'location', j.location, 'salary', j.salary, 'salary_type', j.salary_type,
      'salary_amount', j.salary_amount, 'job_type', j.job_type, 'description', j.description,
      'url', j.url, 'address_detail', j.address_detail, 'work_days', j.work_days,
      'work_time', j.work_time, 'posted_at', j.posted_at, 'expires_at', j.expires_at,
      'crawled_at', j.crawled_at, 'region_id', j.region_id, 'job_category_id', j.job_category_id,
      'employment_type_id', j.employment_type_id, 'work_schedule_id', j.work_schedule_id,
      'korean_level_id', j.korean_level_id, 'visa_sponsorship', j.visa_sponsorship,
      'gender', j.gender, 'education', j.education, 'experience', j.experience,
      'duplicate_group_id', j.duplicate_group_id, 'housing_provided', j.housing_provided,
      'driving_license', j.driving_license,
      'title_translated', CASE WHEN p_lang = 'ko' THEN NULL
        ELSE COALESCE(j.title_translations->>p_lang, j.title_translations->>'en') END,
      'title_en', j.title_translations->>'en',
      'address_translated', CASE WHEN p_lang = 'ko' THEN NULL
        ELSE COALESCE(j.address_translations->>p_lang, j.address_translations->>'en') END,
      'address_en', j.address_translations->>'en',
      'work_time_translated', CASE WHEN p_lang = 'ko' THEN NULL
        ELSE j.work_time_translations->>p_lang END,
      'description_translated', CASE WHEN p_lang = 'ko' THEN NULL
        ELSE COALESCE(j.description_translations->>p_lang, j.description_translations->>'en') END
    ))::jsonb AS job_data
  FROM jobs j
  WHERE j.is_active = true AND j.is_duplicate = false
    AND (j.expires_at IS NULL OR j.expires_at >= CURRENT_DATE)
    AND (p_visa_ids IS NULL OR j.id IN (
      SELECT jv.job_id FROM job_visas jv
      WHERE jv.visa_id = ANY(p_visa_ids) OR jv.visa_id = any_visa_id))
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
    AND (p_site_ids IS NULL OR j.site_id = ANY(p_site_ids))
  ORDER BY
    CASE WHEN p_sort_by = 'salary_desc' THEN j.salary_amount END DESC NULLS LAST,
    (
      CASE WHEN p_visa_ids IS NOT NULL AND EXISTS (
        SELECT 1 FROM job_visas jv WHERE jv.job_id = j.id AND jv.visa_id = ANY(p_visa_ids)
      ) THEN 1 ELSE 0 END
      +
      CASE WHEN p_country_ids IS NOT NULL AND EXISTS (
        SELECT 1 FROM job_countries jc WHERE jc.job_id = j.id AND jc.country_id = ANY(p_country_ids)
      ) THEN 1 ELSE 0 END
    ) DESC,
    j.posted_at DESC NULLS LAST, j.crawled_at DESC
  LIMIT p_limit OFFSET p_offset;
END; $function$;
