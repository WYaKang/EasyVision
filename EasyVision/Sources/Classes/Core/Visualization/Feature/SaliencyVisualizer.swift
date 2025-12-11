import UIKit
import Vision

// MARK: - 5. Saliency Visualization

/// 显著性区域可视化器
public struct SaliencyVisualizer: EasyVisionVisualizer {
    public typealias ResultType = SalientObjectResult
    
    public struct Style {
        public var color: UIColor
        public var lineWidth: CGFloat
        
        public init(color: UIColor = .orange, lineWidth: CGFloat = 3) {
            self.color = color
            self.lineWidth = lineWidth
        }
    }
    
    public let style: Style
    
    public init(style: Style = Style()) {
        self.style = style
    }
    
    public func draw(_ result: SalientObjectResult, on image: UIImage) -> UIImage? {
        return DrawingContext.perform(on: image) { context in
            context.setStrokeColor(style.color.cgColor)
            context.setLineWidth(style.lineWidth)
            context.addRect(result.frame)
            context.strokePath()
        }
    }
}

public extension SalientObjectResult {
    func draw(on image: UIImage, color: UIColor = .orange) -> UIImage? {
        let style = SaliencyVisualizer.Style(color: color)
        return SaliencyVisualizer(style: style).draw(self, on: image)
    }
}
