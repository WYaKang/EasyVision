import UIKit
import Vision

public struct FaceCaptureQualityResult {
    public let frame: CGRect
    public let confidence: Float
    public let quality: Float?
    
    /// 质量等级评估
    public enum QualityLevel {
        case low, medium, high, unknown
    }
    
    public var qualityLevel: QualityLevel {
        guard let q = quality else { return .unknown }
        switch q {
        case 0..<0.3: return .low
        case 0.3..<0.7: return .medium
        default: return .high
        }
    }
}

public class FaceCaptureQualityRequest: ImageBasedRequest<FaceCaptureQualityResult> {
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[FaceCaptureQualityResult], Error>) -> Void) -> VNRequest {
        return create(
            VNDetectFaceCaptureQualityRequest.self,
            observationType: VNFaceObservation.self,
            transform: { obs in
                return FaceCaptureQualityResult(
                    frame: self.convertRect(obs.boundingBox, imageSize: context.imageSize),
                    confidence: obs.confidence,
                    quality: obs.faceCaptureQuality
                )
            },
            completion: completion
        )
    }
}
