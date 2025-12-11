import SwiftUI
import Vision
import EasyVision

struct DocumentSegmentationView: View {
    @State private var revision: Int = VNDetectDocumentSegmentationRequest.defaultRevision
    
    var body: some View {
        VisionDemoView(
            title: "文档分割",
            configView: {
                Picker("Revision", selection: $revision) {
                    ForEach(VNDetectDocumentSegmentationRequest.supportedRevisions.sorted(), id: \.self) { rev in
                        Text("Revision \(rev)").tag(rev)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 5)
            },
            performRequest: { image in
                let req = DetectDocumentSegmentationRequest(config: ImageRequestConfig(revision: revision))
                let res = try await EasyVision.shared.detect(req, in: image)
                
                let imageSize = image.size
                UIGraphicsBeginImageContextWithOptions(imageSize, false, image.scale)
                image.draw(at: .zero)
                let context = UIGraphicsGetCurrentContext()
                context?.setStrokeColor(UIColor.blue.cgColor)
                context?.setLineWidth(3.0)
                context?.setFillColor(UIColor.blue.withAlphaComponent(0.3).cgColor)
                
                for item in res {
                    // 绘制四边形
                    let path = CGMutablePath()
                    path.move(to: item.topLeft)
                    path.addLine(to: item.topRight)
                    path.addLine(to: item.bottomRight)
                    path.addLine(to: item.bottomLeft)
                    path.closeSubpath()
                    
                    context?.addPath(path)
                    context?.drawPath(using: .fillStroke)
                }
                let drawn = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return res.isEmpty ? nil : drawn
            }
        )
    }
}