import Foundation
import Combine
import CoreMotion

class PuttViewModel: ObservableObject {
    @Published var distanceM: Float?  = nil
    @Published var slopeText: String  = "평지"
    @Published var breakText: String  = "직선"
    @Published var motionActive: Bool = false

    let arManager = ARManager()

    private let motion      = CMMotionManager()
    private var cancellables = Set<AnyCancellable>()
    private var pitchDeg: Double = 0
    private var rollDeg:  Double = 0

    init() {
        arManager.$distance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] d in
                self?.distanceM = d
                self?.updateBreak()
            }
            .store(in: &cancellables)

        startMotion()
    }

    // MARK: - CoreMotion

    private func startMotion() {
        guard motion.isAccelerometerAvailable else { return }
        motion.accelerometerUpdateInterval = 0.1
        motion.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let g = data?.acceleration else { return }
            self.motionActive = true
            // pitch: forward/back tilt → uphill / downhill
            self.pitchDeg = atan2(-g.y,  abs(g.z)) * 180 / .pi
            // roll:  left/right tilt  → break direction
            self.rollDeg  = atan2( g.x,  abs(g.z)) * 180 / .pi
            self.updateSlope()
            self.updateBreak()
        }
    }

    private func updateSlope() {
        let p = abs(pitchDeg)
        switch p {
        case ..<2:  slopeText = "평지"
        case ..<5:  slopeText = pitchDeg > 0 ? "약한 오르막" : "약한 내리막"
        case ..<10: slopeText = pitchDeg > 0 ? "오르막"     : "내리막"
        default:    slopeText = pitchDeg > 0 ? "급한 오르막" : "급한 내리막"
        }
    }

    private func updateBreak() {
        let absRoll = abs(rollDeg)
        guard absRoll > 2.0 else { breakText = "직선"; return }

        let dist   = Double(distanceM ?? 5)
        let factor = dist / 5.0  // normalize to 5 m reference

        let cupValue: Double
        switch absRoll {
        case ..<4:  cupValue = 0.5 * factor
        case ..<7:  cupValue = 1.0 * factor
        case ..<10: cupValue = 2.0 * factor
        default:    cupValue = 3.0 * factor
        }

        let cupStr: String
        switch cupValue {
        case ..<0.3:  breakText = "직선"; return
        case ..<0.75: cupStr = "반컵"
        case ..<1.5:  cupStr = "1컵"
        case ..<2.5:  cupStr = "2컵"
        default:      cupStr = "3컵"
        }

        breakText = "\(cupStr) \(rollDeg > 0 ? "우측" : "좌측")"
    }

    // MARK: - Result

    var resultString: String {
        let dStr = distanceM.map { String(format: "%.1fm", $0) } ?? "— m"
        return "\(dStr) / \(slopeText) / \(breakText)"
    }
}
