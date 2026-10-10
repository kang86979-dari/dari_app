-- 인기 검색어 집계용 적재 테이블 (2026-10-10)
-- 앱이 검색 실행 시 fire-and-forget insert. 클라이언트는 조회 불가(insert-only RLS).
CREATE TABLE IF NOT EXISTS search_logs (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  keyword text NOT NULL,
  lang_code text,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE search_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY search_logs_insert ON search_logs
  FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE INDEX IF NOT EXISTS idx_search_logs_created ON search_logs (created_at);
CREATE INDEX IF NOT EXISTS idx_search_logs_keyword ON search_logs (keyword);

-- 집계 예시:
-- SELECT keyword, COUNT(*) FROM search_logs
-- WHERE created_at > now() - interval '30 days'
-- GROUP BY keyword ORDER BY count DESC LIMIT 50;
