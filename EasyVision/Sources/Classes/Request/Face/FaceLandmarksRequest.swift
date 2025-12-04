import UIKit
import Vision

public struct FaceLandmarksResult {
    public let frame: CGRect
    public let confidence: Float
    public let leftEye: [CGPoint]?
    public let rightEye: [CGPoint]?
    public let leftEyebrow: [CGPoint]?
    public let rightEyebrow: [CGPoint]?
    public let nose: [CGPoint]?
    public let noseCrest: [CGPoint]?
    public let medianLine: [CGPoint]?
    public let outerLips: [CGPoint]?
    public let innerLips: [CGPoint]?
    public let faceContour: [CGPoint]?
    
    // 瞳孔（需 iOS 13+ 或 revision 支持）
    public let leftPupil: [CGPoint]?
    public let rightPupil: [CGPoint]?
    
    /// 获取所有关键点的扁平数组，方便统一绘制
    public var allPoints: [CGPoint] {
        [leftEye, rightEye, leftEyebrow, rightEyebrow, nose, noseCrest, medianLine, outerLips, innerLips, faceContour, leftPupil, rightPupil]
            .compactMap { $0 }
            .flatMap { $0 }
    }
}

public class FaceLandmarksRequest: ImageBasedRequest<FaceLandmarksResult> {
    
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[FaceLandmarksResult], Error>) -> Void) -> VNRequest {
        return create(
            VNDetectFaceLandmarksRequest.self,
            observationType: VNFaceObservation.self,
                        transform: { obs in
                let lm = obs.landmarks
                return FaceLandmarksResult(
                    frame: self.convertRect(obs.boundingBox, imageSize: context.imageSize),
                    confidence: obs.confidence,
                    leftEye: self.convertRegionPoints(lm?.leftEye, in: obs.boundingBox, imageSize: context.imageSize),
                    rightEye: self.convertRegionPoints(lm?.rightEye, in: obs.boundingBox, imageSize: context.imageSize),
                    leftEyebrow: self.convertRegionPoints(lm?.leftEyebrow, in: obs.boundingBox, imageSize: context.imageSize),
                    rightEyebrow: self.convertRegionPoints(lm?.rightEyebrow, in: obs.boundingBox, imageSize: context.imageSize),
                    nose: self.convertRegionPoints(lm?.nose, in: obs.boundingBox, imageSize: context.imageSize),
                    noseCrest: self.convertRegionPoints(lm?.noseCrest, in: obs.boundingBox, imageSize: context.imageSize),
                    medianLine: self.convertRegionPoints(lm?.medianLine, in: obs.boundingBox, imageSize: context.imageSize),
                    outerLips: self.convertRegionPoints(lm?.outerLips, in: obs.boundingBox, imageSize: context.imageSize),
                    innerLips: self.convertRegionPoints(lm?.innerLips, in: obs.boundingBox, imageSize: context.imageSize),
                    faceContour: self.convertRegionPoints(lm?.faceContour, in: obs.boundingBox, imageSize: context.imageSize),
                    leftPupil: self.convertRegionPoints(lm?.leftPupil, in: obs.boundingBox, imageSize: context.imageSize),
                    rightPupil: self.convertRegionPoints(lm?.rightPupil, in: obs.boundingBox, imageSize: context.imageSize)
                )
            },
            completion: completion
        )
    }
}
