-- Require completed phone/TOTP MFA (JWT AAL2) for all authenticated access.
-- Run after schema.sql. Users without a verified factor cannot access data.
create policy "MFA required for profiles" on public.profiles as restrictive for all to authenticated
using ((select auth.jwt()->>'aal') = 'aal2') with check ((select auth.jwt()->>'aal') = 'aal2');
create policy "MFA required for suppliers" on public.suppliers as restrictive for all to authenticated
using ((select auth.jwt()->>'aal') = 'aal2') with check ((select auth.jwt()->>'aal') = 'aal2');
create policy "MFA required for invoices" on public.invoices as restrictive for all to authenticated
using ((select auth.jwt()->>'aal') = 'aal2') with check ((select auth.jwt()->>'aal') = 'aal2');
create policy "MFA required for invoice lines" on public.invoice_line_items as restrictive for all to authenticated
using ((select auth.jwt()->>'aal') = 'aal2') with check ((select auth.jwt()->>'aal') = 'aal2');
create policy "MFA required for payments" on public.payments as restrictive for all to authenticated
using ((select auth.jwt()->>'aal') = 'aal2') with check ((select auth.jwt()->>'aal') = 'aal2');
create policy "MFA required for documents" on public.invoice_documents as restrictive for all to authenticated
using ((select auth.jwt()->>'aal') = 'aal2') with check ((select auth.jwt()->>'aal') = 'aal2');
create policy "MFA required for settlements" on public.settlements as restrictive for all to authenticated
using ((select auth.jwt()->>'aal') = 'aal2') with check ((select auth.jwt()->>'aal') = 'aal2');
create policy "MFA required for cash settings" on public.cash_settings as restrictive for all to authenticated
using ((select auth.jwt()->>'aal') = 'aal2') with check ((select auth.jwt()->>'aal') = 'aal2');
create policy "MFA required for private invoice files" on storage.objects as restrictive for all to authenticated
using ((select auth.jwt()->>'aal') = 'aal2') with check ((select auth.jwt()->>'aal') = 'aal2');
