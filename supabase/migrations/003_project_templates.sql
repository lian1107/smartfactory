-- 003_project_templates.sql
-- Project templates that bundle phase_templates together

CREATE TABLE IF NOT EXISTS public.project_templates (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  description   TEXT,
  phase_ids     UUID[] NOT NULL DEFAULT '{}',   -- ordered list of phase_template IDs
  is_default    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE TRIGGER trg_project_templates_updated_at
  BEFORE UPDATE ON public.project_templates
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

ALTER TABLE public.project_templates ENABLE ROW LEVEL SECURITY;
