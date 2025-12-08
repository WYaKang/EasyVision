import UIKit
import Vision

// MARK: - 7. Body Pose Visualization

/// 人体姿态可视化器
public struct BodyPoseVisualizer: EasyVisionVisualizer {
    public typealias ResultType = BodyPose2DResult
    
    public struct Style {
        public var pointColor: UIColor
        public var pointRadius: CGFloat
        public var lineColor: UIColor
        public var lineWidth: CGFloat
        
        public init(
            pointColor: UIColor = .red,
            pointRadius: CGFloat = 3,
            lineColor: UIColor = .green,
            lineWidth: CGFloat = 2
        ) {
            self.pointColor = pointColor
            self.pointRadius = pointRadius
            self.lineColor = lineColor
            self.lineWidth = lineWidth
        }
    }
    
    public let style: Style
    
    public init(style: Style = Style()) {
        self.style = style
    }
    
    public func draw(_ result: BodyPose2DResult, on image: UIImage) -> UIImage? {
        return DrawingContext.perform(on: image) { context in
            // Draw Points
            context.setFillColor(style.pointColor.cgColor)
            for point in result.points.values {
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
            context.setStrokeColor(style.lineColor.cgColor)
            context.setLineWidth(style.lineWidth)
            context.addRect(result.frame)
            context.strokePath()
        }
    }
}

public extension BodyPose2DResult {
    func draw(on image: UIImage, pointColor: UIColor = .red, lineColor: UIColor = .green) -> UIImage? {
        let style = BodyPoseVisualizer.Style(pointColor: pointColor, lineColor: lineColor)
        return BodyPoseVisualizer(style: style).draw(self, on: image)
    }
}
