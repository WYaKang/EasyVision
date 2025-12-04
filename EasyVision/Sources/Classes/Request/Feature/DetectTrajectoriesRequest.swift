import UIKit
import Vision
import CoreMedia

public struct TrajectoryResult {
    public let timeRange: CMTimeRange?
    public let normalizedPoints: [CGPoint]
}

public class DetectTrajectoriesRequest: ImageBasedRequest<TrajectoryResult> {
    public var objectMinimumNormalizedRadius: Float?
    public var objectMaximumNormalizedRadius: Float?
    public var frameAnalysisSpacing: CMTime?
    public var trajectoryLength: Int?
    
    public init(config: ImageRequestConfig = ImageRequestConfig(), objectMinimumNormalizedRadius: Float? = nil, objectMaximumNormalizedRadius: Float? = nil, frameAnalysisSpacing: CMTime? = nil, trajectoryLength: Int? = nil) {
        self.objectMinimumNormalizedRadius = objectMinimumNormalizedRadius
        self.objectMaximumNormalizedRadius = objectMaximumNormalizedRadius
        self.frameAnalysisSpacing = frameAnalysisSpacing
        self.trajectoryLength = trajectoryLength
        super.init(config: config)
    }
    
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[TrajectoryResult], Error>) -> Void) -> VNRequest {
        // VNDetectTrajectoriesRequest 不支持标准的 completionHandler 初始化，必须用这个指定参数的初始化器
        let req = VNDetectTrajectoriesRequest(frameAnalysisSpacing: frameAnalysisSpacing ?? .zero, trajectoryLength: trajectoryLength ?? 5)
        applyCommon(req)
        if let v = objectMinimumNormalizedRadius { req.objectMinimumNormalizedRadius = v }
        if let v = objectMaximumNormalizedRadius { req.objectMaximumNormalizedRadius = v }
        // frameAnalysisSpacing is read-only after init
        return req
    }
}
