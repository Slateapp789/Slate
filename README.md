# Slate

Slate is a Flutter + Riverpod + Supabase app for solo appointment-based service businesses.

## Local Setup

Create a local `.env` file from `.env.example`, then run:

```bash
flutter run --dart-define-from-file=.env
```

## Verification

```bash
flutter analyze
flutter test --dart-define-from-file=.env
```

## Notes

- Do not commit `.env`.
- Supabase table access should stay inside `lib/shared/repositories/`.
- See `docs/foundation.md` and `docs/security.md` before adding major features.
