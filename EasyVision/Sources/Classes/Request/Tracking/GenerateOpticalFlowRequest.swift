import UIKit
import Vision

public struct OpticalFlowResult {
    public let pixelBuffer: CVPixelBuffer
}

public class GenerateOpticalFlowRequest: ImageBasedRequest<OpticalFlowResult> {
    public var computationAccuracy: VNGenerateOpticalFlowRequest.ComputationAccuracy?
    public var outputPixelFormat: OSType?
    
    public init(config: ImageRequestConfig = ImageRequestConfig(), computationAccuracy: VNGenerateOpticalFlowRequest.ComputationAccuracy? = nil, outputPixelFormat: OSType? = nil) {
        self.computationAccuracy = computationAccuracy
        self.outputPixelFormat = outputPixelFormat
        super.init(config: config)
    }
    
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[OpticalFlowResult], Error>) -> Void) -> VNRequest {
        return create(
            VNGenerateOpticalFlowRequest.self,
            observationType: VNPixelBufferObservation.self,
            configuration: { req in
                self.applyCommon(req)
                if let acc = self.computationAccuracy { req.computationAccuracy = acc }
                if let fmt = self.outputPixelFormat { req.outputPixelFormat = fmt }
            },
            transform: { obs in
                OpticalFlowResult(pixelBuffer: obs.pixelBuffer)
            },
            completion: completion
        )
    }
}
