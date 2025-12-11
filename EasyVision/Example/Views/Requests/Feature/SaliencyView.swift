import SwiftUI
import EasyVision
import Vision

struct SaliencyView: View {
    @State private var useObjectness: Bool = false
    @State private var revision: Int = VNGenerateObjectnessBasedSaliencyImageRequest.defaultRevision
    
    var body: some View {
        VisionDemoView(
            title: "显著性检测",
            configView: {
                VStack(spacing: 10) {
                    Toggle("使用 Objectness (vs Attention)", isOn: $useObjectness)
                    
                    Picker("Revision", selection: $revision) {
                        if useObjectness {
                            ForEach(VNGenerateObjectnessBasedSaliencyImageRequest.supportedRevisions.sorted(), id: \.self) { rev in
                                Text("Revision \(rev)").tag(rev)
                            }
                        } else {
                            ForEach(VNGenerateAttentionBasedSaliencyImageRequest.supportedRevisions.sorted(), id: \.self) { rev in
                                Text("Revision \(rev)").tag(rev)
                            }
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 5)
            },
            performRequest: { image in
                let res: [SalientObjectResult]
                if useObjectness {
                    let req = GenerateObjectnessSaliencyRequest(config: ImageRequestConfig(revision: revision))
                    res = try await EasyVision.shared.detect(req, in: image)
                } else {
                    let req = GenerateAttentionSaliencyRequest(config: ImageRequestConfig(revision: revision))
                    res = try await EasyVision.shared.detect(req, in: image)
                }
                
                // 绘制结果
                let imageSize = image.size
                UIGraphicsBeginImageContextWithOptions(imageSize, false, image.scale)
                image.draw(at: .zero)
                let context = UIGraphicsGetCurrentContext()
                context?.setStrokeColor(useObjectness ? UIColor.blue.cgColor : UIColor.red.cgColor)
                context?.setLineWidth(3.0)
                
                for item in res {
                    context?.addRect(item.frame)
                }
                context?.strokePath()
                
                // 叠加热力图 (如果有)
                if let first = res.first, let pixelBuffer = first.pixelBuffer {
                    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                    let ciContext = CIContext()
                    if let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) {
                        let maskImage = UIImage(cgImage: cgImage)
                        maskImage.draw(in: CGRect(origin: .zero, size: imageSize), blendMode: .multiply, alpha: 0.6)
                    }
                }
                
                let drawn = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return res.isEmpty ? nil : drawn
            }
        )
        .onChange(of: useObjectness) { newValue in
            // 重置 Revision，防止不兼容
            if newValue {
                revision = VNGenerateObjectnessBasedSaliencyImageRequest.defaultRevision
            } else {
                revision = VNGenerateAttentionBasedSaliencyImageRequest.defaultRevision
            }
        }
    }
}
