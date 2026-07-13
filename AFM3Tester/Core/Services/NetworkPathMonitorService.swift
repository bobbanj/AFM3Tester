import Foundation
import Network

actor NetworkPathMonitorService {
    static let monitorDisclaimer = SideEffectPolicy.monitorDisclaimer

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.example.AFM3Tester.NetworkPathMonitor")
    private(set) var isOffline = false
    private(set) var pathSnapshot = NetworkPathSnapshot(
        statusDescription: "Not started",
        isSatisfied: true,
        availableInterfaces: []
    )
    private var isRunning = false

    func start() {
        guard !isRunning else { return }
        isRunning = true

        monitor.pathUpdateHandler = { [weak self] path in
            Task {
                await self?.updatePath(path)
            }
        }
        monitor.start(queue: queue)
    }

    func stop() {
        guard isRunning else { return }
        monitor.cancel()
        isRunning = false
    }

    func currentSnapshot() -> NetworkPathSnapshot {
        pathSnapshot
    }

    private func updatePath(_ path: NWPath) {
        isOffline = path.status != .satisfied
        pathSnapshot = Self.makeSnapshot(from: path)
    }

    nonisolated static func makeSnapshot(from path: NWPath, capturedAt: Date = Date()) -> NetworkPathSnapshot {
        let interfaces = path.availableInterfaces.map { interface in
            switch interface.type {
            case .wifi: "wifi"
            case .cellular: "cellular"
            case .wiredEthernet: "wiredEthernet"
            case .loopback: "loopback"
            case .other: "other"
            @unknown default: "unknown"
            }
        }
        let status: String
        switch path.status {
        case .satisfied:
            status = "satisfied"
        case .unsatisfied:
            status = "unsatisfied"
        case .requiresConnection:
            status = "requiresConnection"
        @unknown default:
            status = "unknown"
        }
        return NetworkPathSnapshot(
            statusDescription: status,
            isSatisfied: path.status == .satisfied,
            availableInterfaces: interfaces,
            capturedAt: capturedAt
        )
    }
}
