# Security and privacy

The public demo uses fictional local records, no API configuration and no real backend. It has no staff sign-in or editing controls. Never connect the public sample to an institutional production project without a separate reviewed deployment.

In live builds, staff/admin claims are issued only by a trusted Firebase administrator. Firestore rules, rather than decoded UI claims, enforce access. Anonymous and ordinary unclaimed accounts cannot read or write records. Clients cannot grant roles. Administrator privileges require authentication and a configured backend. Existing staff accounts can read; only administrators can create labs/assets or record inspections. Inspection records are append-only, and associated asset status/service date changes are committed atomically with the inspection. No client delete operations are permitted.

Passwords and ID/refresh tokens remain in process memory. They are cleared on sign-out and are never written to preferences or intentionally logged. Browser refresh signs out. Firebase client API configuration becomes readable in a compiled live application; keeping it out of Git does not make it secret after deployment. Service-account keys, signing keys, refresh tokens and user passwords must never be placed in a client build or public archive.

Store the private client configuration outside this repository and use `--dart-define-from-file` for a private deployment. Restrict API key usage appropriately and enforce rules. Keep Admin SDK credentials in your OS credential environment or secret manager, outside the app and repository. Use minimal IAM roles and separate deployment credentials. Never run trusted provisioning in a public browser or an untrusted pull-request workflow.

Excluded: original Firebase files, `.env`, `.local.json`, private keys/keystores, machine-specific paths, generated build caches, private records, raw documents and original archives. Run `python scripts/check_publication.py` before publication. Pattern scanning cannot guarantee absence of all sensitive material; inspect attachments, history, screenshots, logs and artifacts as well.

Public sample data is not authorization-sensitive, but never repurpose its read-only banner as protection for real data. Production readiness also requires actual rule deployment, user provisioning, account MFA/recovery controls, operational monitoring, tested backups and privacy review. No claim of zero-leak or impenetrable security is made.
