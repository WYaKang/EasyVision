import SwiftUI
import EasyVision
import Vision

struct DetectRectanglesView: View {
    @State private var minConfidence: Float = 0.5
    @State private var minSize: Float = 0.2
    @State private var quadratureTolerance: Float = 30.0
    @State private var minAspectRatio: Float = 0.5
    @State private var maxAspectRatio: Float = 1.0
    
    var body: some View {
        VisionDemoView(
            title: "矩形检测",
            configView: {
                VStack(alignment: .leading, spacing: 8) {
                    Group {
                        HStack {
                            Text("Min Confidence: \(String(format: "%.2f", minConfidence))")
                            Spacer()
                            Slider(value: $minConfidence, in: 0.0...1.0)
                        }
                        HStack {
                            Text("Min Size: \(String(format: "%.2f", minSize))")
                            Spacer()
                            Slider(value: $minSize, in: 0.0...1.0)
                        }
                        HStack {
                            Text("Quad Tolerance: \(Int(quadratureTolerance))")
                            Spacer()
                            Slider(value: $quadratureTolerance, in: 0.0...45.0)
                        }
                    }
                    Group {
                        HStack {
                            Text("Min Aspect: \(String(format: "%.2f", minAspectRatio))")
                            Spacer()
                            Slider(value: $minAspectRatio, in: 0.0...1.0)
                        }
                        HStack {
                            Text("Max Aspect: \(String(format: "%.2f", maxAspectRatio))")
                            Spacer()
                            Slider(value: $maxAspectRatio, in: 0.0...1.0)
                        }
                    }
                }
                .font(.caption)
            },
            performRequest: { image in
                let req = DetectRectanglesRequest(
                    minimumAspectRatio: minAspectRatio,
                    maximumAspectRatio: maxAspectRatio,
                    quadratureTolerance: quadratureTolerance,
                    minimumSize: minSize,
                    minimumConfidence: minConfidence
                )
                let res = try await EasyVision.shared.detect(req, in: image)
                
                // 绘制结果
                let imageSize = image.size
                UIGraphicsBeginImageContextWithOptions(imageSize, false, image.scale)
                image.draw(at: .zero)
                let context = UIGraphicsGetCurrentContext()
                context?.setStrokeColor(UIColor.green.cgColor)
                context?.setLineWidth(3.0)
                
                for item in res {
                    context?.addRect(item.frame)
                }
                context?.strokePath()
                let drawn = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                EasyVisionLogger.shared.info("Detected \(res.count) rectangles")
                return res.isEmpty ? nil : drawn
            }
        )
    }
}