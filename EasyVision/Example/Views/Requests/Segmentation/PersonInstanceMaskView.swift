import SwiftUI
import Vision
import EasyVision

struct PersonInstanceMaskView: View {
    @State private var revision: Int = VNGeneratePersonInstanceMaskRequest.defaultRevision
    
    var body: some View {
        VisionDemoView(
            title: "多人实例掩膜",
            configView: {
                Picker("Revision", selection: $revision) {
                    ForEach(VNGeneratePersonInstanceMaskRequest.supportedRevisions.sorted(), id: \.self) { rev in
                        Text("Revision \(rev)").tag(rev)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 5)
            },
            performRequest: { image in
                let req = GeneratePersonInstanceMaskRequest(config: ImageRequestConfig(revision: revision))
                let res = try await EasyVision.shared.detect(req, in: image)
                guard let result = res.first else { return nil }
                
                let maskBuffer = result.pixelBuffer
                let ciImage = CIImage(cvPixelBuffer: maskBuffer)
                let context = CIContext()
                
                if let cgMask = context.createCGImage(ciImage, from: ciImage.extent) {
                    UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
                    image.draw(at: .zero)
                    let ctx = UIGraphicsGetCurrentContext()!
                    
                    // 简单的全掩膜叠加，不同实例用不同颜色会更好，但这里做简单处理
                    // Mask 像素值代表实例 ID (0 是背景)
                    // 这里我们直接将 Mask 可视化叠加
                    
                    ctx.saveGState()
                    // 注意：InstanceMask 是 uint8 或 uint16，直接作为 Mask 可能需要处理
                    // 这里简化，直接绘制 Mask 的可视表示
                    // 实际应该遍历像素根据 ID 染色
                    
                    // 临时方案：将 Mask 绘制为半透明覆盖层
                    // 由于 CoreGraphics Mask 行为，这里直接绘制 Mask 图像可能看不出实例区别
                    // 我们尝试将 Mask 转换为可视化图像
                    
                    // 为了演示，我们假设 Mask 非 0 区域都染成绿色
                    // 需要更复杂的像素处理才能区分实例颜色
                    
                    // 这里仅做简单的 Mask 叠加
                    let maskImage = UIImage(cgImage: cgMask)
                    maskImage.draw(in: CGRect(origin: .zero, size: image.size), blendMode: .sourceAtop, alpha: 0.5)
                    
                    ctx.restoreGState()
                    
                    let blended = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    return blended
                }
                return nil
            }
        )
    }
}
