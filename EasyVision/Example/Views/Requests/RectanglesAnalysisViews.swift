import SwiftUI
import EasyVision
import Vision

struct DetectBarcodesView: View {
    @State private var selectedSymbology: String = "All"
    @State private var revision: Int = VNDetectBarcodesRequest.defaultRevision
    
    private let symbologies: [(String, [VNBarcodeSymbology]?)] = [
        ("All", nil),
        ("QR Code", [.qr]),
        ("EAN 13", [.ean13]),
        ("EAN 8", [.ean8]),
        ("UPC E", [.upce]),
        ("PDF417", [.pdf417])
    ]
    
    var body: some View {
        VisionDemoView(
            title: "条码检测",
            configView: {
                VStack(alignment: .leading) {
                    Picker("条码类型", selection: $selectedSymbology) {
                        ForEach(symbologies, id: \.0) { name, _ in
                            Text(name).tag(name)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Picker("Revision", selection: $revision) {
                        ForEach(VNDetectBarcodesRequest.supportedRevisions.sorted(), id: \.self) { rev in
                            Text("Revision \(rev)").tag(rev)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 5)
            },
            performRequest: { image in
                let syms = symbologies.first(where: { $0.0 == selectedSymbology })?.1
                let req = DetectBarcodesRequest(
                    config: ImageRequestConfig(revision: revision),
                    symbologies: syms
                )
                let res = try await EasyVision.shared.detect(req, in: image)
                var drawn = image
                for item in res {
                    if let newImg = item.draw(on: drawn) { drawn = newImg }
                }
                return res.isEmpty ? nil : drawn
            }
        )
    }
}

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

struct DetectHumanRectanglesView: View {
    @State private var upperBodyOnly: Bool = true
    @State private var revision: Int = VNDetectHumanRectanglesRequest.defaultRevision
    
    var body: some View {
        VisionDemoView(
            title: "人体矩形检测",
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

struct ClassifyImageView: View {
    @State private var revision: Int = VNClassifyImageRequest.defaultRevision
    
    var body: some View {
        VisionDemoView(
            title: "图像分类",
            configView: {
                Picker("Revision", selection: $revision) {
                    ForEach(VNClassifyImageRequest.supportedRevisions.sorted(), id: \.self) { rev in
                        Text("Revision \(rev)").tag(rev)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 5)
            },
            performRequest: { image in
                let req = ClassifyImageRequest(config: ImageRequestConfig(revision: revision))
                let res = try await EasyVision.shared.detect(req, in: image)
                
                let topRes = res.sorted(by: { $0.confidence > $1.confidence }).prefix(5)
                
                let imageSize = image.size
                UIGraphicsBeginImageContextWithOptions(imageSize, false, image.scale)
                image.draw(at: .zero)
                
                // 在左上角绘制分类结果
                let attr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 18, weight: .bold),
                    .foregroundColor: UIColor.white,
                    .backgroundColor: UIColor.black.withAlphaComponent(0.6)
                ]
                
                var yOffset: CGFloat = 20
                for item in topRes {
                    let text = "\(item.identifier): \(Int(item.confidence * 100))%" as NSString
                    text.draw(at: CGPoint(x: 20, y: yOffset), withAttributes: attr)
                    yOffset += 30
                }
                
                let drawn = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return drawn
            }
        )
    }
}
