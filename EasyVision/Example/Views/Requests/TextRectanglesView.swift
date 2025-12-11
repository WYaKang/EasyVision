import SwiftUI
import EasyVision
import Vision

struct TextRectanglesView: View {
    @State private var reportCharacterBoxes: Bool = false
    @State private var revision: Int = VNDetectTextRectanglesRequest.defaultRevision
    
    var body: some View {
        VisionDemoView(
            title: "文本检测",
            configView: {
                VStack(alignment: .leading) {
                    Toggle("识别字符边框", isOn: $reportCharacterBoxes)
                        .disabled(revision != VNDetectTextRectanglesRequestRevision1)
                    
                    if revision != VNDetectTextRectanglesRequestRevision1 {
                        Text("字符边框仅在 Revision 1 支持")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("Revision", selection: $revision) {
                        ForEach(VNDetectTextRectanglesRequest.supportedRevisions.sorted(), id: \.self) { rev in
                            Text("Revision \(rev)").tag(rev)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 5)
            },
            performRequest: { image in
                let req = TextRectanglesRequest(
                    config: ImageRequestConfig(revision: revision),
                    reportCharacterBoxes: reportCharacterBoxes
                )
                let res = try await EasyVision.shared.detect(req, in: image)
                
                // 绘制结果
                let imageSize = image.size
                UIGraphicsBeginImageContextWithOptions(imageSize, false, image.scale)
                image.draw(at: .zero)
                let context = UIGraphicsGetCurrentContext()
                context?.setLineWidth(2.0)
                
                for item in res {
                    // 绘制文本块边框
                    context?.setStrokeColor(UIColor.green.cgColor)
                    context?.addRect(item.frame)
                    context?.strokePath()
                    
                    // 绘制字符边框
                    if let charBoxes = item.characterBoxes {
                        context?.setStrokeColor(UIColor.red.cgColor)
                        for charBox in charBoxes {
                            context?.addRect(charBox)
                        }
                        context?.strokePath()
                    }
                }
                
                let drawn = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return res.isEmpty ? nil : drawn
            }
        )
    }
}