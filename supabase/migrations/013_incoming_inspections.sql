-- supabase/migrations/013_incoming_inspections.sql

CREATE TABLE IF NOT EXISTS incoming_inspections (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  date                 date NOT NULL,
  material_name        text NOT NULL,
  supplier             text,
  total_qty            int NOT NULL CHECK (total_qty > 0),
  defect_qty           int NOT NULL DEFAULT 0 CHECK (defect_qty >= 0),
  defect_description   text,
  result               text NOT NULL CHECK (result IN ('pass', 'conditional', 'fail')),
  created_by           uuid REFERENCES profiles(id) ON DELETE SET NULL,
  created_at           timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_incoming_inspections_date ON incoming_inspections(date DESC);
CREATE INDEX idx_incoming_inspections_created_by ON incoming_inspections(created_by);

ALTER TABLE incoming_inspections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "read_incoming_inspections"
  ON incoming_inspections FOR SELECT
  USING (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'leader')
    )
  );

CREATE POLICY "insert_incoming_inspections"
  ON incoming_inspections FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid()
      AND role IN ('admin', 'leader', 'qc')
    )
  );
