import UIKit
import Vision

public struct HorizonResult {
    public let angleRadians: CGFloat
    public let transform: CGAffineTransform
}

public class DetectHorizonRequest: ImageBasedRequest<HorizonResult> {
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[HorizonResult], Error>) -> Void) -> VNRequest {
        return create(
            VNDetectHorizonRequest.self,
            observationType: VNHorizonObservation.self,
                        transform: { obs in
                HorizonResult(angleRadians: obs.angle, transform: obs.transform)
            },
            completion: completion
        )
    }
}
