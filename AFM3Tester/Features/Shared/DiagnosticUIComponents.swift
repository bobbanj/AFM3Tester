import SwiftUI

struct OutcomeBadge: View {
    let outcome: TestOutcome

    var body: some View {
        Text(outcome.displayLabel)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2), in: Capsule())
            .foregroundStyle(color)
    }

    private var color: Color {
        switch outcome {
        case .passed: .green
        case .expectedPolicyBlock: .teal
        case .partial: .yellow
        case .failed: .red
        case .unavailable: .orange
        case .skipped: .gray
        case .observation: .blue
        }
    }
}

struct OverallStatusBadge: View {
    let status: OverallRunStatus

    var body: some View {
        Text(status.displayLabel)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2), in: Capsule())
            .foregroundStyle(color)
    }

    private var color: Color {
        switch status {
        case .passed: .green
        case .expectedPolicyBlock: .teal
        case .partial: .yellow
        case .failed: .red
        case .unavailable: .orange
        case .skipped: .gray
        }
    }
}

struct TestResultCard: View {
    let result: TestResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.testName)
                    .font(.headline)
                Spacer()
                OutcomeBadge(outcome: result.outcome)
            }
            if let message = result.message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let latency = result.latency {
                LatencyMetricsView(metrics: latency)
            }
            if !result.validationChecks.isEmpty {
                ValidationChecksView(checks: result.validationChecks)
            }
            if let rawError = result.rawError {
                Text(rawError)
                    .font(.caption.monospaced())
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct LatencyMetricsView: View {
    let metrics: LatencyMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let session = metrics.sessionCreationSeconds {
                metricRow("Session creation", String(format: "%.3fs", session))
            }
            if let ttft = metrics.timeToFirstTokenSeconds {
                metricRow("Time to first token", String(format: "%.3fs", ttft))
            }
            if let total = metrics.totalGenerationSeconds {
                metricRow("Total generation", String(format: "%.3fs", total))
            }
            if let cps = metrics.charactersPerSecond {
                metricRow("Characters/sec", String(format: "%.1f", cps))
            }
            if let input = metrics.inputCharacterCount {
                metricRow("Input chars", "\(input)")
            }
            if let output = metrics.outputCharacterCount {
                metricRow("Output chars", "\(output)")
            }
        }
        .font(.caption)
    }

    private func metricRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
    }
}

struct ValidationChecksView: View {
    let checks: [ValidationCheck]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Validation")
                .font(.caption.weight(.semibold))
            ForEach(checks) { check in
                HStack(alignment: .top) {
                    Image(systemName: check.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(check.passed ? .green : .red)
                    VStack(alignment: .leading) {
                        Text(check.name)
                        if let detail = check.detail {
                            Text(detail)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .font(.caption)
            }
        }
    }
}

struct RunTestButton: View {
    let title: String
    let isRunning: Bool
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.borderedProminent)
            .disabled(isRunning)
    }
}

struct DiagnosticScrollScreen<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                content
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .frame(width: 140, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
    }
}
