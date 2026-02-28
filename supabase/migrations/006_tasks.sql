-- 006_tasks.sql
-- Tasks belong to project_phases (kanban cards)

CREATE TABLE IF NOT EXISTS public.tasks (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id      UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  phase_id        UUID NOT NULL REFERENCES public.project_phases(id) ON DELETE CASCADE,
  title           TEXT NOT NULL,
  description     TEXT,
  assignee_id     UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  priority        TEXT NOT NULL DEFAULT 'medium'
                    CHECK (priority IN ('low','medium','high','urgent')),
  status          TEXT NOT NULL DEFAULT 'todo'
                    CHECK (status IN ('todo','in_progress','done','blocked')),
  due_date        DATE,
  started_at      TIMESTAMPTZ,
  completed_at    TIMESTAMPTZ,
  estimated_hours NUMERIC(6,2),
  actual_hours    NUMERIC(6,2),
  tags            TEXT[] NOT NULL DEFAULT '{}',
  order_index     INT  NOT NULL DEFAULT 0,
  created_by      UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tasks_project    ON public.tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_tasks_phase      ON public.tasks(phase_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assignee   ON public.tasks(assignee_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status     ON public.tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date   ON public.tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_tasks_priority   ON public.tasks(priority);

CREATE OR REPLACE TRIGGER trg_tasks_updated_at
  BEFORE UPDATE ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Task comments
CREATE TABLE IF NOT EXISTS public.task_comments (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id     UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  author_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content     TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_task_comments_task ON public.task_comments(task_id);

CREATE OR REPLACE TRIGGER trg_task_comments_updated_at
  BEFORE UPDATE ON public.task_comments
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

ALTER TABLE public.tasks         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_comments ENABLE ROW LEVEL SECURITY;
