-- 004_products.sql
-- Products (物料/型号) managed in the factory

CREATE TABLE IF NOT EXISTS public.products (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code            TEXT NOT NULL UNIQUE,          -- product code / part number
  name            TEXT NOT NULL,
  description     TEXT,
  category        TEXT,
  specification   TEXT,
  unit            TEXT NOT NULL DEFAULT 'pcs',
  thumbnail_url   TEXT,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_by      UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_products_code     ON public.products(code);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);
CREATE INDEX IF NOT EXISTS idx_products_active   ON public.products(is_active);

CREATE OR REPLACE TRIGGER trg_products_updated_at
  BEFORE UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
