# Workloop

Workloop is a Flutter + Riverpod + Supabase app for solo appointment-based service businesses.

## Local Setup

Create a local `.env` file from `.env.example`, then run:

```bash
source scripts/dev_env.sh
flutter run -d ios --dart-define-from-file=.env
```

On this Mac, Flutter is checked out next to the repo at `../flutter`, and CocoaPods is installed in the user Ruby gem directory. The setup script adds both to `PATH` and sets the Ruby logger option required by CocoaPods on the system Ruby.

For the common iPhone simulator flow:

```bash
scripts/run_ios_sim.sh
```

## Verification

```bash
source scripts/dev_env.sh
flutter analyze
flutter test --dart-define-from-file=.env
```

To check the local Apple/Flutter toolchain:

```bash
scripts/flutter_doctor.sh
```

If an iOS/macOS build fails with `resource fork, Finder information, or similar detritus not allowed`, strip Apple extended attributes from generated SDK/build artifacts:

```bash
scripts/strip_apple_xattrs.sh
```

If that error persists from a repo under `Documents`, move generated build output to `/private/tmp` so macOS File Provider metadata does not break code signing:

```bash
scripts/use_tmp_build_dir.sh
```

## Notes

- Do not commit `.env`.
- Supabase table access should stay inside `lib/shared/repositories/`.
- See `docs/foundation.md` and `docs/security.md` before adding major features.
