import SwiftUI
import Vision
import EasyVision

struct ForegroundInstanceMaskView: View {
    @State private var revision: Int = VNGenerateForegroundInstanceMaskRequest.defaultRevision
    
    var body: some View {
        VisionDemoView(
            title: "前景实例掩膜",
            configView: {
                Picker("Revision", selection: $revision) {
                    ForEach(VNGenerateForegroundInstanceMaskRequest.supportedRevisions.sorted(), id: \.self) { rev in
                        Text("Revision \(rev)").tag(rev)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 5)
            },
            performRequest: { image in
                let req = GenerateForegroundInstanceMaskRequest(config: ImageRequestConfig(revision: revision))
                let res = try await EasyVision.shared.detect(req, in: image)
                guard let result = res.first else { return nil }
                
                let maskBuffer = result.pixelBuffer
                let ciImage = CIImage(cvPixelBuffer: maskBuffer)
                let context = CIContext()
                
                if let cgMask = context.createCGImage(ciImage, from: ciImage.extent) {
                    UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
                    image.draw(at: .zero)
                    
                    // 类似于 PersonInstanceMask，这里简单叠加 Mask
                    let maskImage = UIImage(cgImage: cgMask)
                    maskImage.draw(in: CGRect(origin: .zero, size: image.size), blendMode: .sourceAtop, alpha: 0.5)
                    
                    let blended = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    return blended
                }
                return nil
            }
        )
    }
}
