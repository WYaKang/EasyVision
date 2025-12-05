import UIKit
import Vision

public struct TrackedRectangleResult {
    public let frame: CGRect
    public let confidence: Float
}

public class TrackRectangleRequest: ImageBasedRequest<TrackedRectangleResult> {
    public var inputObservation: VNRectangleObservation
    
    public init(config: ImageRequestConfig = ImageRequestConfig(), inputObservation: VNRectangleObservation) {
        self.inputObservation = inputObservation
        super.init(config: config)
    }
    
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[TrackedRectangleResult], Error>) -> Void) -> VNRequest {
        let req = VNTrackRectangleRequest(rectangleObservation: inputObservation) { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let results = request.results as? [VNRectangleObservation] else {
                completion(.success([]))
                return
            }
            let mapped = results.map { obs in
                TrackedRectangleResult(
                    frame: self.convertRectangleObservation(obs, imageSize: context.imageSize),
                    confidence: obs.confidence
                )
            }
            completion(.success(mapped))
        }
        return req
    }
}
