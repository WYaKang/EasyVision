import SwiftUI
import EasyVision

struct FaceRectView: View {
    var body: some View {
        VisionDemoView<Any>(title: "人脸检测") { image in
            let req = FaceRectRequest()
            let res = try await EasyVision.shared.detect(req, in: image)
            var drawn = image
            for item in res {
                if let newImg = item.draw(on: drawn) { drawn = newImg }
            }
            return res.isEmpty ? nil : drawn
        }
    }
}

struct FaceLandmarksView: View {
    var body: some View {
        VisionDemoView<Any>(title: "关键点检测") { image in
            let req = FaceLandmarksRequest()
            let res = try await EasyVision.shared.detect(req, in: image)
            var drawn = image
            for item in res {
                if let newImg = item.draw(on: drawn) { drawn = newImg }
            }
            return res.isEmpty ? nil : drawn
        }
    }
}

struct FaceQualityView: View {
    var body: some View {
        VisionDemoView<Any>(title: "人脸质量") { image in
            let req = FaceCaptureQualityRequest()
            let res = try await EasyVision.shared.detect(req, in: image)
            // 暂无绘制扩展，直接返回原图或后续添加
            // 可以考虑在这里手动绘制分数
            if let first = res.first {
                EasyVisionLogger.shared.info("Face Quality Score: \(first.quality)")
            }
            return image
        }
    }
}
