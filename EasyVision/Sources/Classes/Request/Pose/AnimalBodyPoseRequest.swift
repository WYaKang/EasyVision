import UIKit
import Vision

public struct AnimalBodyPoseResult {
    public let frame: CGRect
    public let points: [String: CGPoint]
    public let confidences: [String: Float]
}

public class AnimalBodyPoseRequest: ImageBasedRequest<AnimalBodyPoseResult> {
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[AnimalBodyPoseResult], Error>) -> Void) -> VNRequest {
        return create(
            VNDetectAnimalBodyPoseRequest.self,
            observationType: VNAnimalBodyPoseObservation.self,
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
                return AnimalBodyPoseResult(
                    frame: frame,
                    points: points,
                    confidences: confs
                )
            },
            completion: completion
        )
    }
}
