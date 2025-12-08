import UIKit
import Vision

// MARK: - 16. Image Classification Visualization

public struct ClassifyImageVisualizer: EasyVisionVisualizer {
    public typealias ResultType = ImageClassificationResult
    public struct Style {
        public var font: UIFont
        public var textColor: UIColor
        public var backgroundColor: UIColor
        public init(font: UIFont = .boldSystemFont(ofSize: 20), textColor: UIColor = .white, backgroundColor: UIColor = .black.withAlphaComponent(0.5)) {
            self.font = font
            self.textColor = textColor
            self.backgroundColor = backgroundColor
        }
    }
    public let style: Style
    public init(style: Style = Style()) { self.style = style }
    
    public func draw(_ result: ImageClassificationResult, on image: UIImage) -> UIImage? {
        return DrawingContext.perform(on: image) { context in
            let text = "\(result.identifier) (%.2f)"
            let fullText = String(format: text, result.confidence)
            
            let attrs: [NSAttributedString.Key: Any] = [
                .font: style.font,
                .foregroundColor: style.textColor,
                .backgroundColor: style.backgroundColor
            ]
            let size = (fullText as NSString).size(withAttributes: attrs)
            // Draw at bottom center
            let rect = CGRect(x: (image.size.width - size.width) / 2, y: image.size.height - size.height - 20, width: size.width, height: size.height)
            (fullText as NSString).draw(in: rect, withAttributes: attrs)
        }
    }
}

public extension ImageClassificationResult {
    func draw(on image: UIImage) -> UIImage? {
        return ClassifyImageVisualizer().draw(self, on: image)
    }
}
