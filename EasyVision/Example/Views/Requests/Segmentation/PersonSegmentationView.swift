import SwiftUI
import Vision
import EasyVision

struct PersonSegmentationView: View {
    @State private var qualityLevel: VNGeneratePersonSegmentationRequest.QualityLevel = .balanced
    @State private var revision: Int = VNGeneratePersonSegmentationRequest.defaultRevision
    
    var body: some View {
        VisionDemoView(
            title: "人体分割",
            configView: {
                VStack(spacing: 10) {
                    Picker("质量等级", selection: $qualityLevel) {
                        Text("Accurate").tag(VNGeneratePersonSegmentationRequest.QualityLevel.accurate)
                        Text("Balanced").tag(VNGeneratePersonSegmentationRequest.QualityLevel.balanced)
                        Text("Fast").tag(VNGeneratePersonSegmentationRequest.QualityLevel.fast)
                    }
                    .pickerStyle(.segmented)
                    
                    Picker("Revision", selection: $revision) {
                        ForEach(VNGeneratePersonSegmentationRequest.supportedRevisions.sorted(), id: \.self) { rev in
                            Text("Revision \(rev)").tag(rev)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 5)
            },
            performRequest: { image in
                let req = GeneratePersonSegmentationRequest(
                    config: ImageRequestConfig(revision: revision),
                    qualityLevel: qualityLevel
                )
                let res = try await EasyVision.shared.detect(req, in: image)
                guard let maskBuffer = res.first?.pixelBuffer else { return nil }
                
                // 将 Mask 混合到原图
                let ciImage = CIImage(cvPixelBuffer: maskBuffer)
                let context = CIContext()
                if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                    // 简单叠加演示：红色蒙版
                    UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
                    image.draw(at: .zero)
                    let ctx = UIGraphicsGetCurrentContext()!
                    ctx.saveGState()
                    ctx.clip(to: CGRect(origin: .zero, size: image.size), mask: cgImage)
                    ctx.setFillColor(UIColor.red.withAlphaComponent(0.5).cgColor)
                    ctx.fill(CGRect(origin: .zero, size: image.size))
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
