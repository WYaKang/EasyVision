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
        public var confidenceFont: UIFont
        public var confidenceTextColor: UIColor
        public var confidenceBackgroundColor: UIColor
        
        public init(
            color: UIColor = .green,
            lineWidth: CGFloat = 5,
            showConfidence: Bool = false,
            confidenceFont: UIFont = .boldSystemFont(ofSize: 14),
            confidenceTextColor: UIColor = .white,
            confidenceBackgroundColor: UIColor = .black.withAlphaComponent(0.6)
        ) {
            self.color = color
            self.lineWidth = lineWidth
            self.showConfidence = showConfidence
            self.confidenceFont = confidenceFont
            self.confidenceTextColor = confidenceTextColor
            self.confidenceBackgroundColor = confidenceBackgroundColor
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
            
            // Draw Confidence
            if style.showConfidence {
                let text = String(format: "Conf: %.2f", result.confidence)
                drawText(text, at: result.frame.origin, context: context)
            }
        }
    }
    
    private func drawText(_ text: String, at point: CGPoint, context: CGContext) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: style.confidenceFont,
            .foregroundColor: style.confidenceTextColor,
            .backgroundColor: style.confidenceBackgroundColor
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
