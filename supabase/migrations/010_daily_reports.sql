-- supabase/migrations/010_daily_reports.sql

-- 生产日报主表
CREATE TABLE IF NOT EXISTS daily_reports (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  date          date NOT NULL,
  shift         text NOT NULL CHECK (shift IN ('early', 'mid', 'late')),
  product_id    uuid REFERENCES products(id) ON DELETE SET NULL,
  production_line text,
  created_by    uuid REFERENCES profiles(id) ON DELETE SET NULL,
  status        text NOT NULL DEFAULT 'submitted'
                  CHECK (status IN ('draft', 'submitted')),
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

-- 小时时段明细表
CREATE TABLE IF NOT EXISTS report_time_slots (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id     uuid NOT NULL REFERENCES daily_reports(id) ON DELETE CASCADE,
  slot_start    int NOT NULL,  -- 小时数，如 8 = 08:00
  slot_end      int NOT NULL,  -- 如 9 = 09:00
  planned_qty   int NOT NULL DEFAULT 0,
  actual_qty    int NOT NULL DEFAULT 0,
  defect_qty    int NOT NULL DEFAULT 0,
  downtime_reason text,
  created_at    timestamptz NOT NULL DEFAULT now()
);

-- 确保 updated_at 触发器函数存在（兼容不同迁移历史）
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $func$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END
$func$;

-- updated_at 触发器
CREATE TRIGGER update_daily_reports_updated_at
  BEFORE UPDATE ON daily_reports
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- 索引
CREATE INDEX idx_daily_reports_date ON daily_reports(date DESC);
CREATE INDEX idx_daily_reports_created_by ON daily_reports(created_by);
CREATE INDEX idx_report_time_slots_report_id ON report_time_slots(report_id);

-- RLS
ALTER TABLE daily_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_time_slots ENABLE ROW LEVEL SECURITY;

-- daily_reports RLS
CREATE POLICY "leader_and_above_read_reports"
  ON daily_reports FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('admin', 'leader')
    )
    OR created_by = auth.uid()
  );

CREATE POLICY "workshop_insert_reports"
  ON daily_reports FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('admin', 'leader', 'technician', 'qc')
    )
  );

CREATE POLICY "own_update_reports"
  ON daily_reports FOR UPDATE
  USING (created_by = auth.uid());

-- report_time_slots RLS（跟随 daily_reports 权限）
CREATE POLICY "read_slots_via_report"
  ON report_time_slots FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM daily_reports dr
      WHERE dr.id = report_id
      AND (
        dr.created_by = auth.uid()
        OR EXISTS (
          SELECT 1 FROM profiles p
          WHERE p.id = auth.uid()
          AND p.role IN ('admin', 'leader')
        )
      )
    )
  );

CREATE POLICY "insert_slots_via_report"
  ON report_time_slots FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM daily_reports dr
      WHERE dr.id = report_id
      AND dr.created_by = auth.uid()
    )
  );
