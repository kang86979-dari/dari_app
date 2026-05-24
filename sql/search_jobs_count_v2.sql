CREATE OR REPLACE FUNCTION public.search_jobs_count(
  search_query text,
  lang_code text DEFAULT 'ko'::text
)
 RETURNS integer
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE total INT;
BEGIN
  SELECT COUNT(*) INTO total
  FROM jobs j
  WHERE j.is_active = true AND j.is_duplicate = false AND j.is_translated = true
    AND (j.expires_at IS NULL OR j.expires_at >= CURRENT_DATE)
    AND j.search_text ILIKE '%' || search_query || '%';
  RETURN total;
END; $function$;
