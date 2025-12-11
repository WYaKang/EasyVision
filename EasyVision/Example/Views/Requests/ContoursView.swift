import SwiftUI
import EasyVision
import Vision

struct ContoursView: View {
    @State private var contrastAdjustment: Float = 2.0
    @State private var detectDarkOnLight: Bool = true
    @State private var maxDimension: Int = 512
    @State private var revision: Int = VNDetectContoursRequest.defaultRevision
    
    var body: some View {
        VisionDemoView(
            title: "轮廓检测",
            configView: {
                VStack(alignment: .leading) {
                    HStack {
                        Text("对比度调节: \(String(format: "%.1f", contrastAdjustment))")
                        Slider(value: $contrastAdjustment, in: 0.0...3.0)
                    }
                    
                    Toggle("检测深色(在浅色背景上)", isOn: $detectDarkOnLight)
                    
                    HStack {
                        Text("最大尺寸")
                        Spacer()
                        Picker("", selection: $maxDimension) {
                            Text("512").tag(512)
                            Text("1024").tag(1024)
                            Text("2048").tag(2048)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                    
                    Picker("Revision", selection: $revision) {
                        ForEach(VNDetectContoursRequest.supportedRevisions.sorted(), id: \.self) { rev in
                            Text("Revision \(rev)").tag(rev)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            },
            performRequest: { image in
                let req = DetectContoursRequest(
                    config: ImageRequestConfig(revision: revision),
                    contrastAdjustment: contrastAdjustment,
                    detectDarkOnLight: detectDarkOnLight,
                    maximumImageDimension: maxDimension
                )
                let res = try await EasyVision.shared.detect(req, in: image)
                
                // 绘制结果
                let imageSize = image.size
                UIGraphicsBeginImageContextWithOptions(imageSize, false, image.scale)
                image.draw(at: .zero)
                let context = UIGraphicsGetCurrentContext()
                context?.setStrokeColor(UIColor.green.cgColor)
                context?.setLineWidth(2.0)
                
                for item in res {
                    for contourPoints in item.contours {
                        guard let first = contourPoints.first else { continue }
                        context?.move(to: first)
                        for point in contourPoints.dropFirst() {
                            context?.addLine(to: point)
                        }
                    }
                }
                context?.strokePath()
                let drawn = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return res.isEmpty ? nil : drawn
            }
        )
    }
}