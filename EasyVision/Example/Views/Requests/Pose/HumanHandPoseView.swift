import SwiftUI
import Vision
import EasyVision

struct HumanHandPoseView: View {
    @State private var maxHandCount: Int = 2
    @State private var revision: Int = VNDetectHumanHandPoseRequest.defaultRevision
    
    var body: some View {
        VisionDemoView(
            title: "手部姿态",
            defaultImageName: "image_pose",
            configView: {
                VStack(spacing: 10) {
                    Stepper("最大检测手数量: \(maxHandCount)", value: $maxHandCount, in: 1...10)
                    
                    Picker("Revision", selection: $revision) {
                        ForEach(VNDetectHumanHandPoseRequest.supportedRevisions.sorted(), id: \.self) { rev in
                            Text("Revision \(rev)").tag(rev)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 5)
            },
            performRequest: { image in
                let req = HumanHandPoseRequest(
                    config: ImageRequestConfig(revision: revision),
                    maximumHandCount: maxHandCount
                )
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
