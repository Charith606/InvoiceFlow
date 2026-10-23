-- InvoiceFlow baseline schema. Run in Supabase SQL Editor after creating a project.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  full_name text not null default '',
  business_name text not null default '',
  phone text not null default '',
  business_gstin text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.profiles add column if not exists full_name text not null default '';
alter table public.profiles add column if not exists business_name text not null default '';
alter table public.profiles add column if not exists phone text not null default '';
alter table public.profiles add column if not exists business_gstin text not null default '';
create table if not exists public.suppliers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  gstin text,
  contact text,
  address text,
  created_at timestamptz not null default now(),
  unique(user_id, gstin)
);
create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  supplier_id uuid references public.suppliers(id) on delete set null,
  supplier_name text not null,
  supplier_gstin text,
  invoice_number text not null,
  invoice_date date not null,
  due_date date,
  taxable numeric(14,2) not null default 0 check(taxable >= 0),
  cgst numeric(14,2) not null default 0 check(cgst >= 0),
  sgst numeric(14,2) not null default 0 check(sgst >= 0),
  igst numeric(14,2) not null default 0 check(igst >= 0),
  other numeric(14,2) not null default 0,
  total numeric(14,2) not null check(total >= 0),
  paid numeric(14,2) not null default 0 check(paid >= 0 and paid <= total),
  status text not null default 'Pending review',
  note text not null default '',
  is_demo boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, supplier_gstin, invoice_number),
  check (not (cgst > 0 and igst > 0) and not (sgst > 0 and igst > 0))
);
create index if not exists invoices_user_due_idx on public.invoices(user_id, due_date);
create table if not exists public.invoice_line_items (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  description text not null,
  hsn_sac text,
  quantity numeric(14,3) check(quantity >= 0),
  rate numeric(14,2) check(rate >= 0),
  tax_rate numeric(6,3) check(tax_rate >= 0),
  created_at timestamptz not null default now()
);
create index if not exists invoice_line_items_parent_idx on public.invoice_line_items(user_id, invoice_id);
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  amount numeric(14,2) not null check(amount > 0),
  paid_at date not null,
  reference text,
  method text,
  note text not null default '',
  created_at timestamptz not null default now()
);
create index if not exists payments_invoice_idx on public.payments(user_id, invoice_id, paid_at);
create table if not exists public.invoice_documents (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid references public.invoices(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  bucket_id text not null default 'invoice-documents',
  storage_path text not null,
  original_name text not null,
  content_type text not null check(content_type in ('image/jpeg','image/png','application/pdf')),
  size_bytes bigint not null check(size_bytes between 1 and 12582912),
  created_at timestamptz not null default now(),
  unique(bucket_id, storage_path)
);
create table if not exists public.settlements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  order_id text,
  amount numeric(14,2),
  status text,
  utr_reference text,
  source text,
  raw_record jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(user_id, utr_reference)
);
-- Flexible storage for spreadsheet files whose columns do not match a built-in table.
create table if not exists public.dataset_imports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  file_name text not null,
  sheets jsonb not null default '[]'::jsonb,
  row_count integer not null default 0 check(row_count >= 0),
  created_at timestamptz not null default now()
);
create index if not exists dataset_imports_user_created_idx on public.dataset_imports(user_id, created_at desc);
create table if not exists public.cash_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  available numeric(14,2) not null default 0 check(available >= 0),
  reserve numeric(14,2) not null default 0 check(reserve >= 0),
  inflows jsonb not null default '[]'::jsonb,
  expenses jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.suppliers enable row level security;
alter table public.invoices enable row level security;
alter table public.invoice_line_items enable row level security;
alter table public.payments enable row level security;
alter table public.invoice_documents enable row level security;
alter table public.settlements enable row level security;
alter table public.dataset_imports enable row level security;
alter table public.cash_settings enable row level security;

-- Remove these named policies first so this schema can be safely rerun.
drop policy if exists "profile owner access" on public.profiles;
drop policy if exists "supplier owner access" on public.suppliers;
drop policy if exists "invoice owner access" on public.invoices;
drop policy if exists "line item owner access" on public.invoice_line_items;
drop policy if exists "payment owner access" on public.payments;
drop policy if exists "document owner access" on public.invoice_documents;
drop policy if exists "settlement owner access" on public.settlements;
drop policy if exists "dataset import owner access" on public.dataset_imports;
drop policy if exists "cash settings owner access" on public.cash_settings;
drop policy if exists "private invoice files owner access" on storage.objects;

create policy "profile owner access" on public.profiles for all to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
create policy "supplier owner access" on public.suppliers for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "invoice owner access" on public.invoices for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "line item owner access" on public.invoice_line_items for all to authenticated using ((select auth.uid()) = user_id and exists(select 1 from public.invoices i where i.id = invoice_id and i.user_id = (select auth.uid()))) with check ((select auth.uid()) = user_id and exists(select 1 from public.invoices i where i.id = invoice_id and i.user_id = (select auth.uid())));
create policy "payment owner access" on public.payments for all to authenticated using ((select auth.uid()) = user_id and exists(select 1 from public.invoices i where i.id = invoice_id and i.user_id = (select auth.uid()))) with check ((select auth.uid()) = user_id and exists(select 1 from public.invoices i where i.id = invoice_id and i.user_id = (select auth.uid())));
create policy "document owner access" on public.invoice_documents for all to authenticated using ((select auth.uid()) = user_id and (invoice_id is null or exists(select 1 from public.invoices i where i.id = invoice_id and i.user_id = (select auth.uid())))) with check ((select auth.uid()) = user_id and (invoice_id is null or exists(select 1 from public.invoices i where i.id = invoice_id and i.user_id = (select auth.uid()))));
create policy "settlement owner access" on public.settlements for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "dataset import owner access" on public.dataset_imports for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "cash settings owner access" on public.cash_settings for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

grant select, insert, update, delete on public.profiles, public.suppliers, public.invoices, public.invoice_line_items, public.payments, public.invoice_documents, public.settlements, public.dataset_imports, public.cash_settings to authenticated;
insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values ('invoice-documents','invoice-documents',false,12582912,array['image/jpeg','image/png','application/pdf'])
on conflict (id) do nothing;
create policy "private invoice files owner access" on storage.objects for all to authenticated
using (bucket_id = 'invoice-documents' and (storage.foldername(name))[1] = (select auth.uid())::text)
with check (bucket_id = 'invoice-documents' and (storage.foldername(name))[1] = (select auth.uid())::text);
