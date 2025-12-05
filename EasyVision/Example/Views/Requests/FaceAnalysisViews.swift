import SwiftUI
import EasyVision

struct FaceRectView: View {
    var body: some View {
        VisionDemoView<Any>(title: "人脸检测", defaultImageName: "image_face") { image in
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
        VisionDemoView<Any>(title: "关键点检测", defaultImageName: "image_face") { image in
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
        VisionDemoView<Any>(title: "人脸质量", defaultImageName: "image_face") { image in
            let req = FaceCaptureQualityRequest()
            let res = try await EasyVision.shared.detect(req, in: image)
            
            var drawn = image
            for item in res {
                if let newImg = item.draw(on: drawn) { drawn = newImg }
            }
            
            if let first = res.first {
                EasyVisionLogger.shared.info("Face Quality Score: \(first.quality ?? 0)")
            }
            return res.isEmpty ? nil : drawn
        }
    }
}
