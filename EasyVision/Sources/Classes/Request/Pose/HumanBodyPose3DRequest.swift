import UIKit
import Vision
import simd

public struct BodyPose3DResult {
    public let frame: CGRect
    public let joints: [String: SIMD3<Float>]
    /// 相机原点矩阵（从 Hip 到相机的变换）
    public let cameraOriginMatrix: simd_float4x4
    /// 估算身高（米）
    public let bodyHeight: Float
}

public class HumanBodyPose3DRequest: ImageBasedRequest<BodyPose3DResult> {
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[BodyPose3DResult], Error>) -> Void) -> VNRequest {
        return create(
            VNDetectHumanBodyPose3DRequest.self,
            observationType: VNHumanBodyPose3DObservation.self,
                        transform: { obs in
                var joints: [String: SIMD3<Float>] = [:]
                var points2D: [CGPoint] = []
                for name in obs.availableJointNames {
                    if let rp = try? obs.recognizedPoint(name) {
                        let t = rp.position.columns.3
                        joints[String(describing: name)] = SIMD3<Float>(t.x, t.y, t.z)
                    }
                    if let ip = try? obs.pointInImage(name) {
                        let p = CGPoint(x: CGFloat(ip.x) * context.imageSize.width,
                                        y: (1 - CGFloat(ip.y)) * context.imageSize.height)
                        points2D.append(p)
                    }
                }
                let frame: CGRect
                if let minX = points2D.map({ $0.x }).min(),
                   let maxX = points2D.map({ $0.x }).max(),
                   let minY = points2D.map({ $0.y }).min(),
                   let maxY = points2D.map({ $0.y }).max() {
                    frame = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
                } else {
                    frame = .zero
                }
                return BodyPose3DResult(
                    frame: frame,
                    joints: joints,
                    cameraOriginMatrix: obs.cameraOriginMatrix,
                    bodyHeight: obs.bodyHeight
                )
            },
            completion: completion
        )
    }
}
