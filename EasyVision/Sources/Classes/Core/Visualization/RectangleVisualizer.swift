import UIKit
import Vision

// MARK: - 14. Rectangle Visualization

public struct RectangleVisualizer: EasyVisionVisualizer {
    public typealias ResultType = RectangleResult
    public struct Style {
        public var color: UIColor
        public var lineWidth: CGFloat
        public init(color: UIColor = .blue, lineWidth: CGFloat = 3) {
            self.color = color
            self.lineWidth = lineWidth
        }
    }
    public let style: Style
    public init(style: Style = Style()) { self.style = style }
    
    public func draw(_ result: RectangleResult, on image: UIImage) -> UIImage? {
        return DrawingContext.perform(on: image) { context in
            context.setStrokeColor(style.color.cgColor)
            context.setLineWidth(style.lineWidth)
            context.addRect(result.frame)
            context.strokePath()
        }
    }
}

public extension RectangleResult {
    func draw(on image: UIImage, color: UIColor = .blue) -> UIImage? {
        let style = RectangleVisualizer.Style(color: color)
        return RectangleVisualizer(style: style).draw(self, on: image)
    }
}
