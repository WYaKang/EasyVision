import UIKit
import Vision

// MARK: - Visualization Protocol

/// 基础可视化协议，定义绘制行为
public protocol EasyVisionVisualizer {
    associatedtype ResultType
    
    /// 将结果绘制到图像上
    /// - Parameters:
    ///   - result: 检测结果
    ///   - image: 目标图像
    /// - Returns: 绘制后的新图像
    func draw(_ result: ResultType, on image: UIImage) -> UIImage?
}

// MARK: - Context Helper

/// 内部绘图上下文辅助类
private struct DrawingContext {
    static func perform(on image: UIImage, block: (CGContext) -> Void) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        image.draw(at: .zero)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            EasyVisionLogger.shared.error("Failed to get graphics context")
            return nil
        }
        block(context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

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

// MARK: - 2. Face Landmarks Visualization

/// 人脸关键点可视化器
public struct FaceLandmarksVisualizer: EasyVisionVisualizer {
    public typealias ResultType = FaceLandmarksResult
    
    public struct Style {
        public var pointColor: UIColor
        public var pointRadius: CGFloat
        public var lineColor: UIColor
        public var lineWidth: CGFloat
        public var drawFrame: Bool
        
        public init(
            pointColor: UIColor = .yellow,
            pointRadius: CGFloat = 4,
            lineColor: UIColor = .green,
            lineWidth: CGFloat = 5,
            drawFrame: Bool = true
        ) {
            self.pointColor = pointColor
            self.pointRadius = pointRadius
            self.lineColor = lineColor
            self.lineWidth = lineWidth
            self.drawFrame = drawFrame
        }
    }
    
    public let style: Style
    
    public init(style: Style = Style()) {
        self.style = style
    }
    
    public func draw(_ result: FaceLandmarksResult, on image: UIImage) -> UIImage? {
        return DrawingContext.perform(on: image) { context in
            // Draw Points
            context.setFillColor(style.pointColor.cgColor)
            for point in result.allPoints {
                let rect = CGRect(
                    x: point.x - style.pointRadius,
                    y: point.y - style.pointRadius,
                    width: style.pointRadius * 2,
                    height: style.pointRadius * 2
                )
                context.addEllipse(in: rect)
            }
            context.fillPath()
            
            // Draw Frame
            if style.drawFrame {
                context.setStrokeColor(style.lineColor.cgColor)
                context.setLineWidth(style.lineWidth)
                context.addRect(result.frame)
                context.strokePath()
            }
        }
    }
}

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

// MARK: - 7. Body Pose Visualization

/// 人体姿态可视化器
public struct BodyPoseVisualizer: EasyVisionVisualizer {
    public typealias ResultType = BodyPose2DResult
    
    public struct Style {
        public var pointColor: UIColor
        public var pointRadius: CGFloat
        public var lineColor: UIColor
        public var lineWidth: CGFloat
        
        public init(
            pointColor: UIColor = .red,
            pointRadius: CGFloat = 3,
            lineColor: UIColor = .green,
            lineWidth: CGFloat = 2
        ) {
            self.pointColor = pointColor
            self.pointRadius = pointRadius
            self.lineColor = lineColor
            self.lineWidth = lineWidth
        }
    }
    
    public let style: Style
    
    public init(style: Style = Style()) {
        self.style = style
    }
    
    public func draw(_ result: BodyPose2DResult, on image: UIImage) -> UIImage? {
        return DrawingContext.perform(on: image) { context in
            // Draw Points
            context.setFillColor(style.pointColor.cgColor)
            for point in result.points.values {
                let rect = CGRect(
                    x: point.x - style.pointRadius,
                    y: point.y - style.pointRadius,
                    width: style.pointRadius * 2,
                    height: style.pointRadius * 2
                )
                context.addEllipse(in: rect)
            }
            context.fillPath()
            
            // Draw Frame
            context.setStrokeColor(style.lineColor.cgColor)
            context.setLineWidth(style.lineWidth)
            context.addRect(result.frame)
            context.strokePath()
        }
    }
}

// MARK: - 8. Hand Pose Visualization

/// 手部姿态可视化器
public struct HandPoseVisualizer: EasyVisionVisualizer {
    public typealias ResultType = HandPoseResult
    
    public struct Style {
        public var pointColor: UIColor
        public var pointRadius: CGFloat
        
        public init(pointColor: UIColor = .purple, pointRadius: CGFloat = 2) {
            self.pointColor = pointColor
            self.pointRadius = pointRadius
        }
    }
    
    public let style: Style
    
    public init(style: Style = Style()) {
        self.style = style
    }
    
    public func draw(_ result: HandPoseResult, on image: UIImage) -> UIImage? {
        return DrawingContext.perform(on: image) { context in
            context.setFillColor(style.pointColor.cgColor)
            for point in result.points.values {
                let rect = CGRect(
                    x: point.x - style.pointRadius,
                    y: point.y - style.pointRadius,
                    width: style.pointRadius * 2,
                    height: style.pointRadius * 2
                )
                context.addEllipse(in: rect)
            }
            context.fillPath()
        }
    }
}

// MARK: - 9. Trajectory Visualization

/// 轨迹可视化器
public struct TrajectoryVisualizer: EasyVisionVisualizer {
    public typealias ResultType = TrajectoryResult
    
    public struct Style {
        public var color: UIColor
        public var lineWidth: CGFloat
        
        public init(color: UIColor = .magenta, lineWidth: CGFloat = 2) {
            self.color = color
            self.lineWidth = lineWidth
        }
    }
    
    public let style: Style
    
    public init(style: Style = Style()) {
        self.style = style
    }
    
    public func draw(_ result: TrajectoryResult, on image: UIImage) -> UIImage? {
        return DrawingContext.perform(on: image) { context in
            context.setStrokeColor(style.color.cgColor)
            context.setLineWidth(style.lineWidth)
            
            if let first = result.normalizedPoints.first {
                context.move(to: first)
                for point in result.normalizedPoints.dropFirst() {
                    context.addLine(to: point)
                }
            }
            context.strokePath()
        }
    }
}

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

// MARK: - 11. Animal Body Pose Visualization

/// 动物姿态可视化器
public struct AnimalBodyPoseVisualizer: EasyVisionVisualizer {
    public typealias ResultType = AnimalBodyPoseResult
    
    public struct Style {
        public var pointColor: UIColor
        public var pointRadius: CGFloat
        
        public init(pointColor: UIColor = .cyan, pointRadius: CGFloat = 4) {
            self.pointColor = pointColor
            self.pointRadius = pointRadius
        }
    }
    
    public let style: Style
    
    public init(style: Style = Style()) {
        self.style = style
    }
    
    public func draw(_ result: AnimalBodyPoseResult, on image: UIImage) -> UIImage? {
        return DrawingContext.perform(on: image) { context in
            context.setFillColor(style.pointColor.cgColor)
            for point in result.points.values {
                let rect = CGRect(
                    x: point.x - style.pointRadius,
                    y: point.y - style.pointRadius,
                    width: style.pointRadius * 2,
                    height: style.pointRadius * 2
                )
                context.addEllipse(in: rect)
            }
            context.fillPath()
        }
    }
}

// MARK: - 12. Body Pose 3D Visualization (2D Projection)

/// 3D 人体姿态可视化器 (绘制2D投影)
public struct BodyPose3DVisualizer: EasyVisionVisualizer {
    public typealias ResultType = BodyPose3DResult
    
    public struct Style {
        public var pointColor: UIColor
        public var pointRadius: CGFloat
        public var lineColor: UIColor
        public var lineWidth: CGFloat
        
        public init(pointColor: UIColor = .purple, pointRadius: CGFloat = 5, lineColor: UIColor = .yellow, lineWidth: CGFloat = 2) {
            self.pointColor = pointColor
            self.pointRadius = pointRadius
            self.lineColor = lineColor
            self.lineWidth = lineWidth
        }
    }
    
    public let style: Style
    
    public init(style: Style = Style()) {
        self.style = style
    }
    
    public func draw(_ result: BodyPose3DResult, on image: UIImage) -> UIImage? {
        return DrawingContext.perform(on: image) { context in
            context.setFillColor(style.pointColor.cgColor)
            for point in result.points2D.values {
                let rect = CGRect(
                    x: point.x - style.pointRadius,
                    y: point.y - style.pointRadius,
                    width: style.pointRadius * 2,
                    height: style.pointRadius * 2
                )
                context.addEllipse(in: rect)
            }
            context.fillPath()
            
            // Draw Frame
            context.setStrokeColor(style.lineColor.cgColor)
            context.setLineWidth(style.lineWidth)
            context.addRect(result.frame)
            context.strokePath()
        }
    }
}

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

// MARK: - Backward Compatibility Extensions

public extension FaceRectResult {
    func draw(on image: UIImage, color: UIColor = .green, lineWidth: CGFloat = 5) -> UIImage? {
        let style = FaceRectVisualizer.Style(color: color, lineWidth: lineWidth)
        return FaceRectVisualizer(style: style).draw(self, on: image)
    }
}

public extension FaceLandmarksResult {
    func draw(on image: UIImage, pointColor: UIColor = .yellow, pointRadius: CGFloat = 4, lineWidth: CGFloat = 5) -> UIImage? {
        let style = FaceLandmarksVisualizer.Style(pointColor: pointColor, pointRadius: pointRadius, lineColor: .green, lineWidth: lineWidth)
        return FaceLandmarksVisualizer(style: style).draw(self, on: image)
    }
}

public extension RecognizedTextResult {
    func draw(on image: UIImage, boxColor: UIColor = .red, textColor: UIColor = .white, lineWidth: CGFloat = 5) -> UIImage? {
        let style = RecognizedTextVisualizer.Style(boxColor: boxColor, textColor: textColor, lineWidth: lineWidth)
        return RecognizedTextVisualizer(style: style).draw(self, on: image)
    }
}

public extension BarcodeResult {
    func draw(on image: UIImage, color: UIColor = .blue, lineWidth: CGFloat = 5) -> UIImage? {
        let style = BarcodeVisualizer.Style(color: color, lineWidth: lineWidth)
        return BarcodeVisualizer(style: style).draw(self, on: image)
    }
}

public extension SalientObjectResult {
    func draw(on image: UIImage, color: UIColor = .orange) -> UIImage? {
        let style = SaliencyVisualizer.Style(color: color)
        return SaliencyVisualizer(style: style).draw(self, on: image)
    }
}

public extension ContourResult {
    func draw(on image: UIImage, color: UIColor = .cyan, lineWidth: CGFloat = 1) -> UIImage? {
        let style = ContourVisualizer.Style(color: color, lineWidth: lineWidth)
        return ContourVisualizer(style: style).draw(self, on: image)
    }
}

public extension BodyPose2DResult {
    func draw(on image: UIImage, pointColor: UIColor = .red, lineColor: UIColor = .green) -> UIImage? {
        let style = BodyPoseVisualizer.Style(pointColor: pointColor, lineColor: lineColor)
        return BodyPoseVisualizer(style: style).draw(self, on: image)
    }
}

public extension HandPoseResult {
    func draw(on image: UIImage, pointColor: UIColor = .purple) -> UIImage? {
        let style = HandPoseVisualizer.Style(pointColor: pointColor)
        return HandPoseVisualizer(style: style).draw(self, on: image)
    }
}

public extension TrajectoryResult {
    func draw(on image: UIImage, color: UIColor = .magenta) -> UIImage? {
        let style = TrajectoryVisualizer.Style(color: color)
        return TrajectoryVisualizer(style: style).draw(self, on: image)
    }
}

// MARK: - New Result Extensions

public extension FaceCaptureQualityResult {
    func draw(on image: UIImage, color: UIColor = .blue) -> UIImage? {
        let style = FaceCaptureQualityVisualizer.Style(color: color)
        return FaceCaptureQualityVisualizer(style: style).draw(self, on: image)
    }
}

public extension AnimalBodyPoseResult {
    func draw(on image: UIImage, pointColor: UIColor = .cyan) -> UIImage? {
        let style = AnimalBodyPoseVisualizer.Style(pointColor: pointColor)
        return AnimalBodyPoseVisualizer(style: style).draw(self, on: image)
    }
}

public extension BodyPose3DResult {
    func draw(on image: UIImage, pointColor: UIColor = .purple) -> UIImage? {
        let style = BodyPose3DVisualizer.Style(pointColor: pointColor)
        return BodyPose3DVisualizer(style: style).draw(self, on: image)
    }
}

public extension HumanRectResult {
    func draw(on image: UIImage, color: UIColor = .yellow) -> UIImage? {
        let style = HumanRectVisualizer.Style(color: color)
        return HumanRectVisualizer(style: style).draw(self, on: image)
    }
}

public extension RectangleResult {
    func draw(on image: UIImage, color: UIColor = .blue) -> UIImage? {
        let style = RectangleVisualizer.Style(color: color)
        return RectangleVisualizer(style: style).draw(self, on: image)
    }
}

public extension AnimalRecognitionResult {
    func draw(on image: UIImage, color: UIColor = .orange) -> UIImage? {
        let style = AnimalRecognitionVisualizer.Style(color: color)
        return AnimalRecognitionVisualizer(style: style).draw(self, on: image)
    }
}

public extension ImageClassificationResult {
    func draw(on image: UIImage) -> UIImage? {
        return ClassifyImageVisualizer().draw(self, on: image)
    }
}
