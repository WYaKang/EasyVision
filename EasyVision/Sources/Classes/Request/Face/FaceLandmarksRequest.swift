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
    
    public var constellation: VNRequestFaceLandmarksConstellation = .constellation76Points
    
    public init(config: ImageRequestConfig = ImageRequestConfig(), constellation: VNRequestFaceLandmarksConstellation = .constellation76Points) {
        self.constellation = constellation
        super.init(config: config)
    }
    
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[FaceLandmarksResult], Error>) -> Void) -> VNRequest {
        return create(
            VNDetectFaceLandmarksRequest.self,
            observationType: VNFaceObservation.self,
            configuration: { req in
                req.constellation = self.constellation
            },
            transform: { obs in
                let lm = obs.landmarks
                
                // Helper closure for conversion
                let convert: (VNFaceLandmarkRegion2D?) -> [CGPoint]? = { region in
                    guard let region = region else { return nil }
                    // Use Vision's built-in conversion (returns points in Image Coordinates, origin Bottom-Left)
                    let points = region.pointsInImage(imageSize: context.imageSize)
                    // Convert to UIKit Coordinates (origin Top-Left)
                    return points.map { p in
                        CGPoint(x: p.x, y: context.imageSize.height - p.y)
                    }
                }
                
                return FaceLandmarksResult(
                    frame: self.convertRect(obs.boundingBox, imageSize: context.imageSize),
                    confidence: obs.confidence,
                    leftEye: convert(lm?.leftEye),
                    rightEye: convert(lm?.rightEye),
                    leftEyebrow: convert(lm?.leftEyebrow),
                    rightEyebrow: convert(lm?.rightEyebrow),
                    nose: convert(lm?.nose),
                    noseCrest: convert(lm?.noseCrest),
                    medianLine: convert(lm?.medianLine),
                    outerLips: convert(lm?.outerLips),
                    innerLips: convert(lm?.innerLips),
                    faceContour: convert(lm?.faceContour),
                    leftPupil: convert(lm?.leftPupil),
                    rightPupil: convert(lm?.rightPupil)
                )
            },
            completion: completion
        )
    }
}
