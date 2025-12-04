import SwiftUI
import EasyVision

struct HumanBodyPoseView: View {
    var body: some View {
        VisionDemoView<Any>(title: "人体姿态") { image in
            let req = HumanBodyPoseRequest()
            let res = try await EasyVision.shared.detect(req, in: image)
            var drawn = image
            for item in res {
                if let newImg = item.draw(on: drawn) { drawn = newImg }
            }
            return res.isEmpty ? nil : drawn
        }
    }
}

struct HumanHandPoseView: View {
    var body: some View {
        VisionDemoView<Any>(title: "手部姿态") { image in
            let req = HumanHandPoseRequest()
            let res = try await EasyVision.shared.detect(req, in: image)
            var drawn = image
            for item in res {
                if let newImg = item.draw(on: drawn) { drawn = newImg }
            }
            return res.isEmpty ? nil : drawn
        }
    }
}
