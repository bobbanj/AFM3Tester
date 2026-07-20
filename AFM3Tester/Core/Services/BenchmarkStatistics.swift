import Foundation

struct BenchmarkSummary: Codable, Sendable, Hashable {
    let sampleCount: Int
    let medianTotalLatencySeconds: Double?
    let minTotalLatencySeconds: Double?
    let maxTotalLatencySeconds: Double?
    let medianTimeToFirstStreamedContentSeconds: Double?
    let minTimeToFirstStreamedContentSeconds: Double?
    let maxTimeToFirstStreamedContentSeconds: Double?
    let medianCharactersPerSecond: Double?
    /// Estimated tokens/sec using ~4 characters per token. Labeled as estimate only.
    let estimatedMedianTokensPerSecond: Double?
    let thermalStateBefore: String?
    let thermalStateAfter: String?
    let batteryPercentageBefore: Double?
    let batteryPercentageAfter: Double?
    let isCharging: Bool?
    let isLowPowerModeEnabled: Bool?

    nonisolated static let charactersPerEstimatedToken = 4.0
}

enum BenchmarkStatistics: Sendable {

    nonisolated static func median(of values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[mid - 1] + sorted[mid]) / 2.0
        }
        return sorted[mid]
    }

    nonisolated static func summarize(
        samples: [BenchmarkSample],
        thermalBefore: String? = nil,
        thermalAfter: String? = nil,
        batteryBefore: Double? = nil,
        batteryAfter: Double? = nil
    ) -> BenchmarkSummary {
        let totals = samples.compactMap(\.latency.totalGenerationSeconds)
        let firsts = samples.compactMap(\.latency.timeToFirstTokenSeconds)
        let cps = samples.compactMap(\.latency.charactersPerSecond)
        let medianCPS = median(of: cps)
        let estimatedTPS = medianCPS.map { $0 / charactersPerEstimatedToken }

        let last = samples.last
        return BenchmarkSummary(
            sampleCount: samples.count,
            medianTotalLatencySeconds: median(of: totals),
            minTotalLatencySeconds: totals.min(),
            maxTotalLatencySeconds: totals.max(),
            medianTimeToFirstStreamedContentSeconds: median(of: firsts),
            minTimeToFirstStreamedContentSeconds: firsts.min(),
            maxTimeToFirstStreamedContentSeconds: firsts.max(),
            medianCharactersPerSecond: medianCPS,
            estimatedMedianTokensPerSecond: estimatedTPS,
            thermalStateBefore: thermalBefore ?? samples.first?.thermalState,
            thermalStateAfter: thermalAfter ?? last?.thermalState,
            batteryPercentageBefore: batteryBefore.map { $0 * 100 } ?? samples.first?.batteryLevel.map { $0 * 100 },
            batteryPercentageAfter: batteryAfter.map { $0 * 100 } ?? last?.batteryLevel.map { $0 * 100 },
            isCharging: last?.isCharging,
            isLowPowerModeEnabled: last?.isLowPowerModeEnabled
        )
    }

    private nonisolated static var charactersPerEstimatedToken: Double {
        BenchmarkSummary.charactersPerEstimatedToken
    }
}
