import UIKit
import Vision

public struct AnimalRecognitionResult {
    public let frame: CGRect
    public let identifier: String
    public let confidence: Float
    /// 所有候选标签（按置信度排序）
    public let labels: [VNClassificationObservation]
}

public class RecognizeAnimalsRequest: ImageBasedRequest<AnimalRecognitionResult> {
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[AnimalRecognitionResult], Error>) -> Void) -> VNRequest {
        return create(
            VNRecognizeAnimalsRequest.self,
            observationType: VNRecognizedObjectObservation.self,
            transform: { obs in
                guard let best = obs.labels.first else { return nil }
                return AnimalRecognitionResult(
                    frame: self.convertRect(obs.boundingBox, imageSize: context.imageSize),
                    identifier: best.identifier,
                    confidence: best.confidence,
                    labels: obs.labels
                )
            },
            completion: completion
        )
    }
}
