import UIKit
import Vision

// 结果模型
public struct FaceRectResult {
    public let frame: CGRect
    public let confidence: Float
    /// 滚动角（Roll）：人脸平面内旋转角度（弧度）
    public let roll: Float?
    /// 偏航角（Yaw）：左右转头角度（弧度）
    public let yaw: Float?
    /// 俯仰角（Pitch）：上下抬头角度（弧度，iOS 15+）
    public let pitch: Float?
}

public class FaceRectRequest: ImageBasedRequest<FaceRectResult> {
    
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[FaceRectResult], Error>) -> Void) -> VNRequest {
        return create(
            VNDetectFaceRectanglesRequest.self,
            observationType: VNFaceObservation.self,
                        transform: { obs in
                // pitch 在 iOS 15+ 可用，Vision 提供了属性但需检查可用性或直接访问
                // obs.pitch, obs.yaw, obs.roll 均为 NSNumber?
                return FaceRectResult(
                    frame: self.convertRect(obs.boundingBox, imageSize: context.imageSize),
                    confidence: obs.confidence,
                    roll: obs.roll?.floatValue,
                    yaw: obs.yaw?.floatValue,
                    pitch: obs.pitch?.floatValue
                )
            },
            completion: completion
        )
    }
}
