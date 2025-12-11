import SwiftUI
import EasyVision
import Vision

struct FaceQualityView: View {
    // Quality Revision 1 & 2 are common on iOS 15. Revision 3 is newer (iOS 17+).
    // Using Rev 2 as default.
    @State private var revision: Int = VNDetectFaceCaptureQualityRequestRevision2
    
    private var revisions: [(String, Int)] {
        var revs = [
            ("Rev 1", VNDetectFaceCaptureQualityRequestRevision1),
            ("Rev 2", VNDetectFaceCaptureQualityRequestRevision2)
        ]
        if #available(iOS 17.0, *) {
            revs.append(("Rev 3", VNDetectFaceCaptureQualityRequestRevision3))
        }
        return revs
    }
    
    var body: some View {
        VisionDemoView(
            title: "人脸质量",
            defaultImageName: "image_face",
            configView: {
                VStack(alignment: .leading) {
                    Text("Revision")
                        .font(.caption)
                    Picker("Revision", selection: $revision) {
                        ForEach(revisions, id: \.1) { name, val in
                            Text(name).tag(val)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            },
            performRequest: { image in
                let req = FaceCaptureQualityRequest()
                req.config.revision = revision
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
        )
    }
}
