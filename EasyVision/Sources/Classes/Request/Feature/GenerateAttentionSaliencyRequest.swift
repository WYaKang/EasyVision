import UIKit
import Vision

public struct SalientObjectResult {
    public let frame: CGRect
    public let confidence: Float
    /// 显著性热力图 (Saliency Heatmap)
    public let pixelBuffer: CVPixelBuffer?
}

public class GenerateAttentionSaliencyRequest: ImageBasedRequest<SalientObjectResult> {
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[SalientObjectResult], Error>) -> Void) -> VNRequest {
        // 注意：VNGenerateAttentionBasedSaliencyImageRequest 返回单个 VNSaliencyImageObservation，
        // 其中包含多个 salientObjects。通用 build 方法假定一对一映射。
        // 为支持一对多展开，我们这里仍需手动构建，但保持代码风格一致。
        let req = VNGenerateAttentionBasedSaliencyImageRequest { request, error in
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
        applyCommon(req)
        return req
    }
}
