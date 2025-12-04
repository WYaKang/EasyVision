import UIKit
import Vision
import CoreML

public struct CoreMLResult {
    public let observation: VNObservation
    /// 尝试提取分类结果（如果是分类模型）
    public var classification: VNClassificationObservation? {
        observation as? VNClassificationObservation
    }
    /// 尝试提取检测结果（如果是检测模型）
    public var detectedObject: VNDetectedObjectObservation? {
        observation as? VNDetectedObjectObservation
    }
    /// 尝试提取像素结果（如果是分割模型）
    public var pixelBuffer: VNPixelBufferObservation? {
        observation as? VNPixelBufferObservation
    }
}

public class CoreMLRequest: ImageBasedRequest<CoreMLResult> {
    public let model: VNCoreMLModel
    public var imageCropAndScaleOption: VNImageCropAndScaleOption?
    
    public init(config: ImageRequestConfig = ImageRequestConfig(), model: VNCoreMLModel, imageCropAndScaleOption: VNImageCropAndScaleOption? = nil) {
        self.model = model
        self.imageCropAndScaleOption = imageCropAndScaleOption
        super.init(config: config)
    }
    
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[CoreMLResult], Error>) -> Void) -> VNRequest {
        let req = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let results = request.results else {
                completion(.success([]))
                return
            }
            // VNCoreMLRequest 可能返回多种 Observation 子类
            let mapped = results.map { CoreMLResult(observation: $0) }
            completion(.success(mapped))
        }        if let opt = imageCropAndScaleOption {
            req.imageCropAndScaleOption = opt
        }
        return req
    }
}
