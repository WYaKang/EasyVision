import UIKit
import Vision

public struct TrackedObjectResult {
    public let frame: CGRect
    public let confidence: Float
}

public class TrackObjectRequest: ImageBasedRequest<TrackedObjectResult> {
    /// 初始跟踪框（归一化坐标），仅在第一帧需要
    public var inputObservation: VNDetectedObjectObservation
    
    public init(config: ImageRequestConfig = ImageRequestConfig(), inputObservation: VNDetectedObjectObservation) {
        self.inputObservation = inputObservation
        super.init(config: config)
    }
    
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[TrackedObjectResult], Error>) -> Void) -> VNRequest {
        let req = VNTrackObjectRequest(detectedObjectObservation: inputObservation) { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let results = request.results as? [VNDetectedObjectObservation] else {
                completion(.success([]))
                return
            }
            let mapped = results.map { obs in
                TrackedObjectResult(
                    frame: self.convertRect(obs.boundingBox, imageSize: context.imageSize),
                    confidence: obs.confidence
                )
            }
            completion(.success(mapped))
        }        return req
    }
}
