# AFM3Tester

[![CI](https://github.com/bobbanj/AFM3Tester/actions/workflows/ci.yml/badge.svg)](https://github.com/bobbanj/AFM3Tester/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Swift 6](https://img.shields.io/badge/Swift-6-orange.svg)](https://swift.org)
[![iOS 27](https://img.shields.io/badge/iOS-27-lightgrey.svg)](https://developer.apple.com/ios/)
[![TestFlight](https://img.shields.io/badge/TestFlight-Public_Beta-blue.svg)](https://testflight.apple.com/join/FJMVaGWC)

**AFM3Tester — Apple Foundation Models Diagnostic Suite**

AFM3Tester is an open-source SwiftUI diagnostic and capability test suite for Apple’s public **Foundation Models** framework on supported physical iPhones running **iOS 27**.

It helps developers observe on-device `SystemLanguageModel` **Availability**, run structured diagnostics, inspect errors faithfully, and export redacted **Device Report** Markdown — without third-party SDKs, network-backed model providers, analytics, or telemetry.

> **Observed result:** Verified on a physical iPhone in Sweden running iOS 27 beta: `SystemLanguageModel.default` was **Available** and executed **On-Device**. This is a recorded test observation, not a universal guarantee for all devices, regions, or future OS builds.

## Try AFM3Tester

- **GitHub:** https://github.com/bobbanj/AFM3Tester
- **Public TestFlight:** https://testflight.apple.com/join/FJMVaGWC

## TestFlight

AFM3Tester is available as a **public TestFlight beta**.

Requirements:

- A supported physical iPhone (Simulator UI only — no Foundation Models inference)
- **iOS 27**
- Apple Intelligence / Foundation Models assets downloaded and ready
- Apple ID for TestFlight

TestFlight builds may be newer than the latest GitHub release. Prefer TestFlight when you want the most recent release-polish package; use GitHub when you need source, issues, and contribution history.

## What's New in 0.2.2

- Offline Verification reporting improvements (Device Report / History stay consistent with UI)
- Correct Expected Policy Event reporting (separate from Errors)
- Local run History
- Compare Runs
- Community Device Reports via **Copy GitHub Device Report**
- TestFlight beta availability
- Improved export consistency and redaction for metrics

### Try AFM3Tester

• GitHub

https://github.com/bobbanj/AFM3Tester

• TestFlight

https://testflight.apple.com/join/FJMVaGWC

Supports:

• iPhone
• iOS 27 Beta
• Apple Foundation Models

No Xcode required.

## What it tests

AFM3Tester currently exercises:

- `SystemLanguageModel` Availability
- On-Device inference
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
- Offline Verification
- Detailed error reporting
- JSON and Markdown diagnostic exports / Device Report

See [docs/TEST_MATRIX.md](docs/TEST_MATRIX.md) for the full matrix.

## Why this project exists

Early reporting around Siri AI and Apple Intelligence availability in the EU created uncertainty about whether the public **Foundation Models** developer framework — and AFM3-class on-device models — would actually be usable on EU iPhones at the developer API layer.

AFM3Tester was built to test the **public APIs on physical hardware** and record what really happens: Availability state, context limits, inference behavior, tool calls, memory, exports, and policy enforcement in the app itself.

This project reports observations. It does not predict future OS behavior, and it does not claim every EU device or release will behave identically.

## Verified environment

These values come from a captured physical-device run documented in [docs/OBSERVED_RESULTS.md](docs/OBSERVED_RESULTS.md):

| Field | Observed value |
| --- | --- |
| Device | iPhone18,2 |
| OS | iOS 27 beta |
| Build observed | 24A5380h |
| Model | `SystemLanguageModel.default` |
| Reported framework description observed | AFM 3 Core Advanced (framework/runtime observation; not a stable public API identifier) |
| Deployment | On-Device |
| Availability | Available |
| Public `contextSize` observed on this device/build | 8192 tokens (runtime SDK property value) |
| Region during test | Sweden |
| App locale during captured test | en_US |

Beta behavior, model descriptions, context limits, and Availability may change without notice.

## Screenshots

No screenshots are included in the initial repository.

Maintainers can add redacted images under [docs/screenshots/](docs/screenshots/). See [docs/SCREENSHOTS.md](docs/SCREENSHOTS.md) for naming conventions and redaction requirements.

The README intentionally avoids image links until those files exist, so there are no broken image references.

## Requirements

- macOS capable of running **Xcode 27**
- **Xcode 27** beta or later compatible release
- **iOS 27** supported physical iPhone for inference testing
- Apple Intelligence / Foundation Models assets downloaded on the device
- **Developer Mode** enabled on the iPhone (for local builds)
- Apple ID added to Xcode (for local builds)
- A valid signing team selected in Xcode (for local builds)
- The iOS Simulator may display the UI, but **cannot execute Foundation Models inference**

Observed simulator failure:

```text
InferenceError::operationNotAllowed::Simulator is not supported
```

You do not need a paid Apple Developer Program membership to inspect UI in Simulator, but device inference testing from source requires normal Xcode signing setup.

## Quick Start

### Install with TestFlight

1. Open https://testflight.apple.com/join/FJMVaGWC on your iPhone.
2. Install AFM3Tester from TestFlight.
3. Wait for Apple Intelligence / Foundation Models assets to finish downloading.
4. On **Overview**, confirm **Availability** and the public `contextSize` value.
5. Tap **Run All Safe Tests** on a physical device.
6. Optionally run **Offline Verification** (Airplane Mode), then **Copy GitHub Device Report**.

### Build from Source

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
12. On **Overview**, confirm framework Availability and the public `contextSize` value.
13. Tap **Run All Safe Tests** on a physical device to exercise inference paths.
14. For Offline Verification, manually enable **Airplane Mode**, disable Wi‑Fi if it remains active, confirm the app reports no satisfied network path, then run **Offline Verification** and export the Device Report.

## Physical device testing checklist

Record these fields when validating on hardware (for example in [docs/OBSERVED_RESULTS.md](docs/OBSERVED_RESULTS.md) or an exported Device Report):

| Field | Why it matters |
| --- | --- |
| Device model | Hardware eligibility varies |
| iOS version and build | Beta behavior changes between builds |
| Region and locale | Availability and language support vary |
| Model Availability | `SystemLanguageModel.default` Availability state |
| Framework description | Any `String(describing:)` or UI label — observation only |
| Basic generation result | Pass / fail / unavailable with exact reflected error |
| Offline Verification result | Whether inference succeeded while no satisfied path was observed |
| Thermal state | May affect throttling during benchmarks |
| Charging state | Battery/charging context for benchmark interpretation |

Simulator builds can compile and display UI, but **Foundation Models inference is unsupported in Simulator**.

## Community Device Reports

1. Run diagnostics on a supported physical iPhone.
2. On **Overview**, **Export**, or **History**, tap **Copy GitHub Device Report**.
3. Open a [Community Device Report](https://github.com/bobbanj/AFM3Tester/issues/new?template=device_report.yml) issue.
4. Paste the Markdown from **Copy GitHub Device Report** and confirm the privacy checkbox (no prompts or credentials).

## Automated tests

Deterministic logic is covered by the **AFM3TesterTests** XCTest target:

```bash
xcodebuild -project AFM3Tester.xcodeproj -scheme AFM3Tester \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=27.0' \
  build-for-testing test-without-building
```

Embedded debug self-tests on the Overview tab (Debug builds only) are interactive diagnostics and are **not** a substitute for XCTest.

## Test suite

| Tab / area | What it proves |
| --- | --- |
| Overview | Device marketing name + hardware ID, Availability, context size, run-all summary, Device Report copy |
| Generate | Interactive basic and streaming generation, temperature, deterministic seed, latency metrics |
| Structured | `@Generable` decoding for meeting summaries and support ticket batches |
| Tools | Read-only tools, deterministic budget tool, Expected Policy Event, authorized side-effect, quoted-content isolation |
| Memory | Same-session recall, fresh-session isolation, in-memory transcript rehydration |
| Languages | Compact generation across five languages with automatic heuristics and manual quality ratings |
| Safety | Benign prompt-injection observations — not a security certification |
| Context | Synthetic long-context recall until context-limit errors |
| Concurrency | Conservative 1 / 2 sequential / 2 concurrent / 4 concurrent probes |
| Benchmark | Three streaming repetitions with median/min/max summaries |
| Offline Verification | Evidence that tested inference paths can run with no active network route |
| History | Local redacted run History and Compare Runs |
| Errors | Unexpected errors plus Expected Policy Events |
| Export | Redacted JSON/Markdown + Device Report |
| About | Version/build, GitHub, TestFlight, environment summary |

### Wording that matters

- A successful **Offline Verification** shows the tested inference path ran while no active network route was available.
- **Safety tests** are behavioral observations, not a security certification.
- An **Expected Policy Event** means the app correctly denied a side effect without permission; it must not be counted as a failed run by itself.
- **Tool-call blocking** demonstrates application policy enforcement, not guaranteed model resistance to prompt injection.
- **Concurrency success** does not prove hardware inference was physically parallel; the framework may serialize work.
- **Character throughput** is not token throughput; estimated tokens/sec are labeled estimates.
- **Beta benchmarks** are not official Apple performance numbers and are not statistically significant.
- **Compare Runs** across different device models shows a visible warning before interpreting percent changes.

More detail: [docs/TEST_MATRIX.md](docs/TEST_MATRIX.md).

## Security model

Model output must never be treated as authorization.

AFM3Tester implements this side-effect gating pattern:

- Read-only tools can run during normal diagnostic flows.
- Side-effect tools require explicit user permission in the UI.
- Quoted or retrieved content does not grant permission.
- Tool arguments are validated deterministically after model generation.
- The **application policy layer**, not the language model, enforces permissions.

During physical-device testing, a quoted instruction caused a side-effect tool-call attempt, and the application correctly blocked the side effect as an **Expected Policy Event**.

Read more: [docs/SECURITY_MODEL.md](docs/SECURITY_MODEL.md).

## Offline Verification

Offline Verification uses `NWPathMonitor` to detect whether any network path is satisfied.

Important:

- The app **cannot** toggle Airplane Mode.
- You must enable Airplane Mode manually.
- Disable Wi‑Fi as well if it remains active.
- Wait for the app to show an offline / no satisfied path state before running Offline Verification.
- After a completed Offline Verification run, **Device Report** and **History** should show the same outcome (including check counts), not “Not Run”.

In the captured physical-device observation, the app reported **Offline (no satisfied path)** and basic generation, structured output, and memory checks succeeded. This establishes only that those tested paths succeeded while the app observed no satisfied network path; it is not absolute proof that every framework or OS path is always offline. See [docs/OBSERVED_RESULTS.md](docs/OBSERVED_RESULTS.md).

## Privacy

AFM3Tester is designed for local diagnostics:

- No analytics
- No telemetry
- No third-party SDKs
- Prompt text is not collected or exported by diagnostic reports
- Redaction attempts to remove email addresses, phone numbers, API keys, tokens, and passwords
- Latency, versions, hardware identifiers, and similar metrics are not treated as phone numbers

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
- Include device, OS build, locale, region, model Availability, and exact reflected errors in bug reports
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
