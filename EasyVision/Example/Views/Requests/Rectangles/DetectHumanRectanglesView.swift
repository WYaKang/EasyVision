import SwiftUI
import EasyVision
import Vision

struct DetectHumanRectanglesView: View {
    @State private var upperBodyOnly: Bool = true
    @State private var revision: Int = VNDetectHumanRectanglesRequest.defaultRevision
    
    var body: some View {
        VisionDemoView(
            title: "人体矩形检测",
            defaultImageName: "image_pose",
            configView: {
                VStack(alignment: .leading) {
                    Toggle("仅上半身", isOn: $upperBodyOnly)
                    
                    Picker("Revision", selection: $revision) {
                        ForEach(VNDetectHumanRectanglesRequest.supportedRevisions.sorted(), id: \.self) { rev in
                            Text("Revision \(rev)").tag(rev)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 5)
            },
            performRequest: { image in
                let req = DetectHumanRectanglesRequest(
                    config: ImageRequestConfig(revision: revision),
                    upperBodyOnly: upperBodyOnly
                )
                let res = try await EasyVision.shared.detect(req, in: image)
                
                // 绘制结果
                let imageSize = image.size
                UIGraphicsBeginImageContextWithOptions(imageSize, false, image.scale)
                image.draw(at: .zero)
                let context = UIGraphicsGetCurrentContext()
                context?.setStrokeColor(UIColor.yellow.cgColor)
                context?.setLineWidth(3.0)
                
                for item in res {
                    context?.addRect(item.frame)
                }
                context?.strokePath()
                let drawn = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                return res.isEmpty ? nil : drawn
            }
        )
    }
}
