import UIKit
import Vision

public struct RectangleResult {
    public let frame: CGRect
    public let confidence: Float
}

public class DetectRectanglesRequest: ImageBasedRequest<RectangleResult> {
    public var minimumAspectRatio: Float?
    public var maximumAspectRatio: Float?
    public var quadratureTolerance: Float?
    public var minimumSize: Float?
    public var minimumConfidence: Float?
    
    public init(
        config: ImageRequestConfig = ImageRequestConfig(),
        minimumAspectRatio: Float? = nil,
        maximumAspectRatio: Float? = nil,
        quadratureTolerance: Float? = nil,
        minimumSize: Float? = nil,
        minimumConfidence: Float? = nil
    ) {
        self.minimumAspectRatio = minimumAspectRatio
        self.maximumAspectRatio = maximumAspectRatio
        self.quadratureTolerance = quadratureTolerance
        self.minimumSize = minimumSize
        self.minimumConfidence = minimumConfidence
        super.init(config: config)
    }
    
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[RectangleResult], Error>) -> Void) -> VNRequest {
        return create(
            VNDetectRectanglesRequest.self,
            observationType: VNRectangleObservation.self,
            configuration: { req in
                if let v = self.minimumAspectRatio { req.minimumAspectRatio = v }
                if let v = self.maximumAspectRatio { req.maximumAspectRatio = v }
                if let v = self.quadratureTolerance { req.quadratureTolerance = v }
                if let v = self.minimumSize { req.minimumSize = v }
                if let v = self.minimumConfidence { req.minimumConfidence = v }
            },
            transform: { obs in
                RectangleResult(
                    frame: self.convertRectangleObservation(obs, imageSize: context.imageSize),
                    confidence: obs.confidence
                )
            },
            completion: completion
        )
    }
}
