import UIKit
import Vision

// MARK: - 10. Face Capture Quality Visualization

/// 人脸质量可视化器
public struct FaceCaptureQualityVisualizer: EasyVisionVisualizer {
    public typealias ResultType = FaceCaptureQualityResult
    
    public struct Style {
        public var color: UIColor
        public var lineWidth: CGFloat
        public var font: UIFont
        public var textColor: UIColor
        public var textBackgroundColor: UIColor
        
        public init(
            color: UIColor = .blue,
            lineWidth: CGFloat = 3,
            font: UIFont = .boldSystemFont(ofSize: 14),
            textColor: UIColor = .white,
            textBackgroundColor: UIColor = .black.withAlphaComponent(0.6)
        ) {
            self.color = color
            self.lineWidth = lineWidth
            self.font = font
            self.textColor = textColor
            self.textBackgroundColor = textBackgroundColor
        }
    }
    
    public let style: Style
    
    public init(style: Style = Style()) {
        self.style = style
    }
    
    public func draw(_ result: FaceCaptureQualityResult, on image: UIImage) -> UIImage? {
        return DrawingContext.perform(on: image) { context in
            context.setStrokeColor(style.color.cgColor)
            context.setLineWidth(style.lineWidth)
            context.addRect(result.frame)
            context.strokePath()
            
            let qualityStr = result.quality.map { String(format: "%.2f", $0) } ?? "N/A"
            let text = "Quality: \(result.qualityLevel) (\(qualityStr))"
            
            let attrs: [NSAttributedString.Key: Any] = [
                .font: style.font,
                .foregroundColor: style.textColor,
                .backgroundColor: style.textBackgroundColor
            ]
            let size = (text as NSString).size(withAttributes: attrs)
            let rect = CGRect(x: result.frame.minX, y: max(0, result.frame.minY - size.height), width: size.width, height: size.height)
            (text as NSString).draw(in: rect, withAttributes: attrs)
        }
    }
}

public extension FaceCaptureQualityResult {
    func draw(on image: UIImage, color: UIColor = .blue) -> UIImage? {
        let style = FaceCaptureQualityVisualizer.Style(color: color)
        return FaceCaptureQualityVisualizer(style: style).draw(self, on: image)
    }
}
