import SwiftUI
import EasyVision

struct RecognizeTextView: View {
    var body: some View {
        VisionDemoView<Any>(title: "文字识别") { image in
            let req = RecognizeTextRequest(recognitionLevel: .accurate)
            let res = try await EasyVision.shared.detect(req, in: image)
            var drawn = image
            for item in res {
                if let newImg = item.draw(on: drawn) { drawn = newImg }
            }
            return res.isEmpty ? nil : drawn
        }
    }
}
