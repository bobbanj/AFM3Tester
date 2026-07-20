# Observed Results

This document records **observed** results from beta software on a specific device and environment. These results are not universal guarantees and may change with OS builds, device hardware, locale, region, asset downloads, or framework updates.

## Test environment

| Field | Observed value |
| --- | --- |
| Device | iPhone18,2 |
| OS | iOS 27.0 beta |
| Build | 24A5380h |
| Region of physical testing | Sweden |
| App locale captured | en_US |
| Model API used | `SystemLanguageModel.default` |
| Diagnostic framework description observed | AFM 3 Core Advanced (runtime/framework observation on this device; not a stable public API identifier) |
| Deployment observed | On-device |
| Public `contextSize` observed on this device/build | 8192 tokens (runtime value from public SDK `contextSize` property) |

## Availability and model metadata

- `SystemLanguageModel.default` reported **Available** during the captured run.
- The app displayed on-device deployment based on the public `SystemLanguageModel` API.
- No stable public model identifier beyond `SystemLanguageModel.default` was exposed by the SDK in this project.

## Inference and diagnostics observed

| Area | Observed result |
| --- | --- |
| Basic generation | Succeeded |
| Structured generation | Succeeded |
| Tool calling | Succeeded |
| Conversation memory | Succeeded |
| Transcript rehydration | Succeeded |
| English generation | Succeeded |
| Swedish generation | Succeeded |
| German generation | Succeeded |
| Spanish generation | Succeeded |
| Arabic generation | Succeeded |
| Conservative concurrency suite | 9 succeeded, 0 failed |
| Thermal state during short concurrency test | Remained nominal |
| Prompt-injection observation | Quoted instruction caused a side-effect tool-call attempt; application policy blocked the side effect |

## Simulator observation

Running inference in the iOS Simulator produced an unsupported-environment result consistent with:

```text
InferenceError::operationNotAllowed::Simulator is not supported
```

This matches the project’s documented expectation that simulator inference is unsupported.

## Not observed in the captured run

The following were **not** recorded as passed in the captured evidence set used for this document:

- Offline verification with Airplane Mode and no satisfied network path

If you perform offline verification successfully, consider adding a redacted entry here with device, build, and network-path status.

## Interpretation notes

- **Concurrency success** does not prove hardware-level parallel inference; the framework may serialize requests internally.
- **Character throughput** reported by the app is not token throughput; estimated tokens/sec are labeled estimates.
- **Safety observations** are behavioral notes, not a security certification.
- **Expected policy block** for unauthorized `setDemoTheme` is correct application enforcement, not a failed tool suite.
- **Model description strings** such as “AFM 3 Core Advanced” are diagnostic observations and should not be treated as stable API identifiers.
- **Beta behavior** may differ on other devices, regions, locales, or later builds.
- **v0.2 local history / comparison** features were not part of the original captured evidence set; re-run on device to populate history.

## How to extend this document

When adding new observations:

1. Include device model, OS version, OS build, locale, and region.
2. Distinguish unavailable vs failed vs passed.
3. Paste exact reflected errors for failures.
4. Redact private prompts, credentials, and personal data.
5. Phrase results as observations, not guarantees.
