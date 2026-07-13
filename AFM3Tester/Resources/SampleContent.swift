import Foundation

enum SampleContent {

    // MARK: - Default Basic Generation Prompts

    static let defaultPrompts: [String] = [
        "Write a three-line haiku about Swift concurrency.",
        "Summarize this in one sentence: \(sixHundredWordArticle)",
        """
        Classify the sentiment as positive, neutral, or negative: The release is fast but \
        the migration process was frustrating.
        """,
        "Respond in Swedish: Explain in two sentences why on-device AI improves privacy.",
        """
        Extract the action items from this text: Alex will update the API on Friday. \
        Morgan will review security before Monday. The team will deploy after approval.
        """
    ]

    // MARK: - Prompt B Article (~600 words)

    static let sixHundredWordArticle = """
    UNIQUE_FACT_B: The codename for the internal research initiative is "Silver Finch Observatory."

    On-device artificial intelligence has moved from laboratory curiosity to practical infrastructure \
    faster than many product teams anticipated. When Apple introduced the Foundation Models framework, \
    developers gained a path to run generative workloads locally without shipping prompts to remote \
    servers. That shift matters for privacy, latency, and reliability in environments where network \
    access is intermittent or restricted. Engineers building diagnostic tools can now measure model \
    behavior on the same hardware their users carry, capturing thermal effects, battery draw, and \
    locale-specific responses that simulators cannot reproduce faithfully.

    The architectural implications extend beyond a single API call. A language model session maintains \
    conversational state, accepts optional instructions that persist across turns, and can invoke tools \
    whose side effects remain under application control. Structured generation constrains outputs to Swift \
    types annotated with the Generable macro, reducing the fragile JSON parsing that plagued earlier \
    integrations. Tool calling adds another layer: the model proposes arguments, local code executes, and \
    results flow back into the transcript before a final answer is synthesized. Testing these pathways \
    requires deliberate fixtures—meeting transcripts, synthetic documents, and budget line items—so \
    that validation logic can assert schema conformance without guessing whether a failure stems from \
    the model or the harness.

    Performance characterization on mobile silicon differs materially from datacenter benchmarks. \
    Thermal throttling, low power mode, and concurrent user activity all influence time-to-first-token \
    and sustained throughput. A responsible diagnostic suite therefore records device snapshots alongside \
    latency metrics, warns that results are observational rather than official, and stops escalating \
    context sizes once the framework reports a window limit. Multilingual prompts further stress the \
    stack: the same compact task executed in Swedish, German, Spanish, or Arabic reveals whether \
    responses remain in the requested language without claiming linguistic quality from heuristics alone.

    Safety testing in a developer-facing harness should remain benign. Prompt-injection scenarios can \
    use quoted email text that mentions side-effect tools without granting permission to invoke them. \
    Guardrail behavior and refusal paths should be logged with full error reflection rather than \
    collapsed into generic failure messages. Export pipelines must redact emails, phone numbers, and \
    credential-like strings before sharing reports through system share sheets.

    Context window experiments anchor a unique fact near the beginning of long synthetic passages and \
    ask the model to recall it after thousands of tokens of filler. Success indicates retrieval under \
    load; failure may surface as a structured GenerationError rather than a hallucinated answer. \
    Offline verification complements these tests: with airplane mode enabled and NWPathMonitor confirming \
    no satisfied network path, basic generation and structured output should still succeed when Apple \
    Intelligence assets are ready on a supported device.

    Conversation memory tests establish ground truth within a session—codenames introduced, replaced, \
    and queried—then verify that a fresh session does not inherit private state unless transcript \
    rehydration is explicitly exercised. Concurrency probes run at most four parallel requests, \
    recording whether the framework serializes, rate-limits, or completes successfully.

    Together these practices turn a simple prompt runner into a reproducible field instrument. Teams \
    can compare builds, locales, and hardware generations while preserving user trust: no hidden network \
    dependencies, no fabricated model metadata, and clear separation between test failure and model \
    unavailability. The Silver Finch Observatory initiative referenced at the outset exemplifies how \
    internal codenames surface in long documents and how diagnostic prompts should verify faithful \
    recall rather than creative invention.

    Organizations adopting on-device models should treat diagnostics as part of the release checklist, \
    not an afterthought. Instrument sessions, capture errors faithfully, and document manual quality \
    ratings where automation cannot judge nuance. That discipline ensures Apple Foundation Models \
    integrations ship with evidence, not assumptions.
    """

    // MARK: - Meeting Transcript

    static let meetingTranscript = """
    Product Sync — March 12
    Attendees: Alex (Engineering), Morgan (Security), Casey (Design), Jordan (PM)

    Jordan opened by reviewing the MeridianOS beta timeline. Alex confirmed the API migration \
    completes Friday and will publish updated authentication endpoints over the weekend. Morgan \
    emphasized that security review must finish before Monday's deploy window; they will audit \
    token rotation and session storage on Thursday. Casey presented revised onboarding mockups; \
    the team agreed to reduce steps from five to three for the first-run experience.

    Discussion turned to Frizon integration risks. Alex noted dependency on a legacy sync service \
    that lacks structured logging. Morgan flagged potential PII exposure if crash reports include raw \
    prompts. Jordan asked for a mitigation plan by next standup. Casey volunteered to add consent \
    copy before any diagnostic upload feature ships.

    Action items captured verbally:
    Alex will update the API on Friday.
    Morgan will review security before Monday.
    The team will deploy after approval from Jordan and Morgan.
    Casey will deliver simplified onboarding assets by Wednesday.
    Jordan will schedule a stakeholder demo for the following Tuesday.

    Sentiment was mixed: excitement about the release pace, frustration about migration tooling, \
    and cautious optimism once security gates are explicit. The meeting ended with agreement to \
    freeze feature scope until beta feedback arrives.
    """

