# Security Policy

## Supported versions

| Version | Supported |
| --- | --- |
| Latest `main` branch | Yes |
| Latest tagged release | Yes |
| Older tags or forks | No |

Only the latest `main` branch and the latest tagged release receive security fixes initially.

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security vulnerabilities involving:

- Permission bypass for side-effect tools
- Unsafe tool execution
- Unintended prompt or transcript export
- Report redaction failure
- Hidden or unintended network use
- Use of undocumented entitlements or private APIs

Instead:

1. Use **GitHub Private Vulnerability Reporting** if it is enabled for this repository.
2. If private vulnerability reporting is not enabled, contact the maintainers through a private channel listed in the repository profile.

Include:

- A clear description of the issue
- Steps to reproduce
- Impact on user data, permissions, exports, or network behavior
- Affected app version or commit
- Device and OS context if relevant

We aim to acknowledge reports in a reasonable timeframe. Please allow time for investigation on beta OS and framework behavior.

## In scope

Examples of security issues relevant to this repository:

- Side-effect permission bypass (`setDemoTheme` or future side-effect tools)
- Tool argument validation bypass that allows unintended actions
- Prompt or transcript leakage through exports, logs, or persistence
- Failure to redact sensitive exported data when redaction is expected
- Hidden network requests or unexpected outbound connections
- Use of undocumented or private entitlements/APIs
- Unsafe persistence of prompts or transcripts to disk without explicit user intent

## Out of scope

The following are generally **not** treated as application vulnerabilities in this repository:

- Model jailbreaks or undesirable model text without an application-level security impact
- Guardrail behavior inside Apple’s on-device model
- Prompt-injection resistance of the model itself
- Benchmark variance, latency differences, or linguistic quality
- Simulator inference failures (`operationNotAllowed`) when running on simulator

AFM3Tester documents model behavior, but the **application policy layer** is responsible for permissions, validation, and exports.

## Security model reference

See [docs/SECURITY_MODEL.md](docs/SECURITY_MODEL.md) for the project’s tool permission and untrusted-model design.

## Safe harbor

Good-faith security research that follows this policy and avoids privacy violations, data destruction, or disruption to other users is appreciated.
