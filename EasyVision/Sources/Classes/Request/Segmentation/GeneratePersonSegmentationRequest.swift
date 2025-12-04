import UIKit
import Vision

public struct PersonSegmentationResult {
    public let pixelBuffer: CVPixelBuffer
}

public class GeneratePersonSegmentationRequest: ImageBasedRequest<PersonSegmentationResult> {
    public var qualityLevel: VNGeneratePersonSegmentationRequest.QualityLevel?
    public var outputPixelFormat: OSType?
    
    public init(config: ImageRequestConfig = ImageRequestConfig(), qualityLevel: VNGeneratePersonSegmentationRequest.QualityLevel? = nil, outputPixelFormat: OSType? = nil) {
        self.qualityLevel = qualityLevel
        self.outputPixelFormat = outputPixelFormat
        super.init(config: config)
    }
    
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[PersonSegmentationResult], Error>) -> Void) -> VNRequest {
        return create(
            VNGeneratePersonSegmentationRequest.self,
            observationType: VNPixelBufferObservation.self,
            configuration: { req in
                if let q = self.qualityLevel { req.qualityLevel = q }
                if let f = self.outputPixelFormat { req.outputPixelFormat = f }
            },
            transform: { obs in
                PersonSegmentationResult(pixelBuffer: obs.pixelBuffer)
            },
            completion: completion
        )
    }
}
