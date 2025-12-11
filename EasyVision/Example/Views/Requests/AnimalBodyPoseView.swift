import SwiftUI
import Vision
import EasyVision

struct AnimalBodyPoseView: View {
    @State private var revision: Int = VNDetectAnimalBodyPoseRequest.defaultRevision
    
    var body: some View {
        VisionDemoView(
            title: "动物姿态",
            configView: {
                Picker("Revision", selection: $revision) {
                    ForEach(VNDetectAnimalBodyPoseRequest.supportedRevisions.sorted(), id: \.self) { rev in
                        Text("Revision \(rev)").tag(rev)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 5)
            },
            performRequest: { image in
                let req = AnimalBodyPoseRequest(config: ImageRequestConfig(revision: revision))
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