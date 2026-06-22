import ExpoModulesCore
import ARKit

public class LidarSensorModule: Module, ARSessionDelegate {

  private var arSession: ARSession?

  public func definition() -> ModuleDefinition {
    Name("LidarSensor")

    Events("onDistanceUpdate")

    // 이 기기가 LiDAR(SceneDepth)를 지원하는지 반환
    Function("isSupported") { () -> Bool in
      if #available(iOS 14.0, *) {
        return ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
      }
      return false
    }

    // ARKit 세션 시작 (LiDAR depth 활성화)
    AsyncFunction("startSession") { (promise: Promise) in
      guard #available(iOS 14.0, *) else {
        promise.reject("IOS_VERSION", "iOS 14.0 이상이 필요합니다")
        return
      }
      guard ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) else {
        promise.reject(
          "LIDAR_NOT_SUPPORTED",
          "LiDAR를 지원하지 않는 기기입니다. iPhone 12 Pro 이상이 필요합니다."
        )
        return
      }

      DispatchQueue.main.async {
        let session = ARSession()
        session.delegate = self

        let config = ARWorldTrackingConfiguration()
        config.frameSemantics = [.sceneDepth]
        session.run(config)

        self.arSession = session
        promise.resolve(nil)
      }
    }

    // ARKit 세션 중단
    Function("stopSession") { () in
      self.arSession?.pause()
      self.arSession = nil
    }
  }

  // ARKit 프레임 업데이트 → 화면 중앙 depth 값 읽어서 이벤트 발송
  public func session(_ session: ARSession, didUpdate frame: ARFrame) {
    guard #available(iOS 14.0, *),
          let depthData = frame.sceneDepth else { return }

    let depthMap = depthData.depthMap
    let width  = CVPixelBufferGetWidth(depthMap)
    let height = CVPixelBufferGetHeight(depthMap)

    CVPixelBufferLockBaseAddress(depthMap, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }

    guard let base = CVPixelBufferGetBaseAddress(depthMap) else { return }

    // depthMap 픽셀 포맷: kCVPixelFormatType_DepthFloat32
    let stride      = CVPixelBufferGetBytesPerRow(depthMap) / MemoryLayout<Float32>.size
    let floatBuffer = base.assumingMemoryBound(to: Float32.self)

    let cx = width  / 2
    let cy = height / 2
    let dist = floatBuffer[cy * stride + cx]  // 단위: 미터

    // NaN / 무한대 / 측정 불가 거르기 (LiDAR 유효 범위 ~0.1m ~ 5m)
    guard dist.isFinite, dist > 0.05, dist < 6.0 else { return }

    self.sendEvent("onDistanceUpdate", ["distance": Double(dist)])
  }
}
