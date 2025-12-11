import SwiftUI
import EasyVision
import Vision

struct FaceLandmarksView: View {
    @State private var revision: Int = VNDetectFaceLandmarksRequestRevision3
    @State private var constellation: VNRequestFaceLandmarksConstellation = .constellation76Points
    
    private let revisions = [
        ("Rev 1", VNDetectFaceLandmarksRequestRevision1),
        ("Rev 2", VNDetectFaceLandmarksRequestRevision2),
        ("Rev 3", VNDetectFaceLandmarksRequestRevision3)
    ]
    
    private let constellations = [
        ("65 Points", VNRequestFaceLandmarksConstellation.constellation65Points),
        ("76 Points", VNRequestFaceLandmarksConstellation.constellation76Points)
    ]
    
    var body: some View {
        VisionDemoView(
            title: "关键点检测",
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
                    
                    Text("Constellation")
                        .font(.caption)
                    Picker("Constellation", selection: $constellation) {
                        ForEach(constellations, id: \.1) { name, val in
                            Text(name).tag(val)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(revision == VNDetectFaceLandmarksRequestRevision3)
                    
                    if revision == VNDetectFaceLandmarksRequestRevision3 {
                        Text("Revision 3 强制使用 76 点模型")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            },
            performRequest: { image in
                let req = FaceLandmarksRequest()
                //req.config.revision = revision
                //req.constellation = constellation
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
