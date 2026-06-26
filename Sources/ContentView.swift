import SwiftUI
import ARKit
import SceneKit
import AVFoundation

// MARK: - Root View

struct ContentView: View {
    @StateObject private var vm = PuttViewModel()

    var body: some View {
        ZStack {
            ARCameraView(arManager: vm.arManager)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    StatusBadge(label: "LiDAR",  on: vm.arManager.lidarActive)
                    StatusBadge(label: "경사계",   on: vm.motionActive)
                }
                .padding(.top, 58)

                Spacer()
                Crosshair()
                Spacer()

                ResultPanel(vm: vm)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 44)
            }
        }
    }
}

// MARK: - AR Camera (UIViewRepresentable)

struct ARCameraView: UIViewRepresentable {
    let arManager: ARManager

    func makeCoordinator() -> ARManager { arManager }

    func makeUIView(context: Context) -> ARSCNView {
        let v = ARSCNView()
        v.delegate = context.coordinator
        v.automaticallyUpdatesLighting = false
        v.antialiasingMode = .none

        guard ARWorldTrackingConfiguration.isSupported else {
            context.coordinator.lidarActive = false
            return v
        }

        let config = ARWorldTrackingConfiguration()
        if context.coordinator.isLidarSupported {
            config.frameSemantics = [.sceneDepth]
        }

        let camStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if camStatus == .authorized || camStatus == .notDetermined {
            v.session.run(config)
        } else {
            // 카메라 권한 거부 → AR 없이 기동
            context.coordinator.lidarActive = false
        }

        return v
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}

// MARK: - Crosshair

struct Crosshair: View {
    private let accent = Color(red: 0, green: 1, blue: 0.53)

    var body: some View {
        ZStack {
            Rectangle().frame(width: 60, height: 1.5)
            Rectangle().frame(width: 1.5, height: 60)
            Circle().stroke(lineWidth: 1.5).frame(width: 24, height: 24)
        }
        .foregroundColor(accent)
        .opacity(0.85)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let label: String
    let on: Bool
    private var color: Color { on ? Color(red: 0, green: 1, blue: 0.53) : .red }

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.gray)
            Text(on ? "ON" : "OFF")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 14).padding(.vertical, 6)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(color, lineWidth: 1))
    }
}

// MARK: - Result Panel

struct ResultPanel: View {
    @ObservedObject var vm: PuttViewModel
    private let accent = Color(red: 0, green: 1, blue: 0.53)

    var body: some View {
        VStack(spacing: 0) {
            Text(vm.resultString)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.vertical, 16)
                .padding(.horizontal, 8)
                .minimumScaleFactor(0.7)

            Divider().background(Color.white.opacity(0.15))

            HStack(spacing: 0) {
                DetailCell(title: "거리",
                           value: vm.distanceM.map { String(format: "%.2fm", $0) } ?? "—")
                VDivider()
                DetailCell(title: "경사", value: vm.slopeText)
                VDivider()
                DetailCell(title: "방향", value: vm.breakText)
            }
            .padding(.vertical, 10)
        }
        .background(Color.black.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(accent.opacity(0.35), lineWidth: 1)
        )
    }
}

struct DetailCell: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

struct VDivider: View {
    var body: some View {
        Rectangle()
            .frame(width: 1, height: 36)
            .foregroundColor(Color.white.opacity(0.15))
    }
}
