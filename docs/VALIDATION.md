# Validation

- Flutter 3.10.4 / Dart 3.0.3: analysis passed with no issues.
- 8 application tests passed: public write denial, authenticated role boundaries, asset-tag uniqueness/validation, complete inspections, atomic state/history updates, responsive navigation and search.
- 5 Firestore emulator tests passed: anonymous/unclaimed denial, staff read-only access, admin schema validation, atomic inspection/asset consistency, immutable history and unknown-collection denial.
- Optional preview capture passed for desktop overview, desktop assets and mobile assets. Rendered previews are not physical-device tests.
- Release web build passed and deployed core assets match the tested build.
- Android debug APK built successfully with a separate local development signing environment. It is a demonstration build, not a signed production release.
- Publication scan passed. Original Firebase configuration, archives and personal/institutional records are excluded. No absolute guarantee of secret absence is made by pattern scanning.
- Real Firebase provisioning/login, deployed production rules and browser interaction/physical-device acceptance testing remain separate checks.
