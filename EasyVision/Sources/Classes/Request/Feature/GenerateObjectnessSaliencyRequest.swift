import UIKit
import Vision

public class GenerateObjectnessSaliencyRequest: ImageBasedRequest<SalientObjectResult> {
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[SalientObjectResult], Error>) -> Void) -> VNRequest {
        let req = VNGenerateObjectnessBasedSaliencyImageRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let obs = request.results?.first as? VNSaliencyImageObservation else {
                completion(.success([]))
                return
            }
            let mapped = (obs.salientObjects ?? []).map { o in
                SalientObjectResult(
                    frame: self.convertRect(o.boundingBox, imageSize: context.imageSize),
                    confidence: o.confidence,
                    pixelBuffer: obs.pixelBuffer
                )
            }
            completion(.success(mapped))
        }
        return req
    }
}
