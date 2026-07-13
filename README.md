# AFM3Tester

[![CI](https://github.com/bobbanj/AFM3Tester/actions/workflows/ci.yml/badge.svg)](https://github.com/bobbanj/AFM3Tester/actions/workflows/ci.yml)

**AFM3Tester — Foundation Models diagnostics for SwiftUI developers**

AFM3Tester is an open-source SwiftUI diagnostic and capability test suite for Apple’s public **FoundationModels** framework on supported physical iPhones running iOS 27.

It helps developers observe on-device model availability, run structured diagnostics, inspect errors faithfully, and export redacted reports — without third-party SDKs, network-backed model providers, analytics, or telemetry.

> **Observed result:** On one iPhone 17 Pro Max in Sweden running iOS 27 Developer Beta 3, `SystemLanguageModel.default` reported **Available**, deployment was observed as **on-device**, and basic text generation succeeded. This is a beta-software observation, not a universal guarantee for other devices, regions, locales, builds, or releases.

## What it tests

AFM3Tester currently exercises:

- `SystemLanguageModel` availability
- On-device inference
- Model context size
- Basic generation
- Streaming generation
- Sampling configuration
- Structured output / guided generation
- Tool calling
- Side-effect tool permission gating
- Multi-turn session memory
- Transcript rehydration
- Multilingual generation
- Prompt-injection observations
- Context-window behavior
- Conservative concurrency testing
- Latency and throughput
- Thermal and battery state
- Offline verification
- Detailed error reporting
- JSON and Markdown diagnostic exports

See [docs/TEST_MATRIX.md](docs/TEST_MATRIX.md) for the full matrix.

## Why this project exists

AFM3Tester was built to exercise the public **FoundationModels** APIs on physical hardware and record observed availability, context limits, inference behavior, tool calls, memory, exports, and application-level policy enforcement.

This project reports observations. It does not predict future OS behavior, and it does not claim every EU device or release will behave identically.

## Verified environment

These values come from a captured physical-device run documented in [docs/OBSERVED_RESULTS.md](docs/OBSERVED_RESULTS.md):

| Field | Observed value |
| --- | --- |
| Device | iPhone 17 Pro Max (`iPhone18,2`) |
| OS | iOS 27 Developer Beta 3 |
| Build observed | 24A5380h |
| Model | `SystemLanguageModel.default` |
| Reported framework description observed | AFM 3 Core Advanced (framework/runtime observation; not a stable public API identifier) |
| Deployment | On-device |
| Availability | Available |
| Public `contextSize` observed on this device/build | 8192 tokens (runtime SDK property value) |
| Region during test | Sweden |
| App locale during captured test | en_US |

Beta behavior, model descriptions, context limits, and availability may change without notice.

## Screenshots

These physical-device screenshots were manually reviewed for device names, Apple IDs, team IDs, personal bundle IDs, notification content, email addresses, phone numbers, serial numbers, and UDIDs. The PNG files contain image data only and no text or ancillary metadata chunks.

| Offline-path observation | Concurrency observation |
| --- | --- |
| <img src="docs/screenshots/offline-test.png" alt="Offline test showing no satisfied network path and three successful checks" width="280"> | <img src="docs/screenshots/concurrency.png" alt="Concurrency test showing nine successful requests and no failures" width="280"> |

| Benchmark observation | Safety behavior observation | Multilingual observation |
| --- | --- | --- |
| <img src="docs/screenshots/benchmark.png" alt="Three physical-device performance benchmark repetitions" width="240"> | <img src="docs/screenshots/safety-observation.png" alt="Behavioral safety observations and application-level tool gating" width="240"> | <img src="docs/screenshots/multilingual-results.png" alt="Multilingual generation observations and manual rating controls" width="240"> |

See [docs/SCREENSHOTS.md](docs/SCREENSHOTS.md) for filenames and the publication redaction checklist.

## Requirements

- macOS capable of running **Xcode 27**
- **Xcode 27** beta or later compatible release
- **iOS 27** supported physical iPhone for inference testing
- Apple Intelligence / Foundation Models assets downloaded on the device
- **Developer Mode** enabled on the iPhone
- Apple ID added to Xcode
- A valid signing team selected in Xcode
- The iOS Simulator may display the UI, but **cannot execute Foundation Models inference**

Observed simulator failure:

```text
InferenceError::operationNotAllowed::Simulator is not supported
```

You do not need a paid Apple Developer Program membership to inspect UI in Simulator, but device inference testing requires normal Xcode signing setup.

## Getting started

1. Clone the repository:

   ```bash
   git clone https://github.com/bobbanj/AFM3Tester.git
   cd AFM3Tester
   ```

2. Open the project:

   ```bash
   open AFM3Tester.xcodeproj
   ```

3. Select the **AFM3Tester** app target.
4. Open **Signing & Capabilities**.
5. Choose your own development team.
6. Set a unique **Bundle Identifier** for your fork or local testing.
7. Connect a supported physical iPhone.
8. Enable **Developer Mode** on the device if prompted.
9. Select the physical iPhone as the run destination.
10. Build and run.
11. Wait for Apple Intelligence / Foundation Models assets to finish downloading on the device.
12. On **Overview**, confirm framework availability and the public `contextSize` value.
13. Tap **Run All Safe Tests** on a physical device to exercise inference paths.
14. For offline verification, manually enable **Airplane Mode**, disable Wi‑Fi if it remains active, confirm the app reports no satisfied network path, then run **Offline Test** and export the report.

## Physical device testing checklist

Record these fields when validating on hardware (for example in [docs/OBSERVED_RESULTS.md](docs/OBSERVED_RESULTS.md) or an exported report):

| Field | Why it matters |
| --- | --- |
| Device model | Hardware eligibility varies |
| iOS version and build | Beta behavior changes between builds |
| Region and locale | Availability and language support vary |
| Model availability | `SystemLanguageModel.default` availability state |
| Framework description | Any `String(describing:)` or UI label — observation only |
| Basic generation result | Pass / fail / unavailable with exact reflected error |
| Offline-path result | Whether inference succeeded while no satisfied path was observed |
| Thermal state | May affect throttling during benchmarks |
| Charging state | Battery/charging context for benchmark interpretation |

Simulator builds can compile and display UI, but **Foundation Models inference is unsupported in Simulator**.

## Automated tests

Deterministic logic is covered by the **AFM3TesterTests** XCTest target:

```bash
xcodebuild -project AFM3Tester.xcodeproj -scheme AFM3Tester -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Embedded debug self-tests on the Overview tab (Debug builds only) are interactive diagnostics and are **not** a substitute for XCTest.

## Test suite

| Tab / area | What it proves |
| --- | --- |
| Overview | Device/OS/locale metadata, availability, context size, last successful inference, copy/export baseline |
| Generate | Interactive basic and streaming generation, temperature, deterministic seed, latency metrics |
| Structured | `@Generable` decoding for meeting summaries and support ticket batches |
| Tools | Local tool calling, argument validation, explicit side-effect gating |
| Memory | Same-session recall, fresh-session isolation, in-memory transcript rehydration |
| Languages | Compact generation across five languages with automatic heuristics and manual quality ratings |
| Safety | Benign prompt-injection observations — not a security certification |
| Context | Synthetic long-context recall until context-limit errors |
| Concurrency | Conservative 1 / 2 sequential / 2 concurrent / 4 concurrent probes |
| Benchmark | Three streaming repetitions with thermal, battery, and LPM snapshots |
| Offline | Evidence that tested inference paths can run with no active network route |
| Errors | Full reflected errors with classification |
| Export | Redacted JSON/Markdown diagnostic sharing |

### Wording that matters

- A successful **offline test** shows the tested inference path ran while no active network route was available.
- **Safety tests** are behavioral observations, not a security certification.
- **Tool-call blocking** demonstrates application policy enforcement, not guaranteed model resistance to prompt injection.
- **Concurrency success** does not prove hardware inference was physically parallel; the framework may serialize work.
- **Character throughput** is not token throughput.
- **Beta benchmarks** are not official Apple performance numbers.

More detail: [docs/TEST_MATRIX.md](docs/TEST_MATRIX.md).

## Security model

Model output must never be treated as authorization.

AFM3Tester implements this side-effect gating pattern:

- Read-only tools can run during normal diagnostic flows.
- Side-effect tools require explicit user permission in the UI.
- Quoted or retrieved content does not grant permission.
- Tool arguments are validated deterministically after model generation.
- The **application policy layer**, not the language model, enforces permissions.

During physical-device testing, a quoted instruction caused a side-effect tool-call attempt, and the application correctly blocked the side effect.

Read more: [docs/SECURITY_MODEL.md](docs/SECURITY_MODEL.md).

## Offline verification

Offline mode uses `NWPathMonitor` to detect whether any network path is satisfied.

Important:

- The app **cannot** toggle Airplane Mode.
- You must enable Airplane Mode manually.
- Disable Wi‑Fi as well if it remains active.
- Wait for the app to show an offline / no satisfied path state before running the offline suite.

In the captured physical-device observation, the app reported **Offline (no satisfied path)** and basic generation, structured output, and memory checks succeeded. This establishes only that those tested paths succeeded while the app observed no satisfied network path; it is not absolute proof of all framework or OS behavior. See [docs/OBSERVED_RESULTS.md](docs/OBSERVED_RESULTS.md).

## Privacy

AFM3Tester is designed for local diagnostics:

- No analytics
- No telemetry
- No third-party SDKs
- Prompt text is not collected or exported by this developer preview
- Diagnostic fields are redacted before JSON and Markdown export
- Redaction attempts to remove email addresses, phone numbers, API keys, tokens, and passwords

You should still inspect reports before publishing them. Model output and errors may contain sensitive text.

## Architecture

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the current module layout, inference actor, test runners, export pipeline, and permission model.

## Known limitations

- iOS beta APIs may change
- Simulator inference is unsupported
- Results vary by device, thermal state, battery state, locale, language, model assets, and OS build
- Automatic multilingual checks do not establish linguistic quality
- Prompt-injection tests are limited observations
- Estimated token counts may be approximate unless obtained from a public SDK property
- Model name strings are diagnostic descriptions and should not be treated as stable API identifiers
- The app does not certify compliance, security, safety, or production readiness

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening large changes.

- Open an issue before substantial new suites or architecture changes
- Keep tests deterministic where practical
- Do not add network dependencies or private APIs
- Include device, OS build, locale, region, model availability, and exact reflected errors in bug reports
- Never upload private prompts or credentials

## Security

To report security issues, read [SECURITY.md](SECURITY.md).

## License

MIT License — see [LICENSE](LICENSE).

Copyright (c) 2026 Robert Jakobsson

## Disclaimer

This project is independent and is **not affiliated with, sponsored by, or endorsed by Apple Inc.**

Apple, iPhone, iOS, Xcode, Swift, Siri, Apple Intelligence, and Foundation Models are trademarks of Apple Inc.

Results in this repository are observations from beta software and may change.

## Related documents

- [CHANGELOG.md](CHANGELOG.md)
- [docs/OBSERVED_RESULTS.md](docs/OBSERVED_RESULTS.md)
- [docs/RELEASE_SCREENSHOT_CHECKLIST.md](docs/RELEASE_SCREENSHOT_CHECKLIST.md)
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
