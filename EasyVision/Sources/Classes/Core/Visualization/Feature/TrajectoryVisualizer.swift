import UIKit
import Vision

// MARK: - 9. Trajectory Visualization

/// 轨迹可视化器
public struct TrajectoryVisualizer: EasyVisionVisualizer {
    public typealias ResultType = TrajectoryResult
    
    public struct Style {
        public var color: UIColor
        public var lineWidth: CGFloat
        
        public init(color: UIColor = .magenta, lineWidth: CGFloat = 2) {
            self.color = color
            self.lineWidth = lineWidth
        }
    }
    
    public let style: Style
    
    public init(style: Style = Style()) {
        self.style = style
    }
    
    public func draw(_ result: TrajectoryResult, on image: UIImage) -> UIImage? {
        return DrawingContext.perform(on: image) { context in
            context.setStrokeColor(style.color.cgColor)
            context.setLineWidth(style.lineWidth)
            
            if let first = result.normalizedPoints.first {
                context.move(to: first)
                for point in result.normalizedPoints.dropFirst() {
                    context.addLine(to: point)
                }
            }
            context.strokePath()
        }
    }
}

public extension TrajectoryResult {
    func draw(on image: UIImage, color: UIColor = .magenta) -> UIImage? {
        let style = TrajectoryVisualizer.Style(color: color)
        return TrajectoryVisualizer(style: style).draw(self, on: image)
    }
}
