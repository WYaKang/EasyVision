import UIKit
import Vision

// MARK: - 3. Text Visualization

/// 文本识别可视化器
public struct RecognizedTextVisualizer: EasyVisionVisualizer {
    public typealias ResultType = RecognizedTextResult
    
    public struct Style {
        public var boxColor: UIColor
        public var textColor: UIColor
        public var textFont: UIFont
        public var textBackgroundColor: UIColor
        public var lineWidth: CGFloat
        
        public init(
            boxColor: UIColor = .red,
            textColor: UIColor = .white,
            textFont: UIFont = .boldSystemFont(ofSize: 24),
            textBackgroundColor: UIColor? = nil,
            lineWidth: CGFloat = 5
        ) {
            self.boxColor = boxColor
            self.textColor = textColor
            self.textFont = textFont
            self.textBackgroundColor = textBackgroundColor ?? boxColor.withAlphaComponent(0.6)
            self.lineWidth = lineWidth
        }
    }
    
    public let style: Style
    
    public init(style: Style = Style()) {
        self.style = style
    }
    
    public func draw(_ result: RecognizedTextResult, on image: UIImage) -> UIImage? {
        return DrawingContext.perform(on: image) { context in
            // Draw Box
            context.setStrokeColor(style.boxColor.cgColor)
            context.setLineWidth(style.lineWidth)
            context.addRect(result.frame)
            context.strokePath()
            
            // Draw Text
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            
            let attrs: [NSAttributedString.Key: Any] = [
                .font: style.textFont,
                .foregroundColor: style.textColor,
                .backgroundColor: style.textBackgroundColor,
                .paragraphStyle: paragraphStyle
            ]
            
            // Calculate text height
            let textHeight = ("A" as NSString).size(withAttributes: attrs).height + 10
            let textRect = CGRect(
                x: result.frame.minX,
                y: max(0, result.frame.minY - textHeight),
                width: result.frame.width,
                height: textHeight
            )
            
            (result.text as NSString).draw(in: textRect, withAttributes: attrs)
        }
    }
}

public extension RecognizedTextResult {
    func draw(on image: UIImage, boxColor: UIColor = .red, textColor: UIColor = .white, lineWidth: CGFloat = 5) -> UIImage? {
        let style = RecognizedTextVisualizer.Style(boxColor: boxColor, textColor: textColor, lineWidth: lineWidth)
        return RecognizedTextVisualizer(style: style).draw(self, on: image)
    }
}
