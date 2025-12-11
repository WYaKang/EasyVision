import SwiftUI
import EasyVision
import Vision

struct RecognizeTextView: View {
    @State private var recognitionLevel: VNRequestTextRecognitionLevel = .accurate
    @State private var usesLanguageCorrection: Bool = true
    @State private var revision: Int = VNRecognizeTextRequest.defaultRevision
    
    var body: some View {
        VisionDemoView(
            title: "文字识别",
            configView: {
                VStack(alignment: .leading) {
                    Picker("识别精度", selection: $recognitionLevel) {
                        Text("Accurate").tag(VNRequestTextRecognitionLevel.accurate)
                        Text("Fast").tag(VNRequestTextRecognitionLevel.fast)
                    }
                    .pickerStyle(.segmented)
                    
                    Toggle("语言校正", isOn: $usesLanguageCorrection)
                    
                    Picker("Revision", selection: $revision) {
                        ForEach(VNRecognizeTextRequest.supportedRevisions.sorted(), id: \.self) { rev in
                            Text("Revision \(rev)").tag(rev)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            },
            performRequest: { image in
                let req = RecognizeTextRequest(
                    config: ImageRequestConfig(revision: revision),
                    recognitionLevel: recognitionLevel,
                    usesLanguageCorrection: usesLanguageCorrection
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