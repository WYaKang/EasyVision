import SwiftUI
import EasyVision

struct SaliencyView: View {
    var body: some View {
        VisionDemoView<Any>(title: "显著性检测") { image in
            let req = GenerateAttentionSaliencyRequest()
            let res = try await EasyVision.shared.detect(req, in: image)
            var drawn = image
            for item in res {
                if let newImg = item.draw(on: drawn) { drawn = newImg }
            }
            return res.isEmpty ? nil : drawn
        }
    }
}

struct ContoursView: View {
    var body: some View {
        VisionDemoView<Any>(title: "轮廓检测") { image in
            let req = DetectContoursRequest()
            let res = try await EasyVision.shared.detect(req, in: image)
            var drawn = image
            for item in res {
                if let newImg = item.draw(on: drawn) { drawn = newImg }
            }
            return res.isEmpty ? nil : drawn
        }
    }
}
