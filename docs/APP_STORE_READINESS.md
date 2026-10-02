# App Store readiness

This note lists concrete gaps between the current AFM3Tester 0.3 tree and a real App Store submission. It is an engineering checklist for the owner. It is not legal advice, not a privacy policy, and not App Review guidance copied from Apple.

Owner: Robert Jakobsson.

The app is an on-device AFM3 Toolbox. It talks to `SystemLanguageModel` only. It has no other model provider, no cloud inference, no analytics SDK, and no telemetry SDK. The toplist is local History. None of that removes the App Store Connect forms below.

## Owner must provide

These items are not in the repository. Do not treat placeholders in the app or in this file as substitutes.

| Gap | Why it blocks submission | What the owner provides |
| --- | --- | --- |
| Privacy Policy URL | App Store Connect requires a privacy policy URL for apps on the store | A public URL whose text the owner writes or commissions. This repository does not contain that text |
| Support URL | Required metadata | A URL the owner controls, with a contact path that is not invented here |
| Marketing description, subtitle, keywords, promotional text | Metadata is not generated from the README | Final copy, including the AFM3 Toolbox positioning the owner wants reviewers to see |
| Screenshots and app preview | The repo intentionally has no README screenshots until redacted captures exist. See [SCREENSHOTS.md](SCREENSHOTS.md) and [RELEASE_SCREENSHOT_CHECKLIST.md](RELEASE_SCREENSHOT_CHECKLIST.md) | Real device captures for the required iPhone sizes. Do not ship fabricated UI |
| Age rating answers | The questionnaire is completed in App Store Connect | The owner's answers. The app has no ads, no user accounts, and no social features in this tree; the owner still has to submit the form |
| Export compliance answer | Every build uploaded to App Store Connect asks about encryption | The owner's answer. See the section below. This file does not set `ITSAppUsesNonExemptEncryption` |
| Copyright and trade name line | Metadata field | The owner’s legal name or entity string |
| App Review account / demo notes | Reviewers cannot infer on Simulator | Notes that say Foundation Models needs a physical iPhone on a supported iOS 27 build, with assets downloaded. See below |
| Signing identity | The project has an empty development team and bundle id `com.example.AFM3Tester` | A real Apple Developer Program team, a non-example bundle id, and distribution signing |

## Privacy nutrition labels

App Store Connect asks the owner to declare data collection. This tree is built so the app does not phone home:

- No analytics or telemetry SDK
- No account system
- No score upload. Toplist rows are `DiagnosticRunRecord` values in Application Support
- Score cards and Device Reports are copied only when the user taps copy or share
- Prompts are not stored in History

The owner still has to fill the nutrition label form. A local-only design is not a completed label. If a later build adds an online leaderboard, crash reporting, or a network SDK, the label and this checklist both change. That online board is out of scope for 0.3.

Also decide whether a privacy manifest (`PrivacyInfo.xcprivacy`) is required for the APIs this target actually calls before upload. Apple’s required-reason API list changes. Audit the shipping binary rather than assuming the current sources are exempt. Do not add a manifest that claims “no data collected” until that audit is done.

## Export compliance

The app does not implement its own encryption and does not ship a custom crypto library. It can open `https://` URLs in Safari or TestFlight links through the system. HTTPS provided by the operating system is a common reason builds qualify for the standard exemption, but the owner has to answer Apple’s export questionnaire for the binary that is uploaded.

This repository does not set an encryption entitlement or `ITSAppUsesNonExemptEncryption`. Set that only after the owner’s answer is known.

## Foundation Models, iOS version, and review notes

Suggested facts to put in App Review notes, in the owner’s words:

- Inference uses the public Foundation Models framework and `SystemLanguageModel` on device
- The deployment target is iOS 27. Review hardware must be a supported physical iPhone with Apple Intelligence assets downloaded. Availability is a device, region, and OS-build property, not something the app can force
- The iOS Simulator can display the UI. It cannot run inference. A simulator run is not a failed score
- Expected Policy Events are intentional side-effect denials. They are not crashes. See [SECURITY_MODEL.md](SECURITY_MODEL.md)
- There is no login. There is no demo account to provide
- TestFlight builds may be ahead of the latest tagged GitHub release

Do not promise that every review device in every region will report Available.

## TestFlight versus App Store

| | TestFlight | App Store |
| --- | --- | --- |
| Current public link | https://testflight.apple.com/join/FJMVaGWC | Not submitted by this tree |
| Audience | Testers who opt in | Public store listing after review |
| Signing | Distribution via the owner’s team | App Store distribution, not the empty development team in the project |
| Version | TestFlight can carry a newer build than GitHub | Marketing version in this tree is 0.3.0, build 5 |
| Review | Beta review, lighter metadata | Full metadata, privacy policy URL, screenshots, age rating, export compliance |

Shipping 0.3 to TestFlight does not close the App Store gaps in this document.

## Signing and App Store Connect checklist

- [ ] Apple Developer Program membership active for the owner
- [ ] Replace `com.example.AFM3Tester` with the owner’s bundle id on the app target
- [ ] Set `DEVELOPMENT_TEAM` for the app and test targets
- [ ] Create the App Store Connect record for that bundle id
- [ ] Confirm the display name **AFM3 Toolbox** and the version **0.3.0** (build **5** or the build that is actually uploaded)
- [ ] Archive with a Distribution certificate and an App Store provisioning profile
- [ ] Upload with Xcode or Transporter
- [ ] Answer export compliance for that build
- [ ] Attach the privacy policy URL and support URL
- [ ] Complete privacy nutrition labels
- [ ] Complete the age rating questionnaire
- [ ] Upload real screenshots and the rest of the metadata
- [ ] Paste review notes about Foundation Models, iOS 27, and physical devices
- [ ] Confirm the binary contains no third-party analytics SDK
- [ ] Keep side-effect tool permission gating unchanged from [SECURITY_MODEL.md](SECURITY_MODEL.md)

## Still true in this source tree

- On-device `SystemLanguageModel` only
- Local History and local toplist
- Redacted score card and Device Report, with prompts omitted
- No fabricated screenshots in the README
