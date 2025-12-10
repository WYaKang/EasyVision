import SwiftUI
import EasyVision
import Vision

struct SaliencyView: View {
    @State private var useObjectness: Bool = false
    @State private var revision: Int = VNGenerateObjectnessBasedSaliencyImageRequest.defaultRevision
    
    var body: some View {
        VisionDemoView(
            title: "显著性检测",
            configView: {
                VStack(spacing: 10) {
                    Toggle("使用 Objectness (vs Attention)", isOn: $useObjectness)
                    
                    Picker("Revision", selection: $revision) {
                        if useObjectness {
                            ForEach(VNGenerateObjectnessBasedSaliencyImageRequest.supportedRevisions.sorted(), id: \.self) { rev in
                                Text("Revision \(rev)").tag(rev)
                            }
                        } else {
                            ForEach(VNGenerateAttentionBasedSaliencyImageRequest.supportedRevisions.sorted(), id: \.self) { rev in
                                Text("Revision \(rev)").tag(rev)
                            }
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 5)
            },
            performRequest: { image in
                let res: [SalientObjectResult]
                if useObjectness {
                    let req = GenerateObjectnessSaliencyRequest(config: ImageRequestConfig(revision: revision))
                    res = try await EasyVision.shared.detect(req, in: image)
                } else {
                    let req = GenerateAttentionSaliencyRequest(config: ImageRequestConfig(revision: revision))
                    res = try await EasyVision.shared.detect(req, in: image)
                }
                
                // 绘制结果
                let imageSize = image.size
                UIGraphicsBeginImageContextWithOptions(imageSize, false, image.scale)
                image.draw(at: .zero)
                let context = UIGraphicsGetCurrentContext()
                context?.setStrokeColor(useObjectness ? UIColor.blue.cgColor : UIColor.red.cgColor)
                context?.setLineWidth(3.0)
                
                for item in res {
                    context?.addRect(item.frame)
                }
                context?.strokePath()
                
                // 叠加热力图 (如果有)
                if let first = res.first, let pixelBuffer = first.pixelBuffer {
                    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                    let ciContext = CIContext()
                    if let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) {
                        let maskImage = UIImage(cgImage: cgImage)
                        maskImage.draw(in: CGRect(origin: .zero, size: imageSize), blendMode: .multiply, alpha: 0.6)
                    }
                }
                
                let drawn = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return res.isEmpty ? nil : drawn
            }
        )
        .onChange(of: useObjectness) { newValue in
            // 重置 Revision，防止不兼容
            if newValue {
                revision = VNGenerateObjectnessBasedSaliencyImageRequest.defaultRevision
            } else {
                revision = VNGenerateAttentionBasedSaliencyImageRequest.defaultRevision
            }
        }
    }
}

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
