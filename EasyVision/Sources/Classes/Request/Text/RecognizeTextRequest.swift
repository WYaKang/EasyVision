import UIKit
import Vision

public struct RecognizedTextResult {
    public let frame: CGRect
    public let text: String
    public let confidence: Float
    /// 所有候选识别结果（按置信度排序）
    public let candidates: [String]
    /// 字符级边界框（如可用）
    public let boundingBox: CGRect
}

public class RecognizeTextRequest: ImageBasedRequest<RecognizedTextResult> {
    public var recognitionLevel: VNRequestTextRecognitionLevel
    public var usesLanguageCorrection: Bool
    public var recognitionLanguages: [String]?
    public var customWords: [String]?
    /// 返回的候选词最大数量
    public var maximumCandidates: Int
    
    public init(
        config: ImageRequestConfig = ImageRequestConfig(),
        recognitionLevel: VNRequestTextRecognitionLevel = .accurate,
        usesLanguageCorrection: Bool = true,
        recognitionLanguages: [String]? = nil,
        customWords: [String]? = nil,
        maximumCandidates: Int = 1
    ) {
        self.recognitionLevel = recognitionLevel
        self.usesLanguageCorrection = usesLanguageCorrection
        self.recognitionLanguages = recognitionLanguages
        self.customWords = customWords
        self.maximumCandidates = maximumCandidates
        super.init(config: config)
    }
    
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[RecognizedTextResult], Error>) -> Void) -> VNRequest {
        return create(
            VNRecognizeTextRequest.self,
            observationType: VNRecognizedTextObservation.self,
            configuration: { req in
                self.applyCommon(req)
                req.recognitionLevel = self.recognitionLevel
                req.usesLanguageCorrection = self.usesLanguageCorrection
                if let langs = self.recognitionLanguages {
                    req.recognitionLanguages = langs
                }
                if let words = self.customWords {
                    req.customWords = words
                }
            },
            transform: { obs in
                let candidates = obs.topCandidates(self.maximumCandidates)
                guard let best = candidates.first else { return nil }
                
                return RecognizedTextResult(
                    frame: self.convertRect(obs.boundingBox, imageSize: context.imageSize),
                    text: best.string,
                    confidence: Float(best.confidence),
                    candidates: candidates.map { $0.string },
                    boundingBox: self.convertRect(obs.boundingBox, imageSize: context.imageSize)
                )
            },
            completion: completion
        )
    }
}
