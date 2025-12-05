import UIKit
import Vision

public struct ImageAestheticsResult {
    public let overallScore: Float
    public let isUtility: Bool
}

public class CalculateImageAestheticsScoresRequest: ImageBasedRequest<ImageAestheticsResult> {
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[ImageAestheticsResult], Error>) -> Void) -> VNRequest {
        if #available(iOS 18.0, *) {
            return create(
                VNCalculateImageAestheticsScoresRequest.self,
                observationType: VNImageAestheticsScoresObservation.self,
                transform: { obs in
                    ImageAestheticsResult(overallScore: obs.overallScore, isUtility: obs.isUtility)
                },
                completion: completion
            )
        } else {
            // 该请求仅在 iOS 17+ 可用
            // 返回一个空的 VNRequest 以避免崩溃，但在 completion 中报错
            // 或者我们可以选择不编译此文件的一部分，但这里用运行时检查更好
            let req = VNRequest { _, _ in
                completion(.failure(EasyVisionError.visionError(NSError(domain: "EasyVision", code: -1, userInfo: [NSLocalizedDescriptionKey: "VNCalculateImageAestheticsScoresRequest requires iOS 17.0+"]))))
            }
            return req
        }
    }
}
