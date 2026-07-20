import XCTest
@testable import AFM3Tester

@MainActor
final class DeviceMarketingNameResolverTests: XCTestCase {
    func testKnownIdentifierResolves() {
        XCTAssertEqual(
            DeviceMarketingNameResolver.marketingName(forHardwareIdentifier: "iPhone18,2"),
            "iPhone 17 Pro Max"
        )
    }

    func testUnknownIdentifierFallback() {
        XCTAssertEqual(
            DeviceMarketingNameResolver.marketingName(forHardwareIdentifier: "iPhone99,9"),
            "Unknown Apple device (iPhone99,9)"
        )
    }

    func testDisplayLabelIncludesBoth() {
        let label = DeviceMarketingNameResolver.displayLabel(forHardwareIdentifier: "iPhone18,2")
        XCTAssertTrue(label.contains("iPhone 17 Pro Max"))
        XCTAssertTrue(label.contains("iPhone18,2"))
    }

    func testEmptyIdentifierFallback() {
        XCTAssertEqual(
            DeviceMarketingNameResolver.marketingName(forHardwareIdentifier: "  "),
            "Unknown Apple device (unknown)"
        )
    }
}
