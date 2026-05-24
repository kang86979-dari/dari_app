CREATE OR REPLACE FUNCTION public.search_jobs_fuzzy(
  search_query text,
  result_limit integer DEFAULT 20,
  result_offset integer DEFAULT 0,
  sort_by text DEFAULT 'relevance'::text,
  lang_code text DEFAULT 'ko'::text
)
 RETURNS TABLE(job_data jsonb, similarity_score real)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
  IF sort_by = 'latest' THEN
    RETURN QUERY
    SELECT to_jsonb(j.*), 0.0::float4
    FROM jobs j
    WHERE j.is_active = true
      AND j.is_translated = true
      AND (j.expires_at IS NULL OR j.expires_at >= CURRENT_DATE)
      AND j.search_text ILIKE '%' || search_query || '%'
    ORDER BY j.crawled_at DESC
    LIMIT result_limit OFFSET result_offset;

  ELSIF sort_by = 'salary_desc' THEN
    RETURN QUERY
    SELECT to_jsonb(j.*), 0.0::float4
    FROM jobs j
    WHERE j.is_active = true
      AND j.is_translated = true
      AND (j.expires_at IS NULL OR j.expires_at >= CURRENT_DATE)
      AND j.search_text ILIKE '%' || search_query || '%'
    ORDER BY j.salary_amount DESC NULLS LAST, j.crawled_at DESC
    LIMIT result_limit OFFSET result_offset;

  ELSE
    RETURN QUERY
    SELECT to_jsonb(j.*),
      similarity(j.search_text, search_query)::float4 AS score
    FROM jobs j
    WHERE j.is_active = true
      AND j.is_translated = true
      AND (j.expires_at IS NULL OR j.expires_at >= CURRENT_DATE)
      AND j.search_text ILIKE '%' || search_query || '%'
    ORDER BY
      similarity(j.search_text, search_query) DESC,
      j.crawled_at DESC
    LIMIT result_limit OFFSET result_offset;
  END IF;
END;
$function$;
