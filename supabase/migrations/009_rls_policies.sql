-- 009_rls_policies.sql
-- Row Level Security policies for all tables

-- ─────────────────────────────────────────────────────────────
-- Helper: check role
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
  SELECT current_user_role() = 'admin';
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- ─────────────────────────────────────────────────────────────
-- profiles
-- ─────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "profiles_select"       ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_own"   ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_admin" ON public.profiles;

CREATE POLICY "profiles_select" ON public.profiles
  FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_update_admin" ON public.profiles
  FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ─────────────────────────────────────────────────────────────
-- phase_templates / project_templates — read-only for most
-- ─────────────────────────────────────────────────────────────
CREATE POLICY "phase_templates_select" ON public.phase_templates
  FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "phase_templates_write"  ON public.phase_templates
  FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "project_templates_select" ON public.project_templates
  FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "project_templates_write"  ON public.project_templates
  FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ─────────────────────────────────────────────────────────────
-- products
-- ─────────────────────────────────────────────────────────────
CREATE POLICY "products_select" ON public.products
  FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "products_insert" ON public.products
  FOR INSERT TO authenticated WITH CHECK (
    public.current_user_role() IN ('admin','leader')
  );
CREATE POLICY "products_update" ON public.products
  FOR UPDATE TO authenticated USING (
    public.current_user_role() IN ('admin','leader')
  ) WITH CHECK (
    public.current_user_role() IN ('admin','leader')
  );
CREATE POLICY "products_delete" ON public.products
  FOR DELETE TO authenticated USING (public.is_admin());

-- ─────────────────────────────────────────────────────────────
-- projects
-- ─────────────────────────────────────────────────────────────
CREATE POLICY "projects_select" ON public.projects
  FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "projects_insert" ON public.projects
  FOR INSERT TO authenticated WITH CHECK (
    public.current_user_role() IN ('admin','leader')
  );
CREATE POLICY "projects_update" ON public.projects
  FOR UPDATE TO authenticated USING (
    public.current_user_role() IN ('admin','leader') OR owner_id = auth.uid()
  ) WITH CHECK (
    public.current_user_role() IN ('admin','leader') OR owner_id = auth.uid()
  );
CREATE POLICY "projects_delete" ON public.projects
  FOR DELETE TO authenticated USING (public.is_admin());

-- ─────────────────────────────────────────────────────────────
-- project_phases
-- ─────────────────────────────────────────────────────────────
CREATE POLICY "project_phases_select" ON public.project_phases
  FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "project_phases_write" ON public.project_phases
  FOR ALL TO authenticated USING (
    public.current_user_role() IN ('admin','leader')
  ) WITH CHECK (
    public.current_user_role() IN ('admin','leader')
  );

-- ─────────────────────────────────────────────────────────────
-- tasks
-- ─────────────────────────────────────────────────────────────
CREATE POLICY "tasks_select" ON public.tasks
  FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "tasks_insert" ON public.tasks
  FOR INSERT TO authenticated WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "tasks_update" ON public.tasks
  FOR UPDATE TO authenticated USING (
    assignee_id = auth.uid()
    OR created_by = auth.uid()
    OR public.current_user_role() IN ('admin','leader')
  ) WITH CHECK (
    assignee_id = auth.uid()
    OR created_by = auth.uid()
    OR public.current_user_role() IN ('admin','leader')
  );
CREATE POLICY "tasks_delete" ON public.tasks
  FOR DELETE TO authenticated USING (
    created_by = auth.uid() OR public.is_admin()
  );

-- ─────────────────────────────────────────────────────────────
-- task_comments
-- ─────────────────────────────────────────────────────────────
CREATE POLICY "task_comments_select" ON public.task_comments
  FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "task_comments_insert" ON public.task_comments
  FOR INSERT TO authenticated WITH CHECK (author_id = auth.uid());
CREATE POLICY "task_comments_update" ON public.task_comments
  FOR UPDATE TO authenticated USING (author_id = auth.uid())
  WITH CHECK (author_id = auth.uid());
CREATE POLICY "task_comments_delete" ON public.task_comments
  FOR DELETE TO authenticated USING (author_id = auth.uid() OR public.is_admin());

-- ─────────────────────────────────────────────────────────────
-- activity_logs — append-only read
-- ─────────────────────────────────────────────────────────────
CREATE POLICY "activity_logs_select" ON public.activity_logs
  FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "activity_logs_insert" ON public.activity_logs
  FOR INSERT TO authenticated WITH CHECK (actor_id = auth.uid() OR public.is_admin());

-- ─────────────────────────────────────────────────────────────
-- change_requests
-- ─────────────────────────────────────────────────────────────
CREATE POLICY "change_requests_select" ON public.change_requests
  FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "change_requests_insert" ON public.change_requests
  FOR INSERT TO authenticated WITH CHECK (requester_id = auth.uid());
CREATE POLICY "change_requests_update" ON public.change_requests
  FOR UPDATE TO authenticated USING (
    requester_id = auth.uid() OR public.current_user_role() IN ('admin','leader')
  ) WITH CHECK (
    requester_id = auth.uid() OR public.current_user_role() IN ('admin','leader')
  );

-- ─────────────────────────────────────────────────────────────
-- document_links
-- ─────────────────────────────────────────────────────────────
CREATE POLICY "document_links_select" ON public.document_links
  FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "document_links_insert" ON public.document_links
  FOR INSERT TO authenticated WITH CHECK (uploaded_by = auth.uid());
CREATE POLICY "document_links_delete" ON public.document_links
  FOR DELETE TO authenticated USING (uploaded_by = auth.uid() OR public.is_admin());

-- ─────────────────────────────────────────────────────────────
-- defect_codes — read all, write admin
-- ─────────────────────────────────────────────────────────────
CREATE POLICY "defect_codes_select" ON public.defect_codes
  FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "defect_codes_write"  ON public.defect_codes
  FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());
