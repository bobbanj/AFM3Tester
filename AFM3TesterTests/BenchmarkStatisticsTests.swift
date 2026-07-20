import XCTest
@testable import AFM3Tester

@MainActor
final class BenchmarkStatisticsTests: XCTestCase {
    func testMedianOddAndEven() {
        XCTAssertEqual(BenchmarkStatistics.median(of: [1, 3, 2]), 2)
        XCTAssertEqual(BenchmarkStatistics.median(of: [1, 2, 3, 4]), 2.5)
        XCTAssertNil(BenchmarkStatistics.median(of: []))
    }

    func testSummarizeMinMaxMedian() {
        let samples = [
            makeSample(total: 1.0, first: 0.2, cps: 10),
            makeSample(total: 3.0, first: 0.4, cps: 30),
            makeSample(total: 2.0, first: 0.6, cps: 20),
        ]
        let summary = BenchmarkStatistics.summarize(
            samples: samples,
            thermalBefore: "nominal",
            thermalAfter: "fair",
            batteryBefore: 0.9,
            batteryAfter: 0.85
        )
        XCTAssertEqual(summary.sampleCount, 3)
        XCTAssertEqual(summary.medianTotalLatencySeconds, 2.0)
        XCTAssertEqual(summary.minTotalLatencySeconds, 1.0)
        XCTAssertEqual(summary.maxTotalLatencySeconds, 3.0)
        XCTAssertEqual(summary.medianTimeToFirstStreamedContentSeconds, 0.4)
        XCTAssertEqual(summary.minTimeToFirstStreamedContentSeconds, 0.2)
        XCTAssertEqual(summary.maxTimeToFirstStreamedContentSeconds, 0.6)
        XCTAssertEqual(summary.medianCharactersPerSecond, 20)
        XCTAssertEqual(summary.estimatedMedianTokensPerSecond, 5)
        XCTAssertEqual(summary.thermalStateBefore, "nominal")
        XCTAssertEqual(summary.thermalStateAfter, "fair")
    }

    private func makeSample(total: Double, first: Double, cps: Double) -> BenchmarkSample {
        BenchmarkSample(
            testName: "Performance Benchmark",
            repetition: 1,
            latency: LatencyMetrics(
                sessionCreationSeconds: nil,
                timeToFirstTokenSeconds: first,
                totalGenerationSeconds: total,
                charactersPerSecond: cps,
                inputCharacterCount: 10,
                outputCharacterCount: Int(cps * total)
            ),
            thermalState: "nominal",
            batteryLevel: 0.8,
            isLowPowerModeEnabled: false,
            isCharging: true
        )
    }
}
