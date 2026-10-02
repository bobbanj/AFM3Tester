# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.3.0] - Unreleased (AFM3 Toolbox)

### Added

- AFM3 Score for fixed suite `afm3-score-suite-1`: composite geometric mean plus Latency, Throughput, Responsiveness, and Capability sub-scores
- Local toplist built from History, with a this-device filter and a separate section for other suite versions
- Redacted score card Markdown (`Copy Score Card`) with no prompts and no upload
- Compare Runs states whether two scores are the same device and the same suite version before showing a percent change
- Tips & tricks for Airplane Mode, assets download, Simulator inference, Expected Policy Events, thermal/charging, and the Device Report paste flow
- Lab tab that keeps Generate, Structured, Tools, Memory, Languages, Safety, Context, Concurrency, Benchmark, Offline, Overview, Errors, and Export
- `docs/APP_STORE_READINESS.md` listing owner-provided gaps for a real App Store submission

### Changed

- Marketing version `0.3.0` (build `5`); home screen name AFM3 Toolbox
- History schema v4 stores an optional AFM3 Score snapshot. Older records still decode, and a missing snapshot is derived at read time
- Tab bar is Score, Toplist, Lab, History, Tips, and About
- README positioning describes AFM3Tester as an on-device AFM3 Toolbox

### Notes

- The score is a local calibration against documented baselines (1000). It is not an Apple score and it is not statistically significant
- Offline Verification stays in Lab and is not part of the score suite
- The toplist is local-only. An online leaderboard is out of scope
- Expected Policy Events still do not count as Errors or as failed capability members

## [0.2.2] - Release polish

### Fixed

- Device Report Offline-path observation no longer reports “Not Run” after Offline Verification completed in the UI
- Offline Verification now persists into History immediately after the suite finishes
- Offline observation label includes check counts and NWPathMonitor evidence wording when available

### Changed

- History schema v3 stores offline check counts and completion timestamp (older records still decode)
- Marketing version set to `0.2.2` (build `4`)

### Documentation

- README release polish: badges, Try AFM3Tester, TestFlight section, Quick Start split, What’s New in 0.2.2
- Community Device Report issue template emphasizes **Copy GitHub Device Report**
- Terminology pass: Foundation Models, SystemLanguageModel, On-Device, Availability, Expected Policy Event, Offline Verification, Device Report, History, Compare Runs

## [0.2.1] - Unreleased (polish)

### Fixed

- Offline structured-output validation now uses the same FoundationModels guided generation + schema decoding path as the Structured tab (no wording/owner comparison)
- Export redaction no longer misclassifies latency/benchmark/version/hardware numeric spans as phone numbers
- Context Window runs last in Run All and always uses fresh sessions to avoid contaminating later suites
- Expected policy denials (`sideEffectsNotAllowed`, quoted tool-call blocks) are recorded as Expected Policy Events, not Errors

### Added

- `partial` suite / overall status for incomplete but non-failing verification (e.g. offline 3/4 checks)
- About screen with version/build, GitHub, TestFlight, MIT license, privacy statement, and Copy Environment Summary
- History schema v2 `policyEventSummaries` (older records decode with empty policy events)

### Changed

- Demo project fixtures use generic fictional names (Project Atlas / Project Orion / Sample Workspace)
- Diagnostic export and GitHub device report separate Errors from Expected Policy Events
- Benchmark UI separates current samples from historical session records
- Marketing version set to `0.2.1` (build `3`)

## [0.2.0] - Unreleased (beta)

### Added

- Explicit `expectedPolicyBlock` test outcome for intentional side-effect denials
- Deterministic overall run-status aggregation (passed / expected policy block / failed / unavailable / skipped)
- Local diagnostic run history (Application Support JSON, schema v1, retention default 50)
- History tab with run detail, delete one / delete all
- Side-by-side run comparison (suite status deltas, latency metrics, cross-device warning)
- Deterministic hardware-identifier → marketing-name resolver
- “Copy GitHub Device Report” Markdown export (redacted, no prompts)
- GitHub issue template for community device reports
- Benchmark median / min / max summaries and estimated tokens/sec (labeled estimate)
- XCTest coverage for policy classification, history, comparison, resolver, and benchmarks

### Changed

- Tool Calling suite treats `DemoThemeError.sideEffectsNotAllowed` as expected policy enforcement, not suite failure
- Authorized demo-theme side-effect path is tested separately after explicit permission
- Overview shows marketing name + hardware identifier and last-run overall summary
- Marketing version set to `0.2.0` (build `2`)

### Notes

- History is local-only: no iCloud, no network, no prompt storage
- Comparison does not claim statistical significance
- On-device Foundation Models inference still requires a physical supported iPhone

## [Unreleased]

### Added

- Initial public diagnostic suite
- On-device Foundation Models availability inspection
- Basic and streaming generation
- Structured output
- Tool calling
- Explicit side-effect permission gating
- Conversation memory and transcript rehydration
- Multilingual tests
- Safety observations
- Context testing
- Concurrency testing
- Performance benchmarks
- Offline verification
- Error explorer
- Diagnostic report export
- Embedded unit self-tests
