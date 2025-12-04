import UIKit
import Vision

public struct ImageRegistrationResult {
    public let transform: CGAffineTransform
    public let alignmentObservation: VNImageAlignmentObservation
}

public class TrackTranslationalImageRegistrationRequest: ImageBasedRequest<ImageRegistrationResult> {
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[ImageRegistrationResult], Error>) -> Void) -> VNRequest {
        return create(
            VNTrackTranslationalImageRegistrationRequest.self,
            observationType: VNImageTranslationAlignmentObservation.self,
                        transform: { obs in
                ImageRegistrationResult(transform: obs.alignmentTransform, alignmentObservation: obs)
            },
            completion: completion
        )
    }
}

public class TrackHomographicImageRegistrationRequest: ImageBasedRequest<ImageRegistrationResult> {
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[ImageRegistrationResult], Error>) -> Void) -> VNRequest {
        return create(
            VNTrackHomographicImageRegistrationRequest.self,
            observationType: VNImageHomographicAlignmentObservation.self,
                        transform: { obs in
                // 透视变换对应 warpTransform，这里 alignmentTransform 可能不适用或为 identity
                // Homographic 观察提供 warpTransform (3x3 matrix)
                // 但 CGAffineTransform 只有 2x3，所以这里仅返回基础结构，完整矩阵需从 observation 获取
                // 注意：VNImageHomographicAlignmentObservation 的 warpTransform 是 simd_float3x3
                return ImageRegistrationResult(transform: .identity, alignmentObservation: obs)
            },
            completion: completion
        )
    }
}
