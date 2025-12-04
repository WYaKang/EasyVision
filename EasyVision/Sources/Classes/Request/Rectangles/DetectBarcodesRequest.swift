import UIKit
import Vision

public struct BarcodeResult {
    public let frame: CGRect
    public let symbology: VNBarcodeSymbology
    public let payload: String?
    public let confidence: Float
    /// 条形码的原始数据描述符（可选）
    public let barcodeDescriptor: CIBarcodeDescriptor?
    /// 关联的 CIImage 二维码（如果有）
    public var barcodeImage: CIImage? {
        guard let desc = barcodeDescriptor else { return nil }
        // 这里仅作占位，实际转换可能需要 Context
        return nil 
    }
}

public class DetectBarcodesRequest: ImageBasedRequest<BarcodeResult> {
    public var symbologies: [VNBarcodeSymbology]?
    
    public init(config: ImageRequestConfig = ImageRequestConfig(), symbologies: [VNBarcodeSymbology]? = nil) {
        self.symbologies = symbologies
        super.init(config: config)
    }

    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[BarcodeResult], Error>) -> Void) -> VNRequest {
        return create(
            VNDetectBarcodesRequest.self,
            observationType: VNBarcodeObservation.self,
            configuration: { req in
                if let syms = self.symbologies {
                    req.symbologies = syms
                }
            },
            transform: { obs in
                BarcodeResult(
                    frame: self.convertRect(obs.boundingBox, imageSize: context.imageSize),
                    symbology: obs.symbology,
                    payload: obs.payloadStringValue,
                    confidence: obs.confidence,
                    barcodeDescriptor: obs.barcodeDescriptor
                )
            },
            completion: completion
        )
    }
}
