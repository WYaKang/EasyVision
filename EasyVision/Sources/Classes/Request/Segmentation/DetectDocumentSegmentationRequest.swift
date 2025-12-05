import UIKit
import Vision

public struct DocumentSegmentationResult {
    public let frame: CGRect
    public let confidence: Float
}

public class DetectDocumentSegmentationRequest: ImageBasedRequest<DocumentSegmentationResult> {
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[DocumentSegmentationResult], Error>) -> Void) -> VNRequest {
        return create(
            VNDetectDocumentSegmentationRequest.self,
            observationType: VNRectangleObservation.self,
            transform: { obs in
                // 文档分割返回的是 VNRectangleObservation，表示文档的四角
                return DocumentSegmentationResult(
                    frame: self.convertRectangleObservation(obs, imageSize: context.imageSize),
                    confidence: obs.confidence
                )
            },
            completion: completion
        )
    }
}
