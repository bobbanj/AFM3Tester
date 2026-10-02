# Test Matrix

This matrix describes the diagnostic areas implemented in AFM3Tester as of the initial public release.

| Test | Purpose | Automatic / Manual | Requires physical device | Requires network | Expected result | Limitations |
| --- | --- | --- | --- | --- | --- | --- |
| Overview metadata | Show OS, locale, model availability, context size | Automatic display | Recommended | No | Current device and model state shown | Model description strings are observations, not stable API identifiers |
| Run All Safe Tests | Execute non-destructive suites sequentially | Automatic | Yes | No for inference itself | Combined pass/fail/unavailable results | Does not replace focused manual review |
| Basic generation | Prompt/instructions, temperature, seed, streaming | Manual + automatic metrics | Yes | No | Text response or exact reflected error | Character throughput is not token throughput |
| Default prompt set A–E | Cover haiku, summary, sentiment, Swedish, action items | Manual selection | Yes | No | Responses vary by model/assets | Not a regression benchmark |
| Structured meeting summary | `@Generable` `MeetingSummary` from transcript | Automatic | Yes | No | Decoded struct passes validation checks | Validation checks schema/logic, not business correctness |
| Support ticket batch | Ten `@Generable` classifications | Automatic | Yes | No | Ten schema-conforming outputs | Does not verify semantic ticket quality |
| Tool: project status | Model should use `getProjectStatus` | Automatic | Yes | No | Tool invocation or equivalent answer content | Model may answer without tool on some builds |
| Tool: budget | Model should use `calculateBudget` | Automatic | Yes | No | Tool invocation or correct total | Same as above |
| Tool: unauthorized side effect | Deny `setDemoTheme` without permission | Automatic | Yes | No | **Expected policy block** (not failed) | Policy must remain enforced |
| Tool: authorized side effect | Explicit theme change after permission | Automatic + UI toggle | Yes | No | Theme changes when permitted | Demonstrates app policy, not model resistance |
| Tool injection observation | Quoted text must not authorize theme change | Automatic | Yes | No | No side-effect without permission | Policy enforcement, not security certification |
| Conversation memory | Same-session recall of codename | Automatic | Yes | No | Aurora then Borealis recalled | Wording checks are heuristic |
| Fresh session isolation | New session should not recall codename | Automatic | Yes | No | No prior codename leaked | Heuristic string match |
| Transcript rehydration | Rehydrated session recalls Borealis | Automatic | Yes | No | Rehydrated session succeeds | In-memory only; not persisted to disk |
| Multilingual EN/SV/DE/ES/AR | Compact generation in five languages | Automatic checks + manual rating | Yes | No | Non-empty, length-bounded outputs | Automatic checks do not judge linguistic quality |
| Safety observations | Benign prompt-injection scenarios | Automatic observations | Yes | No | Logged behavior notes | Not a security certification |
| Context window ladder | Recall unique fact at increasing sizes | Automatic | Yes | No | Fact recall until context error | Token counts may be estimated |
| Concurrency 1/2/2/4 | Conservative parallel request probe | Automatic | Yes | No | At least some successes recorded | Framework may serialize; not proof of hardware parallelism |
| Benchmark (3 reps) | Streaming latency and device state | Automatic | Yes | No | Median/min/max + thermal/battery | Beta observations only; not statistically significant |
| Offline verification | Inference with no satisfied network path | Manual Airplane Mode + automatic tests | Yes | Must be offline during test | Basic, structured, memory pass while offline | App cannot enable Airplane Mode; Wi‑Fi must be off too |
| AFM3 Score | Composite and sub-scores from fixed suite `afm3-score-suite-1` | Automatic after Run AFM3 Score | Yes | No | Complete score when every required suite passed and the benchmark produced metrics | Calibration baseline 1000. Not an Apple score. Not statistically significant. Offline Verification is excluded |
| Toplist | Rank complete History scores for the current suite version | Automatic from History | No | No | This device by default; other suite versions listed apart | Local only. No upload |
| Tips | Bundled Airplane Mode, assets, Simulator, policy, thermal, and Device Report notes | Manual reading | No | No | Offline content matches the in-app catalog | Not downloaded |
| History / compare | Local redacted run storage and deltas | Manual | No | No | Newest-first history; compare two runs | No prompts stored. AFM3 Score percent only for the same device and same suite version |
| Error explorer | Preserve full reflected errors | Automatic logging | No for UI; yes for model errors | No | Detailed categorized log | Logs may contain sensitive model output |
| Export JSON/Markdown | Share redacted diagnostic report | Manual | No | No | Share sheet export | User must review before publishing |
| GitHub device report | Concise community Markdown | Manual copy | No | No | Redacted observation paste | No prompts/credentials |
| Embedded unit self-tests | Redaction, validation, tools, gating (Debug UI only) | Manual (Debug) | No | No | Interactive checks pass | Does not test live model inference; not a substitute for XCTest |
| XCTest (`AFM3TesterTests`) | Deterministic redaction, validation, tools, history, compare, export | Automatic (`xcodebuild test`) | No | No | Unit tests pass in CI/simulator | Does not test live Foundation Models inference |

## Result semantics

| Outcome | Meaning |
| --- | --- |
| Passed | Test logic succeeded on an available model |
| Expected policy block | Intentional side-effect denial without permission; not a failure |
| Partial | Some checks passed; incomplete verification (e.g. offline 3/4) without a hard failure |
| Failed | Unexpected test logic or inference failure while model was available |
| Unavailable | Model/assets/device prerequisites not met |
| Skipped | Preconditions missing, such as network still online for offline test |
| Observation | Behavioral note, especially in safety suite |

### Overall run aggregation

1. Any failed suite → overall **Failed**
2. Else all meaningful suites unavailable → overall **Unavailable**
3. Else mixed unavailable + success → overall **Failed** (not a successful run)
4. Else any partial → overall **Partial**
5. Else any passed → overall **Passed**
6. Else any expected policy block → overall **Expected policy block**
7. Else only skipped/observation → overall **Skipped**

## Physical device requirement

Foundation Models inference is **not supported in the iOS Simulator**. UI inspection can occur in Simulator; all inference rows marked “Requires physical device: Yes” expect a supported iPhone with Apple Intelligence assets ready.

## Offline evidence wording

A successful offline test provides evidence that the tested inference path ran while **no active network route was available**. It does not prove all future OS builds, locales, or devices will behave identically.
