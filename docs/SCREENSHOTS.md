# Screenshots

AFM3Tester does not require screenshots to build or run. The repository includes manually reviewed physical-device screenshots as optional documentation assets for the GitHub README and future release notes.

## Directory

Place redacted screenshots in:

```text
docs/screenshots/
```

Recommended filenames:

| Filename | Suggested content |
| --- | --- |
| `overview.png` | Overview tab with availability metadata |
| `basic-generation.png` | Basic generation prompt and output |
| `structured-output.png` | Structured output validation results |
| `tool-calling.png` | Tool invocation log |
| `conversation-memory.png` | Memory test transcript and checks |
| `multilingual-results.png` | Multilingual results and manual ratings |
| `concurrency.png` | Concurrency test summary |
| `offline-test.png` | Offline instructions and network-path status |
| `benchmark.png` | Three performance benchmark repetitions |
| `safety-observation.png` | Behavioral safety observations and application-level tool gating |
| `error-explorer.png` | Error Explorer with reflected error detail |

Only commit screenshots after redaction review.

## Redaction checklist

Before publishing screenshots, redact or avoid showing:

- Apple ID
- Personal name
- Team ID
- Bundle identifier if sensitive in your organization
- Device serial number
- UDID
- Email address
- Phone number
- Notification badges with private content
- Private prompt text
- Private project or company names not intended for public release
- Diagnostic exports containing user-entered text

## Capture tips

- Prefer light mode and a neutral wallpaper for readability.
- Use physical-device screenshots for inference results; simulator shots are suitable only for UI layout.
- Crop status bar details when they reveal personal information.
- Do not capture full diagnostic exports in screenshots unless heavily redacted.

## README usage

The root `README.md` intentionally avoids linking to screenshot files until they exist in this directory. After adding redacted images, maintainers may reference them with relative paths such as:

```markdown
![Overview](docs/screenshots/overview.png)
```

Verify links locally before publishing.
