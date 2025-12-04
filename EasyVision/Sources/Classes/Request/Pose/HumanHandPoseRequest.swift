import UIKit
import Vision

public struct HandPoseResult {
    public let frame: CGRect
    public let points: [String: CGPoint]
    public let confidences: [String: Float]
}

public class HumanHandPoseRequest: ImageBasedRequest<HandPoseResult> {
    public var maximumHandCount: Int?
    
    public init(config: ImageRequestConfig = ImageRequestConfig(), maximumHandCount: Int? = nil) {
        self.maximumHandCount = maximumHandCount
        super.init(config: config)
    }
    
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[HandPoseResult], Error>) -> Void) -> VNRequest {
        return create(
            VNDetectHumanHandPoseRequest.self,
            observationType: VNHumanHandPoseObservation.self,
            configuration: { req in
                self.applyCommon(req)
                if let m = self.maximumHandCount {
                    req.maximumHandCount = m
                }
            },
            transform: { obs in
                let dict = (try? obs.recognizedPoints(.all)) ?? [:]
                var points: [String: CGPoint] = [:]
                var confs: [String: Float] = [:]
                for (name, p) in dict {
                    let xy = CGPoint(x: CGFloat(p.location.x) * context.imageSize.width,
                                     y: (1 - CGFloat(p.location.y)) * context.imageSize.height)
                    points[String(describing: name)] = xy
                    confs[String(describing: name)] = p.confidence
                }
                let all = Array(points.values)
                let frame: CGRect
                if let minX = all.map({ $0.x }).min(),
                   let maxX = all.map({ $0.x }).max(),
                   let minY = all.map({ $0.y }).min(),
                   let maxY = all.map({ $0.y }).max() {
                    frame = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
                } else {
                    frame = .zero
                }
                return HandPoseResult(
                    frame: frame,
                    points: points,
                    confidences: confs
                )
            },
            completion: completion
        )
    }
}
