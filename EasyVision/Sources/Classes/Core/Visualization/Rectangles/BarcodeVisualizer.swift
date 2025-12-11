import UIKit
import Vision

// MARK: - 4. Barcode Visualization

/// 条码可视化器
public struct BarcodeVisualizer: EasyVisionVisualizer {
    public typealias ResultType = BarcodeResult
    
    public struct Style {
        public var color: UIColor
        public var lineWidth: CGFloat
        public var showPayload: Bool
        public var payloadFont: UIFont
        public var payloadColor: UIColor
        public var payloadBackgroundColor: UIColor
        
        public init(
            color: UIColor = .blue,
            lineWidth: CGFloat = 5,
            showPayload: Bool = true,
            payloadFont: UIFont = .systemFont(ofSize: 24),
            payloadColor: UIColor = .white,
            payloadBackgroundColor: UIColor? = nil
        ) {
            self.color = color
            self.lineWidth = lineWidth
            self.showPayload = showPayload
            self.payloadFont = payloadFont
            self.payloadColor = payloadColor
            self.payloadBackgroundColor = payloadBackgroundColor ?? color.withAlphaComponent(0.7)
        }
    }
    
    public let style: Style
    
    public init(style: Style = Style()) {
        self.style = style
    }
    
    public func draw(_ result: BarcodeResult, on image: UIImage) -> UIImage? {
        return DrawingContext.perform(on: image) { context in
            context.setStrokeColor(style.color.cgColor)
            context.setLineWidth(style.lineWidth)
            context.addRect(result.frame)
            context.strokePath()
            
            if style.showPayload, let payload = result.payload {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: style.payloadFont,
                    .foregroundColor: style.payloadColor,
                    .backgroundColor: style.payloadBackgroundColor
                ]
                
                let textHeight = ("A" as NSString).size(withAttributes: attrs).height + 10
                let textRect = CGRect(
                    x: result.frame.minX,
                    y: result.frame.maxY,
                    width: result.frame.width,
                    height: textHeight
                )
                (payload as NSString).draw(in: textRect, withAttributes: attrs)
            }
        }
    }
}

public extension BarcodeResult {
    func draw(on image: UIImage, color: UIColor = .blue, lineWidth: CGFloat = 5) -> UIImage? {
        let style = BarcodeVisualizer.Style(color: color, lineWidth: lineWidth)
        return BarcodeVisualizer(style: style).draw(self, on: image)
    }
}