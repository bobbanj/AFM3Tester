import Foundation
import UIKit

enum DeviceInfoProvider {

    // MARK: - OS

    static var osVersion: String {
        ProcessInfo.processInfo.operatingSystemVersionString
    }

    static var osBuild: String {
        if let build = ProcessInfo.processInfo.environment["SIMULATOR_RUNTIME_BUILD_VERSION"] {
            return build
        }
        var size = 0
        sysctlbyname("kern.osversion", nil, &size, nil, 0)
        var build = [CChar](repeating: 0, count: size)
        sysctlbyname("kern.osversion", &build, &size, nil, 0)
        return String(cString: build)
    }

    // MARK: - Device Model

    static var deviceModelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
        return machine
    }

    // MARK: - Locale

    static var localeIdentifier: String {
        Locale.current.identifier
    }

    static var languageCode: String {
        Locale.current.language.languageCode?.identifier ?? "unknown"
    }

    static var regionCode: String {
        Locale.current.region?.identifier ?? "unknown"
    }

    // MARK: - Thermal State

    static var thermalStateDescription: String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal:
            "nominal"
        case .fair:
            "fair"
        case .serious:
            "serious"
        case .critical:
            "critical"
        @unknown default:
            "unknown"
        }
    }

    // MARK: - Simulator

    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }

    // MARK: - Battery & Power (MainActor)

    @MainActor
    static func batteryLevel() -> Double? {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        guard level >= 0 else { return nil }
        return Double(level)
    }

    @MainActor
    static var isLowPowerModeEnabled: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    @MainActor
    static var isCharging: Bool {
        UIDevice.current.isBatteryMonitoringEnabled = true
        switch UIDevice.current.batteryState {
        case .charging, .full:
            return true
        default:
            return false
        }
    }

    // MARK: - Snapshot

    @MainActor
    static func captureSnapshot() -> DeviceSnapshot {
        DeviceSnapshot(
            osVersion: osVersion,
            osBuild: osBuild,
            deviceModel: deviceModelIdentifier,
            localeIdentifier: localeIdentifier,
            languageCode: languageCode,
            regionCode: regionCode,
            thermalState: thermalStateDescription,
            batteryLevel: batteryLevel(),
            isLowPowerModeEnabled: isLowPowerModeEnabled,
            isCharging: isCharging,
            isSimulator: isSimulator
        )
    }
}
