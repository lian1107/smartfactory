-- supabase/migrations/011_quality_records.sql

CREATE TABLE IF NOT EXISTS quality_records (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  date             date NOT NULL,
  inspection_type  text NOT NULL CHECK (inspection_type IN ('full', 'sample')),
  product_id       uuid REFERENCES products(id) ON DELETE SET NULL,
  total_qty        int NOT NULL CHECK (total_qty > 0),
  defect_qty       int NOT NULL DEFAULT 0 CHECK (defect_qty >= 0),
  notes            text,
  created_by       uuid REFERENCES profiles(id) ON DELETE SET NULL,
  created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_quality_records_date ON quality_records(date DESC);
CREATE INDEX idx_quality_records_created_by ON quality_records(created_by);

ALTER TABLE quality_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "read_quality_records"
  ON quality_records FOR SELECT
  USING (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'leader')
    )
  );

CREATE POLICY "insert_quality_records"
  ON quality_records FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'leader', 'qc')
    )
  );
