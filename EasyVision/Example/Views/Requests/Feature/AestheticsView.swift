import SwiftUI
import EasyVision
import Vision

struct AestheticsView: View {
    @State private var revision: Int = 1
    
    var body: some View {
        VisionDemoView(
            title: "美学评分",
            configView: {
                if #available(iOS 18.0, *) {
                    Picker("Revision", selection: $revision) {
                        ForEach(VNCalculateImageAestheticsScoresRequest.supportedRevisions.sorted(), id: \.self) { rev in
                            Text("Revision \(rev)").tag(rev)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 5)
                } else {
                    EmptyView()
                }
            },
            performRequest: { image in
                if #available(iOS 18.0, *) {
                    let req = CalculateImageAestheticsScoresRequest(config: ImageRequestConfig(revision: revision))
                    // 由于 Request 内部可能有 iOS 版本限制，我们在外部也保护一下
                    // 实际上 EasyVision 封装应该处理好，但这里为了演示 Demo
                    do {
                        let res = try await EasyVision.shared.detect(req, in: image)
                        guard let score = res.first else { return nil }
                        
                        let imageSize = image.size
                        UIGraphicsBeginImageContextWithOptions(imageSize, false, image.scale)
                        image.draw(at: .zero)
                        
                        let text = "Score: \(String(format: "%.2f", score.overallScore))\nUtility: \(score.isUtility)" as NSString
                        let attr: [NSAttributedString.Key: Any] = [
                            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                            .foregroundColor: UIColor.white,
                            .backgroundColor: UIColor.black.withAlphaComponent(0.6)
                        ]
                        let textSize = text.size(withAttributes: attr)
                        text.draw(in: CGRect(x: 20, y: 40, width: textSize.width, height: textSize.height), withAttributes: attr)
                        
                        let drawn = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                        return drawn
                    } catch {
                        EasyVisionLogger.shared.error("Aesthetics error: \(error)")
                        return nil
                    }
                } else {
                    EasyVisionLogger.shared.info("Aesthetics requires iOS 18+")
                    return nil
                }
            }
        )
    }
}
