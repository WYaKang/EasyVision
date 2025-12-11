import SwiftUI
import Vision
import EasyVision

struct HumanBodyPoseView: View {
    @State private var revision: Int = VNDetectHumanBodyPoseRequest.defaultRevision
    
    var body: some View {
        VisionDemoView(
            title: "人体姿态",
            defaultImageName: "image_pose",
            configView: {
                Picker("Revision", selection: $revision) {
                    ForEach(VNDetectHumanBodyPoseRequest.supportedRevisions.sorted(), id: \.self) { rev in
                        Text("Revision \(rev)").tag(rev)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 5)
            },
            performRequest: { image in
                let req = HumanBodyPoseRequest(config: ImageRequestConfig(revision: revision))
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