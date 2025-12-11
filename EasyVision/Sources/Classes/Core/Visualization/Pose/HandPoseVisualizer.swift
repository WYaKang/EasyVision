import UIKit
import Vision

// MARK: - 8. Hand Pose Visualization

/// 手部姿态可视化器
public struct HandPoseVisualizer: EasyVisionVisualizer {
    public typealias ResultType = HandPoseResult
    
    public struct Style {
        public var pointColor: UIColor
        public var pointRadius: CGFloat
        
        public init(pointColor: UIColor = .purple, pointRadius: CGFloat = 2) {
            self.pointColor = pointColor
            self.pointRadius = pointRadius
        }
    }
    
    public let style: Style
    
    public init(style: Style = Style()) {
        self.style = style
    }
    
    public func draw(_ result: HandPoseResult, on image: UIImage) -> UIImage? {
        return DrawingContext.perform(on: image) { context in
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
        }
    }
}

public extension HandPoseResult {
    func draw(on image: UIImage, pointColor: UIColor = .purple) -> UIImage? {
        let style = HandPoseVisualizer.Style(pointColor: pointColor)
        return HandPoseVisualizer(style: style).draw(self, on: image)
    }
}