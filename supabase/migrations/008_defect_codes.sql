-- 008_defect_codes.sql
-- Defect / non-conformance codes for QC

CREATE TABLE IF NOT EXISTS public.defect_codes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code        TEXT NOT NULL UNIQUE,
  name        TEXT NOT NULL,
  description TEXT,
  category    TEXT NOT NULL DEFAULT 'general'
                CHECK (category IN ('appearance','dimension','function','material','process','other','general')),
  severity    TEXT NOT NULL DEFAULT 'minor'
                CHECK (severity IN ('minor','major','critical')),
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_defect_codes_category ON public.defect_codes(category);
CREATE INDEX IF NOT EXISTS idx_defect_codes_severity ON public.defect_codes(severity);

CREATE OR REPLACE TRIGGER trg_defect_codes_updated_at
  BEFORE UPDATE ON public.defect_codes
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

ALTER TABLE public.defect_codes ENABLE ROW LEVEL SECURITY;
