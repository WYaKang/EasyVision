import UIKit
import Vision

// MARK: - 15. Animal Recognition Visualization

public struct AnimalRecognitionVisualizer: EasyVisionVisualizer {
    public typealias ResultType = AnimalRecognitionResult
    public struct Style {
        public var color: UIColor
        public var lineWidth: CGFloat
        public var font: UIFont
        public var textColor: UIColor
        public init(color: UIColor = .orange, lineWidth: CGFloat = 3, font: UIFont = .boldSystemFont(ofSize: 14), textColor: UIColor = .white) {
            self.color = color
            self.lineWidth = lineWidth
            self.font = font
            self.textColor = textColor
        }
    }
    public let style: Style
    public init(style: Style = Style()) { self.style = style }
    
    public func draw(_ result: AnimalRecognitionResult, on image: UIImage) -> UIImage? {
        return DrawingContext.perform(on: image) { context in
            context.setStrokeColor(style.color.cgColor)
            context.setLineWidth(style.lineWidth)
            context.addRect(result.frame)
            context.strokePath()
            
            let text = "\(result.identifier) (%.2f)".uppercased()
            let fullText = String(format: text, result.confidence)
            
            let attrs: [NSAttributedString.Key: Any] = [
                .font: style.font,
                .foregroundColor: style.textColor,
                .backgroundColor: style.color.withAlphaComponent(0.6)
            ]
            let size = (fullText as NSString).size(withAttributes: attrs)
            let rect = CGRect(x: result.frame.minX, y: max(0, result.frame.minY - size.height), width: size.width, height: size.height)
            (fullText as NSString).draw(in: rect, withAttributes: attrs)
        }
    }
}

public extension AnimalRecognitionResult {
    func draw(on image: UIImage, color: UIColor = .orange) -> UIImage? {
        let style = AnimalRecognitionVisualizer.Style(color: color)
        return AnimalRecognitionVisualizer(style: style).draw(self, on: image)
    }
}