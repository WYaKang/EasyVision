import UIKit
import Vision

// MARK: - 6. Contour Visualization

/// 轮廓可视化器
public struct ContourVisualizer: EasyVisionVisualizer {
    public typealias ResultType = ContourResult
    
    public struct Style {
        public var color: UIColor
        public var lineWidth: CGFloat
        
        public init(color: UIColor = .cyan, lineWidth: CGFloat = 1) {
            self.color = color
            self.lineWidth = lineWidth
        }
    }
    
    public let style: Style
    
    public init(style: Style = Style()) {
        self.style = style
    }
    
    public func draw(_ result: ContourResult, on image: UIImage) -> UIImage? {
        return DrawingContext.perform(on: image) { context in
            context.setStrokeColor(style.color.cgColor)
            context.setLineWidth(style.lineWidth)
            
            for pathPoints in result.contours {
                guard let first = pathPoints.first else { continue }
                context.move(to: first)
                for point in pathPoints.dropFirst() {
                    context.addLine(to: point)
                }
                // Note: Vision contours might not be closed automatically, user decision.
                // Keeping open as per original implementation.
            }
            context.strokePath()
        }
    }
}

public extension ContourResult {
    func draw(on image: UIImage, color: UIColor = .cyan, lineWidth: CGFloat = 1) -> UIImage? {
        let style = ContourVisualizer.Style(color: color, lineWidth: lineWidth)
        return ContourVisualizer(style: style).draw(self, on: image)
    }
}
