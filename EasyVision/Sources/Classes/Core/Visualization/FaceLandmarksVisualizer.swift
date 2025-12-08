import UIKit
import Vision

// MARK: - 2. Face Landmarks Visualization

/// 人脸关键点可视化器
public struct FaceLandmarksVisualizer: EasyVisionVisualizer {
    public typealias ResultType = FaceLandmarksResult
    
    public struct Style {
        public var pointColor: UIColor
        public var pointRadius: CGFloat
        public var lineColor: UIColor
        public var lineWidth: CGFloat
        public var drawFrame: Bool
        
        public init(
            pointColor: UIColor = .yellow,
            pointRadius: CGFloat = 4,
            lineColor: UIColor = .green,
            lineWidth: CGFloat = 5,
            drawFrame: Bool = true
        ) {
            self.pointColor = pointColor
            self.pointRadius = pointRadius
            self.lineColor = lineColor
            self.lineWidth = lineWidth
            self.drawFrame = drawFrame
        }
    }
    
    public let style: Style
    
    public init(style: Style = Style()) {
        self.style = style
    }
    
    public func draw(_ result: FaceLandmarksResult, on image: UIImage) -> UIImage? {
        return DrawingContext.perform(on: image) { context in
            // Draw Points
            context.setFillColor(style.pointColor.cgColor)
            for point in result.allPoints {
                let rect = CGRect(
                    x: point.x - style.pointRadius,
                    y: point.y - style.pointRadius,
                    width: style.pointRadius * 2,
                    height: style.pointRadius * 2
                )
                context.addEllipse(in: rect)
            }
            context.fillPath()
            
            // Draw Frame
            if style.drawFrame {
                context.setStrokeColor(style.lineColor.cgColor)
                context.setLineWidth(style.lineWidth)
                context.addRect(result.frame)
                context.strokePath()
            }
        }
    }
}

public extension FaceLandmarksResult {
    func draw(on image: UIImage, pointColor: UIColor = .yellow, pointRadius: CGFloat = 4, lineWidth: CGFloat = 5) -> UIImage? {
        let style = FaceLandmarksVisualizer.Style(pointColor: pointColor, pointRadius: pointRadius, lineColor: .green, lineWidth: lineWidth)
        return FaceLandmarksVisualizer(style: style).draw(self, on: image)
    }
}
