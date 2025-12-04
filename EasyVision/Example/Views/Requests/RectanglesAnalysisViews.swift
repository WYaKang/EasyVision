import SwiftUI
import EasyVision

struct DetectBarcodesView: View {
    var body: some View {
        VisionDemoView<Any>(title: "条码检测") { image in
            let req = DetectBarcodesRequest()
            let res = try await EasyVision.shared.detect(req, in: image)
            var drawn = image
            for item in res {
                if let newImg = item.draw(on: drawn) { drawn = newImg }
            }
            return res.isEmpty ? nil : drawn
        }
    }
}

struct DetectRectanglesView: View {
    var body: some View {
        VisionDemoView<Any>(title: "矩形检测") { image in
            let req = DetectRectanglesRequest()
            let res = try await EasyVision.shared.detect(req, in: image)
            // DetectRectangleResult 暂无绘制扩展
            EasyVisionLogger.shared.info("Detected \(res.count) rectangles")
            return image
        }
    }
}
