-- 007_activity_logs.sql
-- Activity logs, change requests, document links

CREATE TABLE IF NOT EXISTS public.activity_logs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type     TEXT NOT NULL CHECK (entity_type IN ('project','task','product','phase')),
  entity_id       UUID NOT NULL,
  action          TEXT NOT NULL,   -- e.g. 'created','updated','status_changed','assigned'
  actor_id        UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  old_value       JSONB,
  new_value       JSONB,
  metadata        JSONB DEFAULT '{}',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_activity_logs_entity ON public.activity_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_actor  ON public.activity_logs(actor_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_time   ON public.activity_logs(created_at DESC);

-- Change requests (ECN/ECO)
CREATE TABLE IF NOT EXISTS public.change_requests (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id      UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  title           TEXT NOT NULL,
  description     TEXT,
  requester_id    UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  status          TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending','approved','rejected','implemented')),
  priority        TEXT NOT NULL DEFAULT 'medium'
                    CHECK (priority IN ('low','medium','high','urgent')),
  resolved_by     UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  resolved_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_change_requests_project ON public.change_requests(project_id);
CREATE INDEX IF NOT EXISTS idx_change_requests_status  ON public.change_requests(status);

CREATE OR REPLACE TRIGGER trg_change_requests_updated_at
  BEFORE UPDATE ON public.change_requests
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Document links (URLs to Google Drive, Confluence, etc.)
CREATE TABLE IF NOT EXISTS public.document_links (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type     TEXT NOT NULL CHECK (entity_type IN ('project','task','product')),
  entity_id       UUID NOT NULL,
  title           TEXT NOT NULL,
  url             TEXT NOT NULL,
  doc_type        TEXT NOT NULL DEFAULT 'other'
                    CHECK (doc_type IN ('spec','drawing','report','checklist','other')),
  uploaded_by     UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_document_links_entity ON public.document_links(entity_type, entity_id);

ALTER TABLE public.activity_logs   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.change_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_links  ENABLE ROW LEVEL SECURITY;
