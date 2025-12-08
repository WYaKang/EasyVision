import UIKit
import Vision

// MARK: - 13. Human Rect Visualization

public struct HumanRectVisualizer: EasyVisionVisualizer {
    public typealias ResultType = HumanRectResult
    public struct Style {
        public var color: UIColor
        public var lineWidth: CGFloat
        public init(color: UIColor = .yellow, lineWidth: CGFloat = 3) {
            self.color = color
            self.lineWidth = lineWidth
        }
    }
    public let style: Style
    public init(style: Style = Style()) { self.style = style }
    
    public func draw(_ result: HumanRectResult, on image: UIImage) -> UIImage? {
        return DrawingContext.perform(on: image) { context in
            context.setStrokeColor(style.color.cgColor)
            context.setLineWidth(style.lineWidth)
            context.addRect(result.frame)
            context.strokePath()
        }
    }
}

public extension HumanRectResult {
    func draw(on image: UIImage, color: UIColor = .yellow) -> UIImage? {
        let style = HumanRectVisualizer.Style(color: color)
        return HumanRectVisualizer(style: style).draw(self, on: image)
    }
}
