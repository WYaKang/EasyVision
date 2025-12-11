import SwiftUI
import EasyVision
import Vision

struct ClassifyImageView: View {
    @State private var revision: Int = VNClassifyImageRequest.defaultRevision
    
    var body: some View {
        VisionDemoView(
            title: "图像分类",
            configView: {
                Picker("Revision", selection: $revision) {
                    ForEach(VNClassifyImageRequest.supportedRevisions.sorted(), id: \.self) { rev in
                        Text("Revision \(rev)").tag(rev)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 5)
            },
            performRequest: { image in
                let req = ClassifyImageRequest(config: ImageRequestConfig(revision: revision))
                let res = try await EasyVision.shared.detect(req, in: image)
                
                let topRes = res.sorted(by: { $0.confidence > $1.confidence }).prefix(5)
                
                let imageSize = image.size
                UIGraphicsBeginImageContextWithOptions(imageSize, false, image.scale)
                image.draw(at: .zero)
                
                // 在左上角绘制分类结果
                let attr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 18, weight: .bold),
                    .foregroundColor: UIColor.white,
                    .backgroundColor: UIColor.black.withAlphaComponent(0.6)
                ]
                
                var yOffset: CGFloat = 20
                for item in topRes {
                    let text = "\(item.identifier): \(Int(item.confidence * 100))%" as NSString
                    text.draw(at: CGPoint(x: 20, y: yOffset), withAttributes: attr)
                    yOffset += 30
                }
                
                let drawn = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return drawn
            }
        )
    }
}
