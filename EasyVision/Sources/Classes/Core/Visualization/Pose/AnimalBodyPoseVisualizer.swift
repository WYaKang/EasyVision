import UIKit
import Vision

// MARK: - 11. Animal Body Pose Visualization

/// 动物姿态可视化器
public struct AnimalBodyPoseVisualizer: EasyVisionVisualizer {
    public typealias ResultType = AnimalBodyPoseResult
    
    public struct Style {
        public var pointColor: UIColor
        public var pointRadius: CGFloat
        
        public init(pointColor: UIColor = .cyan, pointRadius: CGFloat = 4) {
            self.pointColor = pointColor
            self.pointRadius = pointRadius
        }
    }
    
    public let style: Style
    
    public init(style: Style = Style()) {
        self.style = style
    }
    
    public func draw(_ result: AnimalBodyPoseResult, on image: UIImage) -> UIImage? {
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

public extension AnimalBodyPoseResult {
    func draw(on image: UIImage, pointColor: UIColor = .cyan) -> UIImage? {
        let style = AnimalBodyPoseVisualizer.Style(pointColor: pointColor)
        return AnimalBodyPoseVisualizer(style: style).draw(self, on: image)
    }
}
