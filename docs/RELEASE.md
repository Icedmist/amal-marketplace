# Release → APK workflow

Each **GitHub Release** (or `v*` tag) triggers a new Android APK build. The APK
is named with that release tag and uploaded to the release assets together with
a SHA-256 checksum.

## Trigger options

| Trigger | What happens |
|---------|----------------|
| Publish a GitHub Release | Workflow builds APK and uploads `amal-<tag>.apk` + `.sha256` |
| `git push origin v1.1.0` | Creates/updates release `v1.1.0` and uploads the APK |
| Actions → **Release APK** → Run workflow | Manual build; optional tag input |

## Recommended flow

```bash
# 1. Bump version in pubspec.yaml (e.g. 1.1.1+3)
# 2. Log the change in docs/CHANGELOG.md and CHANGELOG.md
# 3. Verify locally
flutter analyze --fatal-infos
flutter test
# 4. Commit
git add -A
git commit -m "Release v1.1.1"

# 5. Tag and push (this triggers the APK workflow)
git tag v1.1.1
git push origin main
git push origin v1.1.1
```

Or use the GitHub UI: **Releases → Draft a new release → tag `v1.1.1` → Publish**.

## What the workflow does

1. Checks out the tagged revision.
2. Resolves the release tag (release event, pushed tag, manual input, or
   `pubspec.yaml` version as a fallback).
3. Sets up Java 17 and Flutter stable.
4. Runs `flutter pub get`, `flutter analyze --fatal-infos` and `flutter test` —
   the build stops if analysis or tests fail.
5. Optionally configures a release keystore from secrets.
6. Builds `build/app/outputs/flutter-apk/app-release.apk`.
7. Copies it to `dist/amal-<tag>.apk`, writes `amal-<tag>.apk.sha256`, and
   uploads both to the workflow artifacts.
8. Creates the GitHub Release if needed and uploads the APK + checksum.

## Artifact naming

- Source build output: `build/app/outputs/flutter-apk/app-release.apk`
- Release asset: `amal-v1.1.0.apk` (tag with `/` replaced by `-`)
- Checksum: `amal-v1.1.0.apk.sha256`

## Signing secrets (optional but recommended)

Add these repository secrets for a stable Play-ready signature:

| Secret | Description |
|--------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded `.jks` / `.keystore` |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_ALIAS` | Key alias |
| `KEY_PASSWORD` | Key password |

Without them, CI still builds a **release-mode** APK signed with the debug
keystore (fine for testing downloads; not for Play Store).

Encode a keystore:

```bash
base64 -w0 upload-keystore.jks > keystore.b64
```

## Repository setup

The project is pushed to:

- https://github.com/Icedmist/amal-marketplace

The workflow file is
[`.github/workflows/release-apk.yml`](../.github/workflows/release-apk.yml).
