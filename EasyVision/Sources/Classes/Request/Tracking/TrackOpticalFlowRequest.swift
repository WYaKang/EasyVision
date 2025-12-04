import UIKit
import Vision

public struct TrackOpticalFlowResult {
    // 暂无公开属性，通常用于辅助其他跟踪或作为序列请求的一部分
    public let observation: VNObservation
}

public class TrackOpticalFlowRequest: ImageBasedRequest<TrackOpticalFlowResult> {
    public var computationAccuracy: VNTrackOpticalFlowRequest.ComputationAccuracy?
    public var outputPixelFormat: OSType?
    
    public init(config: ImageRequestConfig = ImageRequestConfig(), computationAccuracy: VNTrackOpticalFlowRequest.ComputationAccuracy? = nil, outputPixelFormat: OSType? = nil) {
        self.computationAccuracy = computationAccuracy
        self.outputPixelFormat = outputPixelFormat
        super.init(config: config)
    }
    
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[TrackOpticalFlowResult], Error>) -> Void) -> VNRequest {
        return create(
            VNTrackOpticalFlowRequest.self,
            observationType: VNPixelBufferObservation.self,
            configuration: { req in
                self.applyCommon(req)
                if let acc = self.computationAccuracy { req.computationAccuracy = acc }
                if let fmt = self.outputPixelFormat { req.outputPixelFormat = fmt }
            },
            transform: { obs in
                TrackOpticalFlowResult(observation: obs)
            },
            completion: completion
        )
    }
}
