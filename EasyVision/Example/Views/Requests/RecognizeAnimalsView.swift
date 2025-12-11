import SwiftUI
import EasyVision
import Vision

struct RecognizeAnimalsView: View {
    @State private var revision: Int = VNRecognizeAnimalsRequest.defaultRevision
    
    var body: some View {
        VisionDemoView(
            title: "动物识别",
            configView: {
                Picker("Revision", selection: $revision) {
                    ForEach(VNRecognizeAnimalsRequest.supportedRevisions.sorted(), id: \.self) { rev in
                        Text("Revision \(rev)").tag(rev)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 5)
            },
            performRequest: { image in
                let req = RecognizeAnimalsRequest(config: ImageRequestConfig(revision: revision))
                let res = try await EasyVision.shared.detect(req, in: image)
                
                let imageSize = image.size
                UIGraphicsBeginImageContextWithOptions(imageSize, false, image.scale)
                image.draw(at: .zero)
                let context = UIGraphicsGetCurrentContext()
                context?.setLineWidth(3.0)
                
                for item in res {
                    context?.setStrokeColor(UIColor.orange.cgColor)
                    context?.addRect(item.frame)
                    context?.strokePath()
                    
                    // 绘制标签
                    let text = "\(item.identifier) \(Int(item.confidence * 100))%" as NSString
                    let attr: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 16, weight: .bold),
                        .foregroundColor: UIColor.white,
                        .backgroundColor: UIColor.orange.withAlphaComponent(0.7)
                    ]
                    let textSize = text.size(withAttributes: attr)
                    let textRect = CGRect(x: item.frame.origin.x, y: max(0, item.frame.origin.y - textSize.height), width: textSize.width, height: textSize.height)
                    text.draw(in: textRect, withAttributes: attr)
                }
                
                let drawn = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return res.isEmpty ? nil : drawn
            }
        )
    }
}