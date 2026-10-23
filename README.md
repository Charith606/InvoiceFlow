# InvoiceFlow prototype

InvoiceFlow is a no-build HTML/CSS/JavaScript application. It requires a user's own Supabase Auth account before opening the workspace. It uses Supabase for invoices, suppliers, settlements, and cash-flow settings. Demo records are not copied into accounts; no demo account is provided.

## Run locally

Serve `index.html` from localhost (for example, in this folder run `python -m http.server 8000` and open `http://localhost:8000`). Camera APIs generally require localhost or HTTPS; opening the file directly with `file://` may not support camera access. OCR loads Tesseract.js from jsDelivr, so OCR needs an internet connection. Manual invoice entry works without camera access.

## Camera and OCR

- Select **Scan with camera** to request permission, take a picture, retake, or accept it for OCR. The camera stream is stopped when the scanner closes or capture is taken.
- If live camera access is unavailable, choose **Upload invoice image/PDF**; compatible mobile browsers can offer the rear camera via the file picker.
- OCR currently supports JPG/JPEG and PNG, including captured images. PDF selection reports the limitation and offers manual entry; it does not OCR PDFs.
- OCR attempts supplier, GSTIN, invoice number/date, due date, taxable amount, CGST, SGST, IGST, and total. The app presents extracted text and requires opening the editable invoice form to check and save values. Missing fields remain blank. Line items are not extracted.
- InvoiceFlow retains its existing GST arithmetic warnings and duplicate matching. OCR is not government GST verification.

## GitHub Pages preparation

The manual-only workflow in `.github/workflows/deploy-pages.yml` packages only `index.html`. Before running it in GitHub, add the repository variables `INVOICEFLOW_SUPABASE_URL` and `INVOICEFLOW_SUPABASE_PUBLISHABLE_KEY`, then choose **Settings → Pages → GitHub Actions** as the publishing source. The workflow runs only when manually dispatched from the Actions tab. It creates the runtime `window.INVOICEFLOW_SUPABASE` configuration inside the staged copy of `index.html`; it does not publish `supabase-config.js` as a separate file or change the local app. The URL and publishable key are visible to browser visitors by design; never use a secret or service-role key here.

The workflow publishes only the app entry page, so local datasets, backups, SQL files, and other repository files are not included in the Pages artifact. The local `.gitignore` also excludes `dataset_for_billing.csv`, `index backup .html`, `supabase-config.js`, and the generated staging folder. After choosing the final GitHub Pages URL, add that exact URL to Supabase Auth's allowed redirect URLs and set it as the Site URL so email confirmation links return to the deployed app.

## Supabase setup (required)

1. Create a Supabase project and open **SQL Editor**.
2. Run `supabase/schema.sql`. It creates per-user tables for profiles, suppliers, invoices, line items, payments, document metadata, and optional settlements; enables RLS; and creates a private `invoice-documents` bucket with user-folder policies.
3. Enable email/password sign-in and email confirmation in Supabase Auth settings; configure localhost/deployed URLs under Auth URL configuration.
4. Copy `supabase-config.example.js` to `supabase-config.js`, then set the project URL and **publishable** key from Project Settings. Never put a secret/service-role key in browser code.

Without this configuration, the app shows sign-in and registration but cannot open the workspace. Passwords are sent to Supabase Auth over HTTPS; InvoiceFlow does not save plaintext passwords, create its own hashes, or keep passwords in localStorage. Supabase Auth handles password hashing and credential storage. The browser uses only a publishable key and RLS limits account data access. Existing demo data is not imported when a user registers.

### Required phone verification (MFA)

The app requires a one-time SMS code at account setup and each sign-in. In Supabase Dashboard, enable Phone MFA/verification and configure an SMS provider (for example Twilio or another supported provider) with valid sender credentials and permitted destination countries. Then run `supabase/mfa-enforcement.sql` after `schema.sql`; these restrictive policies require an AAL2 session for all database tables and invoice Storage objects. A browser notification permission is not used as authentication. If the SMS provider is not configured, verification cannot send a code and the workspace stays locked.

Registration asks for full name, official business/organization name, and mobile number; business GSTIN is optional. These profile details are stored in Supabase Auth user metadata and mirrored to the user's protected `profiles` row after sign-in. If you already ran the earlier schema, run `supabase/profile-details.sql` once to add the new profile columns.

Invoice fields, supplier records, settlements, and cash settings are connected to PostgreSQL. The current payment interface updates each invoice's paid balance and keeps its reference in the invoice note; it does not yet write separate rows to the normalized `payments` table. Private document metadata and Storage policies are prepared, but file uploads are not yet connected to Supabase Storage. The current UI has no line-item editor.

## Data and existing capabilities

The supplied CSV and seeded invoices are synthetic demo data. They are only source defaults before authentication; after sign-in, they are replaced by the user's cloud data and are never uploaded. Use Export data for a JSON backup. The app includes invoice entry/editing, GST checks, duplicate review, payment recording, cash-flow forecast, CSV import/export, and settlement analysis.

## Dependencies and verification

There is no package manager or build step. Tesseract.js 5.1.1 and Supabase JS v2 are loaded from CDNs at runtime. Camera, OCR accuracy, cloud persistence, and cross-account RLS behavior still require browser/device tests with a configured Supabase project. Run the SQL once in a new project; this initial setup script creates policies.
