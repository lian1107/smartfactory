-- 002_phase_templates.sql
-- Reusable phase building blocks for project templates

CREATE TABLE IF NOT EXISTS public.phase_templates (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  description   TEXT,
  default_order INT  NOT NULL DEFAULT 0,
  color         TEXT NOT NULL DEFAULT '#6B7280',   -- hex color for kanban column
  icon          TEXT,                               -- material icon name
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE TRIGGER trg_phase_templates_updated_at
  BEFORE UPDATE ON public.phase_templates
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

ALTER TABLE public.phase_templates ENABLE ROW LEVEL SECURITY;
