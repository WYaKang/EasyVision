import SwiftUI
import Vision
import EasyVision

struct HumanBodyPose3DView: View {
    @State private var revision: Int = 1
    
    var body: some View {
        VisionDemoView(
            title: "人体3D姿态",
            defaultImageName: "image_pose",
            configView: {
                if #available(iOS 17.0, *) {
                    Picker("Revision", selection: $revision) {
                        ForEach(VNDetectHumanBodyPose3DRequest.supportedRevisions.sorted(), id: \.self) { rev in
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
                if #available(iOS 17.0, *) {
                    let req = HumanBodyPose3DRequest(config: ImageRequestConfig(revision: revision))
                    let res = try await EasyVision.shared.detect(req, in: image)
                    
                    let imageSize = image.size
                    UIGraphicsBeginImageContextWithOptions(imageSize, false, image.scale)
                    image.draw(at: .zero)
                    let context = UIGraphicsGetCurrentContext()
                    context?.setStrokeColor(UIColor.purple.cgColor)
                    context?.setLineWidth(3.0)
                    
                    for item in res {
                        // 绘制 2D 投影点
                        for p in item.points2D.values {
                            let rect = CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6)
                            context?.addEllipse(in: rect)
                        }
                        context?.strokePath()
                        
                        // 显示身高估算
                        let text = "Height: \(String(format: "%.2f", item.bodyHeight))m" as NSString
                        let attr: [NSAttributedString.Key: Any] = [
                            .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                            .foregroundColor: UIColor.white,
                            .backgroundColor: UIColor.purple.withAlphaComponent(0.6)
                        ]
                        text.draw(at: CGPoint(x: item.frame.minX, y: max(0, item.frame.minY - 30)), withAttributes: attr)
                    }
                    
                    let drawn = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    return drawn
                } else {
                    EasyVisionLogger.shared.info("BodyPose3D requires iOS 17+")
                    return nil
                }
            }
        )
    }
}