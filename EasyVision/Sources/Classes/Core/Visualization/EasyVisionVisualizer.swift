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
struct DrawingContext {
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
