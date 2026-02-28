-- 005_projects_and_phases.sql
-- Projects represent production orders; phases are kanban columns

CREATE TABLE IF NOT EXISTS public.projects (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title               TEXT NOT NULL,
  description         TEXT,
  product_id          UUID REFERENCES public.products(id) ON DELETE SET NULL,
  template_id         UUID REFERENCES public.project_templates(id) ON DELETE SET NULL,
  status              TEXT NOT NULL DEFAULT 'active'
                        CHECK (status IN ('active','on_hold','completed','cancelled')),
  health              TEXT NOT NULL DEFAULT 'green'
                        CHECK (health IN ('green','yellow','red')),
  planned_start_date  DATE,
  planned_end_date    DATE,
  actual_start_date   DATE,
  actual_end_date     DATE,
  owner_id            UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  quantity            INT NOT NULL DEFAULT 1,
  priority            INT NOT NULL DEFAULT 3
                        CHECK (priority BETWEEN 1 AND 5),
  created_by          UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_projects_status     ON public.projects(status);
CREATE INDEX IF NOT EXISTS idx_projects_owner      ON public.projects(owner_id);
CREATE INDEX IF NOT EXISTS idx_projects_product    ON public.projects(product_id);
CREATE INDEX IF NOT EXISTS idx_projects_health     ON public.projects(health);
CREATE INDEX IF NOT EXISTS idx_projects_created_at ON public.projects(created_at DESC);

CREATE OR REPLACE TRIGGER trg_projects_updated_at
  BEFORE UPDATE ON public.projects
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Project phases (kanban columns, instantiated from phase_templates)
CREATE TABLE IF NOT EXISTS public.project_phases (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id      UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  template_id     UUID REFERENCES public.phase_templates(id) ON DELETE SET NULL,
  name            TEXT NOT NULL,
  description     TEXT,
  order_index     INT  NOT NULL DEFAULT 0,
  color           TEXT NOT NULL DEFAULT '#6B7280',
  is_completed    BOOLEAN NOT NULL DEFAULT FALSE,
  completed_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_project_phases_project ON public.project_phases(project_id);

CREATE OR REPLACE TRIGGER trg_project_phases_updated_at
  BEFORE UPDATE ON public.project_phases
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

ALTER TABLE public.projects       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_phases ENABLE ROW LEVEL SECURITY;
