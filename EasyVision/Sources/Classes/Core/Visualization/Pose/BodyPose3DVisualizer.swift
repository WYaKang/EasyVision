import UIKit
import Vision

// MARK: - 12. Body Pose 3D Visualization (2D Projection)

/// 3D 人体姿态可视化器 (绘制2D投影)
public struct BodyPose3DVisualizer: EasyVisionVisualizer {
    public typealias ResultType = BodyPose3DResult
    
    public struct Style {
        public var pointColor: UIColor
        public var pointRadius: CGFloat
        public var lineColor: UIColor
        public var lineWidth: CGFloat
        
        public init(pointColor: UIColor = .purple, pointRadius: CGFloat = 5, lineColor: UIColor = .yellow, lineWidth: CGFloat = 2) {
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
    
    public func draw(_ result: BodyPose3DResult, on image: UIImage) -> UIImage? {
        return DrawingContext.perform(on: image) { context in
            context.setFillColor(style.pointColor.cgColor)
            for point in result.points2D.values {
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

public extension BodyPose3DResult {
    func draw(on image: UIImage, pointColor: UIColor = .purple) -> UIImage? {
        let style = BodyPose3DVisualizer.Style(pointColor: pointColor)
        return BodyPose3DVisualizer(style: style).draw(self, on: image)
    }
}