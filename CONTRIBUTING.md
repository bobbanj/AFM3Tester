# Contributing to AFM3Tester

Thank you for your interest in improving AFM3Tester. This project is a diagnostic harness for Apple’s public Foundation Models framework. Contributions should preserve that scope.

## Development prerequisites

- macOS capable of running **Xcode 27**
- **Xcode 27** beta or a later compatible release
- A supported **physical iPhone** running **iOS 27** for inference-related changes
- Apple Intelligence assets downloaded on the test device
- Developer Mode enabled on the iPhone
- An Apple ID added to Xcode and a valid signing team for device builds

The iOS Simulator can be used to inspect UI layout, but **Foundation Models inference is unsupported in the simulator**.

## Getting started locally

1. Fork and clone the repository.
2. Open `AFM3Tester.xcodeproj`.
3. Select the **AFM3Tester** target.
4. In **Signing & Capabilities**, choose your own team and set a unique bundle identifier.
5. Build for a physical device when testing model behavior.

## Branch workflow

1. Create a branch from `main`:

   ```bash
   git checkout -b feature/short-description
   ```

2. Keep changes focused and deterministic where practical.
3. Open a pull request against `main`.

For substantial changes, open an issue first so maintainers can agree on scope.

## Coding style

- **Swift 6** with **strict concurrency** enabled
- Match existing project structure and naming
- Prefer small, focused diffs
- Avoid force unwraps in new code
- Avoid `fatalError` in new code
- Do not add large copyright headers to individual Swift files unless the project already uses them consistently

## Project constraints

Please do **not** introduce:

- Third-party analytics or telemetry
- Crash reporting SDKs
- Network-backed model providers
- Private or undocumented Apple APIs
- Hidden network requests
- New external package dependencies unless there is a strong, reviewed reason

AFM3Tester is intentionally dependency-free beyond Apple system frameworks.

## Testing

### XCTest (`AFM3TesterTests`)

Canonical automated coverage lives in the **AFM3TesterTests** XCTest target. Run:

```bash
xcodebuild -project AFM3Tester.xcodeproj -scheme AFM3Tester -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build-for-testing test-without-building
```

These tests cover deterministic logic only (redaction, validation, local tools, side-effect gating, export serialization, offline evidence records). They do **not** execute Foundation Models inference.

### Embedded debug self-tests

In **Debug** builds, the **Overview** tab also exposes **Embedded Unit Self-Tests** as an interactive diagnostic convenience. These are **not** a substitute for XCTest and do not replace CI coverage.

### Community device reports

If you want to share observations without a code change:

1. Run AFM3Tester on a supported physical iPhone.
2. Use **Copy GitHub Device Report** (Overview or Export).
3. Open a Community Device Report issue and paste the Markdown.
4. Confirm the privacy checkbox — never include prompts or credentials.

### Physical device testing

Inference-related changes should be verified on a supported physical iPhone with Apple Intelligence enabled. Include in your PR notes:

- Device model identifier
- iOS version and build
- Locale and region
- Model availability state
- Exact reflected error output when failures occur

Do **not** upload private prompts, credentials, or personal data in issues or PRs.

## Issue reports

When filing a bug, include:

- Device model
- iOS version and build
- Xcode version
- Locale and region
- Model availability state
- Network, charging, Low Power Mode, and thermal state if relevant
- Whether the test used simulator or physical device
- Exact reflected error text from the Error Explorer when applicable
- Reproduction steps

Use the bug report issue form when possible.

## Pull request checklist

Before requesting review, confirm:

- [ ] Builds with the supported Xcode version
- [ ] Tested on a physical device where relevant
- [ ] No private APIs added
- [ ] No new network dependency added
- [ ] No secrets, credentials, or personal data included
- [ ] Swift concurrency warnings resolved
- [ ] `AFM3TesterTests` updated when deterministic behavior changes
- [ ] Embedded debug self-tests updated when interactive diagnostic behavior changes
- [ ] README or docs updated if user-visible behavior changed
- [ ] Security implications considered
- [ ] Tool side effects remain explicitly gated

## Documentation

If you add a new diagnostic test or change export behavior, update:

- `README.md`
- `docs/TEST_MATRIX.md`
- `docs/ARCHITECTURE.md` when structure changes
- `CHANGELOG.md` under `[Unreleased]`

## Code of conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). Please read it before participating.
