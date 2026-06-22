import ARKit
import SceneKit
import Combine

class ARManager: NSObject, ObservableObject, ARSCNViewDelegate {
    @Published var distance: Float? = nil
    @Published var lidarActive = false

    var isLidarSupported: Bool {
        ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
    }

    private var lastProcessTime: TimeInterval = 0

    // MARK: - ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard time - lastProcessTime > 0.1 else { return }
        lastProcessTime = time

        guard let arView = renderer as? ARSCNView,
              let frame = arView.session.currentFrame,
              let depthData = frame.sceneDepth else { return }

        let d = centerDepth(depthData.depthMap)
        guard let d, d.isFinite, d > 0.05, d < 6.0 else { return }

        DispatchQueue.main.async {
            self.distance = d
            self.lidarActive = true
        }
    }

    private func centerDepth(_ buf: CVPixelBuffer) -> Float? {
        CVPixelBufferLockBaseAddress(buf, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buf, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(buf) else { return nil }
        let w      = CVPixelBufferGetWidth(buf)
        let h      = CVPixelBufferGetHeight(buf)
        let stride = CVPixelBufferGetBytesPerRow(buf) / MemoryLayout<Float32>.size
        return base.assumingMemoryBound(to: Float32.self)[(h / 2) * stride + (w / 2)]
    }
}
