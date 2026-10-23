-- Apply this upgrade to an existing InvoiceFlow Supabase database.
alter table public.profiles add column if not exists full_name text not null default '';
alter table public.profiles add column if not exists business_name text not null default '';
alter table public.profiles add column if not exists phone text not null default '';
alter table public.profiles add column if not exists business_gstin text not null default '';
