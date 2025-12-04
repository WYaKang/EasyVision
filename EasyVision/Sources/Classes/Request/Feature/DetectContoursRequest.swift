import UIKit
import Vision

public struct ContourResult {
    /// 轮廓点集合（像素坐标）
    /// 数组中每个元素代表一条闭合或非闭合路径
    public let contours: [[CGPoint]]
    /// 原始归一化路径计数
    public let contourCount: Int
}

public class DetectContoursRequest: ImageBasedRequest<ContourResult> {
    public var contrastAdjustment: Float?
    public var detectDarkOnLight: Bool?
    public var maximumImageDimension: Int?
    
    public init(config: ImageRequestConfig = ImageRequestConfig(), contrastAdjustment: Float? = nil, detectDarkOnLight: Bool? = nil, maximumImageDimension: Int? = nil) {
        self.contrastAdjustment = contrastAdjustment
        self.detectDarkOnLight = detectDarkOnLight
        self.maximumImageDimension = maximumImageDimension
        super.init(config: config)
    }
    
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[ContourResult], Error>) -> Void) -> VNRequest {
        return create(
            VNDetectContoursRequest.self,
            observationType: VNContoursObservation.self,
            configuration: { req in
                self.applyCommon(req)
                if let v = self.contrastAdjustment { req.contrastAdjustment = v }
                if let v = self.detectDarkOnLight { req.detectsDarkOnLight = v }
                if let v = self.maximumImageDimension { req.maximumImageDimension = v }
            },
            transform: { obs in
                // 递归收集所有层级的轮廓点
                func collect(_ contour: VNContour) -> [[CGPoint]] {
                    var acc: [[CGPoint]] = []
                    let pts = contour.normalizedPoints.map { p in
                        CGPoint(x: CGFloat(p.x) * context.imageSize.width,
                                y: (1 - CGFloat(p.y)) * context.imageSize.height)
                    }
                    acc.append(pts)
                    for child in contour.childContours {
                        acc.append(contentsOf: collect(child))
                    }
                    return acc
                }
                
                let all = obs.topLevelContours.flatMap { collect($0) }
                return ContourResult(contours: all, contourCount: obs.contourCount)
            },
            completion: completion
        )
    }
}
