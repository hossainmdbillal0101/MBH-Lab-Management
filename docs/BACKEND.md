# Private Firebase backend and login setup

Publishing the demo does not provision or connect a real backend. The following is the explicit owner-operated setup for the supplied implementation.

1. Create a separate Firebase project for this lab deployment. Enable Firestore in a suitable region and Authentication email/password. Review project access and enable MFA on administrator accounts. Do not import old production data into the public sample.
2. With the official Firebase CLI, sign in to the intended account and deploy only the reviewed rules: `firebase deploy --only firestore:rules --project YOUR_PROJECT_ID`. Review the target project before confirming. Do not use a production project for emulator tests. The Storage rules file denies all access and is supplied for review if a bucket already exists; Storage is not needed or enabled for this edition.
3. Create the initial staff/admin authentication account through the Firebase console. Set its password yourself or send a password-reset invitation privately. Do not publish a default administrator account or password. Copy its UID locally, not into source.
4. In a trusted local environment, install the dependencies in `backend-tools/`. Authenticate the Admin SDK through Application Default Credentials or an external secret-manager workflow. Run `node backend-tools/access.cjs --uid USER_UID --role admin`. Use `staff` for read-only staff, or `revoke` to remove application access. This script merges unrelated existing claims and does not print passwords, tokens or keys. Admin credentials bypass rules and require careful handling.
5. Create an ignored configuration file **outside** the repository with `FIREBASE_PROJECT_ID` and `FIREBASE_API_KEY`. These are Firebase client identifiers/configuration, not server credentials. Build a separate private workspace with `flutter build web --release --dart-define-from-file=PATH_TO_PRIVATE_CONFIG` or run an Android build with the same define file. Never place service-account credentials in that file. Add the actual deployment host to the Firebase Auth authorized-domain configuration where required.
6. Sign in using the provisioned account. Add laboratories first, then assets. Staff sign-in appears only in configured live builds. Restart/sign out and back in after changing custom claims. Revoke refresh tokens for account compromise; merely changing UI state does not invalidate a stolen token.
7. Test anonymous, unclaimed, staff and admin access before introducing real records. Verify network logs do not expose records to unauthenticated visitors. Add backups, monitoring, recovery procedures, token/session response and a retention policy appropriate to your institution.

## Rule tests

```sh
npm install --prefix backend-tests
firebase emulators:exec --only firestore --project demo-mbh-lab-management "node --test backend-tests/rules.test.cjs"
```

The `demo-` project identifier is intentional. Tests use fictional records, no production credentials and no real Firebase project. Photo uploads are denied until a separate access-controlled evidence design is implemented. The application does not deploy or configure a public registration endpoint.

## Known limits

This is a single-workspace design, not a multi-tenant SaaS. Dates use local calendar days. Staff cannot edit assets; operational writes are administrator-only. No inspection amendments, deletion, recovery UI, camera scan, evidence upload or offline synchronization is implemented. The UI hides editing while the backend is unavailable, but production enforcement is always the deployed rules. Account MFA and organization policies require owner review; they are not activated by this code.
