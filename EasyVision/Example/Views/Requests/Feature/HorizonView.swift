import SwiftUI
import EasyVision
import Vision

struct HorizonView: View {
    @State private var revision: Int = VNDetectHorizonRequest.defaultRevision
    
    var body: some View {
        VisionDemoView(
            title: "地平线检测",
            configView: {
                Picker("Revision", selection: $revision) {
                    ForEach(VNDetectHorizonRequest.supportedRevisions.sorted(), id: \.self) { rev in
                        Text("Revision \(rev)").tag(rev)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 5)
            },
            performRequest: { image in
                let req = DetectHorizonRequest(config: ImageRequestConfig(revision: revision))
                let res = try await EasyVision.shared.detect(req, in: image)
                guard let horizon = res.first else { return nil }
                
                let imageSize = image.size
                UIGraphicsBeginImageContextWithOptions(imageSize, false, image.scale)
                image.draw(at: .zero)
                let context = UIGraphicsGetCurrentContext()
                
                context?.setStrokeColor(UIColor.green.cgColor)
                context?.setLineWidth(3.0)
                
                // 绘制地平线
                // VN 角度是顺时针偏离水平线的弧度
                let angle = horizon.angleRadians
                let center = CGPoint(x: imageSize.width / 2, y: imageSize.height / 2)
                let length = max(imageSize.width, imageSize.height)
                
                context?.saveGState()
                context?.translateBy(x: center.x, y: center.y)
                context?.rotate(by: angle) // Vision 的 angle 方向
                
                context?.move(to: CGPoint(x: -length, y: 0))
                context?.addLine(to: CGPoint(x: length, y: 0))
                context?.strokePath()
                context?.restoreGState()
                
                let drawn = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                EasyVisionLogger.shared.info("Horizon Angle: \(angle * 180 / .pi) degrees")
                return drawn
            }
        )
    }
}
