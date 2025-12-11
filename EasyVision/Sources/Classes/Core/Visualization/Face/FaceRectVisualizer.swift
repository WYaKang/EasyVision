import UIKit
import Vision

// MARK: - 1. Face Rect Visualization

/// 人脸矩形可视化器
public struct FaceRectVisualizer: EasyVisionVisualizer {
    public typealias ResultType = FaceRectResult
    
    public struct Style {
        public var color: UIColor
        public var lineWidth: CGFloat
        public var showConfidence: Bool
        public var showAngles: Bool // New
        public var infoFont: UIFont // Renamed/General
        public var infoTextColor: UIColor
        public var infoBackgroundColor: UIColor
        
        public init(
            color: UIColor = .green,
            lineWidth: CGFloat = 5,
            showConfidence: Bool = true,
            showAngles: Bool = true,
            infoFont: UIFont = .boldSystemFont(ofSize: 14),
            infoTextColor: UIColor = .white,
            infoBackgroundColor: UIColor = .black.withAlphaComponent(0.6)
        ) {
            self.color = color
            self.lineWidth = lineWidth
            self.showConfidence = showConfidence
            self.showAngles = showAngles
            self.infoFont = infoFont
            self.infoTextColor = infoTextColor
            self.infoBackgroundColor = infoBackgroundColor
        }
    }
    
    public let style: Style
    
    public init(style: Style = Style()) {
        self.style = style
    }
    
    public func draw(_ result: FaceRectResult, on image: UIImage) -> UIImage? {
        return DrawingContext.perform(on: image) { context in
            // Draw Rect
            context.setStrokeColor(style.color.cgColor)
            context.setLineWidth(style.lineWidth)
            context.addRect(result.frame)
            context.strokePath()
            
            // Prepare Text
            var texts: [String] = []
            if style.showConfidence {
                texts.append(String(format: "Conf: %.2f", result.confidence))
            }
            if style.showAngles {
                if let yaw = result.yawDegrees { texts.append(String(format: "Y: %.0f°", yaw)) }
                if let pitch = result.pitchDegrees { texts.append(String(format: "P: %.0f°", pitch)) }
                if let roll = result.rollDegrees { texts.append(String(format: "R: %.0f°", roll)) }
            }
            
            if !texts.isEmpty {
                let text = texts.joined(separator: " ")
                drawText(text, at: result.frame.origin, context: context)
            }
        }
    }
    
    private func drawText(_ text: String, at point: CGPoint, context: CGContext) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: style.infoFont,
            .foregroundColor: style.infoTextColor,
            .backgroundColor: style.infoBackgroundColor
        ]
        let size = (text as NSString).size(withAttributes: attrs)
        let rect = CGRect(x: point.x, y: max(0, point.y - size.height), width: size.width, height: size.height)
        (text as NSString).draw(in: rect, withAttributes: attrs)
    }
}

public extension FaceRectResult {
    func draw(on image: UIImage, color: UIColor = .green, lineWidth: CGFloat = 5) -> UIImage? {
        let style = FaceRectVisualizer.Style(color: color, lineWidth: lineWidth)
        return FaceRectVisualizer(style: style).draw(self, on: image)
    }
}
