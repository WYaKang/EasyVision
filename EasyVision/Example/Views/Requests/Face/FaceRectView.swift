//
//  FaceRectView.swift
//  EasyVision
//
//  Created by yakang wang on 2025/12/8.
//

import SwiftUI
import EasyVision
import Vision

struct FaceRectView: View {
    @State private var revision: Int = VNDetectFaceRectanglesRequestRevision3
    
    // 选项列表
    private let revisions = [
        ("Revision 1", VNDetectFaceRectanglesRequestRevision1),
        ("Revision 2", VNDetectFaceRectanglesRequestRevision2),
        ("Revision 3", VNDetectFaceRectanglesRequestRevision3)
    ]
    
    var body: some View {
        VisionDemoView(
            title: "人脸检测",
            defaultImageName: "image_face",
            configView: {
                VStack(alignment: .leading, spacing: 10) {
                    Text("配置参数")
                        .font(.headline)
                    
                    Picker("Revision", selection: $revision) {
                        ForEach(revisions, id: \.1) { name, val in
                            Text(name).tag(val)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text("Revision 3 支持更复杂的场景和偏航/俯仰角度检测。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            },
            performRequest: { image in
                let req = FaceRectRequest()
                req.config.revision = revision
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
