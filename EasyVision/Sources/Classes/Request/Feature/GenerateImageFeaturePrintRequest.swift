import UIKit
import Vision

public struct FeaturePrintResult {
    public let observation: VNFeaturePrintObservation
    
    /// 计算与另一个特征指纹的距离
    /// - Parameter other: 另一个特征结果
    /// - Returns: 距离值（越小越相似），若计算失败返回 nil
    public func distance(to other: FeaturePrintResult) -> Float? {
        var dist: Float = 0
        do {
            try observation.computeDistance(&dist, to: other.observation)
            return dist
        } catch {
            EasyVisionLogger.shared.error("FeaturePrint distance error: \(error)")
            return nil
        }
    }
}

public class GenerateImageFeaturePrintRequest: ImageBasedRequest<FeaturePrintResult> {
    public var imageCropAndScaleOption: VNImageCropAndScaleOption?
    
    public init(config: ImageRequestConfig = ImageRequestConfig(), imageCropAndScaleOption: VNImageCropAndScaleOption? = nil) {
        self.imageCropAndScaleOption = imageCropAndScaleOption
        super.init(config: config)
    }
    
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[FeaturePrintResult], Error>) -> Void) -> VNRequest {
        return create(
            VNGenerateImageFeaturePrintRequest.self,
            observationType: VNFeaturePrintObservation.self,
            configuration: { req in
                self.applyCommon(req)
                if let v = self.imageCropAndScaleOption {
                    req.imageCropAndScaleOption = v
                }
            },
            transform: { obs in
                FeaturePrintResult(observation: obs)
            },
            completion: completion
        )
    }
}
