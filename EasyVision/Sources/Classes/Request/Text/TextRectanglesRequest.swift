import UIKit
import Vision

public struct TextRectResult {
    public let frame: CGRect
    public let confidence: Float
    public let characterBoxes: [CGRect]?
}

public class TextRectanglesRequest: ImageBasedRequest<TextRectResult> {
    public var reportCharacterBoxes: Bool
    
    public init(config: ImageRequestConfig = ImageRequestConfig(), reportCharacterBoxes: Bool = false) {
        self.reportCharacterBoxes = reportCharacterBoxes
        super.init(config: config)
    }
    
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[TextRectResult], Error>) -> Void) -> VNRequest {
        return create(
            VNDetectTextRectanglesRequest.self,
            observationType: VNTextObservation.self,
            configuration: { req in
                req.reportCharacterBoxes = self.reportCharacterBoxes
            },
            transform: { obs in
                let charRects = obs.characterBoxes?.map { self.convertRectangleObservation($0, imageSize: context.imageSize) }
                return TextRectResult(
                    frame: self.convertRect(obs.boundingBox, imageSize: context.imageSize),
                    confidence: obs.confidence,
                    characterBoxes: charRects
                )
            },
            completion: completion
        )
    }
}
