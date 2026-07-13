# Release Screenshot Checklist

Do not add screenshots to the repository until they are captured on real hardware and redacted. This checklist defines expected filenames and minimum redaction requirements.

## Expected filenames

Place redacted images under `docs/screenshots/`:

| Filename | What to capture |
| --- | --- |
| `overview-availability.png` | Overview tab showing device metadata, framework availability, and context size label |
| `basic-generation.png` | Basic generation tab with a successful on-device response |
| `structured-output.png` | Structured output validation checks after a successful run |
| `tool-calling.png` | Tool invocation transcript and deterministic tool results |
| `conversation-memory.png` | Memory tab showing same-session recall |
| `multilingual-results.png` | Multilingual tab with manual quality ratings visible |
| `offline-test.png` | Offline tab showing no satisfied network path and exported evidence summary |
| `error-explorer.png` | Error explorer with a classified reflected error |
| `exported-report.png` | Export tab or share sheet showing redacted Markdown/JSON output |

## Redaction requirements

Before publishing any screenshot, verify the image does **not** reveal:

- Personal status-bar indicators where inappropriate (carrier name, unread counts, personal notifications)
- Device names assigned in Settings
- Apple IDs or account names
- Email addresses
- Phone numbers
- Notification contents
- Project or team identifiers from Xcode signing
- Absolute local filesystem paths
- API keys, tokens, passwords, or provisioning details

Use the in-app export redaction pipeline as a baseline, then manually inspect each image.

## Capture notes

- Capture on a supported physical iPhone running iOS 27 beta or later compatible build.
- Record device model, OS version/build, locale, and region alongside each screenshot in commit messages or release notes — not inside the image when avoidable.
- Label any framework description strings visible in UI as observations, not guaranteed stable metadata.
- Do not claim offline execution from screenshots unless Airplane Mode was manually enabled and the app reported no satisfied network path.

## Repository policy

- No placeholder or fabricated screenshots.
- No broken image links in README until files exist.
- See also [SCREENSHOTS.md](SCREENSHOTS.md).
