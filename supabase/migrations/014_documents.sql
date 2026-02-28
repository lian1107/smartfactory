-- 014_documents.sql
create table if not exists public.documents (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  description text,
  type        text not null check (type in ('feishu', 'file', 'note')),
  url         text,
  file_path   text,
  content     text,
  category    text check (category in ('作业指导书', '质量标准', '设备手册', '其他')),
  tags        text[] default '{}',
  created_by  uuid references public.profiles(id) on delete set null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- updated_at trigger (reuses shared function from 001_profiles_and_auth.sql)
create trigger documents_updated_at
  before update on public.documents
  for each row execute function public.update_updated_at();

-- RLS
alter table public.documents enable row level security;

-- All authenticated users can read
create policy "documents_select" on public.documents
  for select to authenticated using (true);

-- Only admin can insert
create policy "documents_insert" on public.documents
  for insert to authenticated
  with check (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

-- Only admin can update
create policy "documents_update" on public.documents
  for update to authenticated
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

-- Only admin can delete
create policy "documents_delete" on public.documents
  for delete to authenticated
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );
