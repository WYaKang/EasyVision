import UIKit
import Vision

public struct HumanRectResult {
    public let frame: CGRect
    public let confidence: Float
}

public class DetectHumanRectanglesRequest: ImageBasedRequest<HumanRectResult> {
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[HumanRectResult], Error>) -> Void) -> VNRequest {
        return create(
            VNDetectHumanRectanglesRequest.self,
            observationType: VNHumanObservation.self,
                        transform: { obs in
                HumanRectResult(
                    frame: self.convertRect(obs.boundingBox, imageSize: context.imageSize),
                    confidence: obs.confidence
                )
            },
            completion: completion
        )
    }
}