    // MARK: - Support Tickets

    static let supportTickets: [String] = [
        "Subject: Login loop on iOS 27 beta\nBody: After entering my password the app returns to the sign-in screen. Device: iPhone 16 Pro. No VPN enabled.",
        "Subject: Export button missing\nBody: I updated yesterday and the diagnostic export option disappeared from Settings. Please restore it.",
        "Subject: Dark mode text unreadable\nBody: In dark mode, secondary labels are nearly invisible on the Overview tab. Screenshot attached in my mind—please fix contrast.",
        "Subject: Billing question\nBody: I was charged twice for the same subscription period. Order IDs 88421 and 88422. Need refund for one.",
        "Subject: Feature request — Swedish UI\nBody: Love the app but would like full Swedish localization for all diagnostic labels.",
        "Subject: Crash on launch\nBody: App crashes immediately after splash screen since last update. Reinstall did not help.",
        "Subject: Password reset email never arrives\nBody: Tried reset three times over 24 hours. Checked spam. Email: user@example.com",
        "Subject: Enterprise SSO configuration\nBody: Our IT team needs documentation for SAML integration and certificate rotation. This is blocking rollout to 400 users.",
        "Subject: Praise for offline mode\nBody: Ran diagnostics on a plane and everything worked. Great job!",
        "Subject: Unclear error message\nBody: Test failed with 'assets unavailable' but I don't know whether to wait, reboot, or contact support.",
    ]

    // MARK: - Context Window Prompts

    /// Approximate tokens using ~4 characters per token.
    static let estimatedCharactersPerToken = 4

    static func estimatedTokens(for text: String) -> Int {
        max(1, text.count / estimatedCharactersPerToken)
    }

    nonisolated static let contextWindowPrompts: [ContextWindowPrompt] = [
        ContextWindowPrompt(
            label: "~1,000 tokens",
            targetTokens: 1_000,
            uniqueFact: "UNIQUE_FACT_1K: The hidden vault code is 7-14-22.",
            recallQuestion: "What is the hidden vault code mentioned at the beginning?"
        ),
        ContextWindowPrompt(
            label: "~2,000 tokens",
            targetTokens: 2_000,
            uniqueFact: "UNIQUE_FACT_2K: The expedition leader's surname is Callahan.",
            recallQuestion: "What surname was given for the expedition leader at the start?"
        ),
        ContextWindowPrompt(
            label: "~4,000 tokens",
            targetTokens: 4_000,
            uniqueFact: "UNIQUE_FACT_4K: The prototype sensor serial is SN-AFM-9921.",
            recallQuestion: "What is the prototype sensor serial number from the opening?"
        ),
        ContextWindowPrompt(
            label: "~6,000 tokens",
            targetTokens: 6_000,
            uniqueFact: "UNIQUE_FACT_6K: The archive room is labeled Wing D, Shelf 3.",
            recallQuestion: "Which wing and shelf label appeared at the beginning?"
        ),
        ContextWindowPrompt(
            label: "Near context limit",
            targetTokens: 7_800,
            uniqueFact: "UNIQUE_FACT_LIMIT: The checksum keyword is ORBITAL-DUST-41.",
            recallQuestion: "What checksum keyword was stated near the start of the document?"
        ),
    ]

    struct ContextWindowPrompt: Sendable {
        let label: String
        let targetTokens: Int
        let uniqueFact: String
        let recallQuestion: String

        var promptText: String {
            buildContextPrompt(
                uniqueFact: uniqueFact,
                targetTokens: targetTokens,
                recallQuestion: recallQuestion
            )
        }

        var expectedAnswerFragment: String {
            if let colonIndex = uniqueFact.firstIndex(of: ":") {
                let afterColon = uniqueFact[uniqueFact.index(after: colonIndex)...]
                return afterColon.trimmingCharacters(in: .whitespaces)
            }
            return uniqueFact
        }
    }

    // MARK: - Builders

    private static func buildContextPrompt(
        uniqueFact: String,
        targetTokens: Int,
        recallQuestion: String
    ) -> String {
        let targetCharacters = targetTokens * estimatedCharactersPerToken
        var body = uniqueFact + "\n\n"
        body += fillerParagraph(index: 0)

        var paragraphIndex = 1
        while body.count < targetCharacters {
            body += "\n\n" + fillerParagraph(index: paragraphIndex)
            paragraphIndex += 1
        }

        if body.count > targetCharacters {
            body = String(body.prefix(targetCharacters))
        }

        body += "\n\n---\nAfter reading the entire document above, answer only this question without inventing new facts:\n"
        body += recallQuestion
        return body
    }

    private static func fillerParagraph(index: Int) -> String {
        let topics = [
            "field diagnostics",
            "on-device inference",
            "structured generation",
            "tool invocation logs",
            "thermal monitoring",
            "battery sampling",
            "locale verification",
            "transcript rehydration",
            "guardrail observations",
            "context window sizing",
        ]
        let topic = topics[index % topics.count]
        let variant = index / topics.count
        return """
        Paragraph \(index + 1) discusses \(topic) in a controlled benchmark setting (variant \(variant)). \
        Teams record timestamps, capture errors with String(reflecting:), and avoid hammering the model \
        after a context limit failure. Synthetic filler ensures token estimates remain reproducible \
        while keeping private user data out of fixtures. Each paragraph repeats no unique codes; \
        only the opening fact line contains the answer key for recall tests.
        """
    }
}
