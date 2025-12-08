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
    var body: some View {
        VisionDemoView<Any>(title: "人脸检测", defaultImageName: "image_face") { image in
            let req = FaceRectRequest()
            req.config.revision = VNDetectFaceRectanglesRequestRevision3
            let res = try await EasyVision.shared.detect(req, in: image)
            var drawn = image
            for item in res {
                if let newImg = item.draw(on: drawn) { drawn = newImg }
            }
            return res.isEmpty ? nil : drawn
        }
    }
}
