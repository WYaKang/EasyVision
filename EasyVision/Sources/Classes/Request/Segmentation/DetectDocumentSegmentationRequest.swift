import UIKit
import Vision

public struct DocumentSegmentationResult {
    public let frame: CGRect
    public let topLeft: CGPoint
    public let topRight: CGPoint
    public let bottomLeft: CGPoint
    public let bottomRight: CGPoint
    public let confidence: Float
}

public class DetectDocumentSegmentationRequest: ImageBasedRequest<DocumentSegmentationResult> {
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[DocumentSegmentationResult], Error>) -> Void) -> VNRequest {
        return create(
            VNDetectDocumentSegmentationRequest.self,
            observationType: VNRectangleObservation.self,
            transform: { obs in
                // 文档分割返回的是 VNRectangleObservation，表示文档的四角
                let w = context.imageSize.width
                let h = context.imageSize.height
                
                let tl = CGPoint(x: obs.topLeft.x * w, y: (1 - obs.topLeft.y) * h)
                let tr = CGPoint(x: obs.topRight.x * w, y: (1 - obs.topRight.y) * h)
                let bl = CGPoint(x: obs.bottomLeft.x * w, y: (1 - obs.bottomLeft.y) * h)
                let br = CGPoint(x: obs.bottomRight.x * w, y: (1 - obs.bottomRight.y) * h)
                
                return DocumentSegmentationResult(
                    frame: self.convertRectangleObservation(obs, imageSize: context.imageSize),
                    topLeft: tl,
                    topRight: tr,
                    bottomLeft: bl,
                    bottomRight: br,
                    confidence: obs.confidence
                )
            },
            completion: completion
        )
    }
}
