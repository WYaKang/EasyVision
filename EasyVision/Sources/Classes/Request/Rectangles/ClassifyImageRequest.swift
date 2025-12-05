import UIKit
import Vision

public struct ImageClassificationResult {
    public let identifier: String
    public let confidence: Float
    /// 分类层级（如果 Vision 支持层级关系）
    public let hasHierarchy: Bool
}

public class ClassifyImageRequest: ImageBasedRequest<ImageClassificationResult> {
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[ImageClassificationResult], Error>) -> Void) -> VNRequest {
        return create(
            VNClassifyImageRequest.self,
            observationType: VNClassificationObservation.self,
            transform: { obs in
                ImageClassificationResult(
                    identifier: obs.identifier,
                    confidence: obs.confidence,
                    hasHierarchy: obs.hasPrecisionRecallCurve // 暂用此属性代表高级特征
                )
            },
            completion: completion
        )
    }
}
