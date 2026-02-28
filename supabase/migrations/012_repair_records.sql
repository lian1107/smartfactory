-- supabase/migrations/012_repair_records.sql

CREATE TABLE IF NOT EXISTS repair_records (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  date              date NOT NULL,
  product_id        uuid REFERENCES products(id) ON DELETE SET NULL,
  fault_types       text[] NOT NULL DEFAULT '{}',
  repair_action     text NOT NULL,
  duration_minutes  int,
  created_by        uuid REFERENCES profiles(id) ON DELETE SET NULL,
  created_at        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_repair_records_date ON repair_records(date DESC);
CREATE INDEX idx_repair_records_created_by ON repair_records(created_by);

ALTER TABLE repair_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "read_repair_records"
  ON repair_records FOR SELECT
  USING (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'leader')
    )
  );

CREATE POLICY "insert_repair_records"
  ON repair_records FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid()
      AND role IN ('admin', 'leader', 'technician')
    )
  );
