import UIKit
import Vision

public struct HumanRectResult {
    public let frame: CGRect
    public let confidence: Float
}

public class DetectHumanRectanglesRequest: ImageBasedRequest<HumanRectResult> {
    
    public var upperBodyOnly: Bool
    
    public init(config: ImageRequestConfig = ImageRequestConfig(), upperBodyOnly: Bool = true) {
        self.upperBodyOnly = upperBodyOnly
        super.init(config: config)
    }
    
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[HumanRectResult], Error>) -> Void) -> VNRequest {
        return create(
            VNDetectHumanRectanglesRequest.self,
            observationType: VNHumanObservation.self,
            configuration: { req in
                req.upperBodyOnly = self.upperBodyOnly
            },
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
