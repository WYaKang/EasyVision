//
//  VisionTestViewModel.swift
//  EasyVision
//
//  Created by EasyVision on 2025/12/04.
//

import SwiftUI
import Vision
import UIKit

@MainActor
class VisionTestViewModel: ObservableObject {
    
    // MARK: - State
    
    @Published var image: UIImage?
    @Published var resultImage: UIImage?
    @Published var message: String = "Ready"
    @Published var isProcessing: Bool = false
    @Published var showPicker: Bool = false
    
    // MARK: - Actions
    
    func reset() {
        resultImage = nil
        message = "Image selected"
    }
    
    func runDetection() {
        guard let uiImage = image, let cgImage = uiImage.cgImage else {
            message = "No image selected"
            return
        }
        
        isProcessing = true
        message = "Processing..."
        
        Task {
            // 使用 Task.detached 避免阻塞主线程，模拟耗时操作
            // 虽然 Vision 请求本身会利用 GPU/Neural Engine，但在主线程发起可能会有微小卡顿
            // 这里演示 Raw API 调用，实际项目中建议使用 EasyVision 封装
            
            await performDetection(cgImage: cgImage, uiImage: uiImage)
        }
    }
    
    private func performDetection(cgImage: CGImage, uiImage: UIImage) async {
        let request = VNDetectFaceRectanglesRequest { [weak self] req, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.message = "Error: \(error.localizedDescription)"
                    self.isProcessing = false
                }
                return
            }
            
            guard let results = req.results as? [VNFaceObservation] else {
                DispatchQueue.main.async {
                    self.message = "No results"
                    self.isProcessing = false
                }
                return
            }
            
            let count = results.count
            let drawnImage = self.drawResults(results, on: uiImage)
            
            DispatchQueue.main.async {
                self.message = "Found \(count) faces"
                self.resultImage = drawnImage
                self.isProcessing = false
            }
        }
        
        #if targetEnvironment(simulator)
        print("[ViewModel] Configuring for Simulator: Forcing CPU usage.")
        request.usesCPUOnly = true
        #endif
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            DispatchQueue.main.async {
                self.message = "Handler error: \(error.localizedDescription)"
                self.isProcessing = false
            }
        }
    }
    
    private func drawResults(_ results: [VNFaceObservation], on image: UIImage) -> UIImage? {
        // 使用 EasyVision 提供的 Result 模型进行绘制，或者直接使用 CoreGraphics
        // 这里为了演示 Raw API，我们手动转换并绘制，或者临时包装成 FaceRectResult
        // 为了方便，我们手动绘制一下，复用 EasyVision 的思路但更宽的线
        
        let imageSize = image.size
        UIGraphicsBeginImageContextWithOptions(imageSize, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        image.draw(at: .zero)
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setStrokeColor(UIColor.green.cgColor)
        context.setLineWidth(5.0) // 增加宽度
        
        for observation in results {
            let boundingBox = observation.boundingBox
            let w = boundingBox.width * imageSize.width
            let h = boundingBox.height * imageSize.height
            let x = boundingBox.minX * imageSize.width
            let y = (1 - boundingBox.minY - boundingBox.height) * imageSize.height
            let rect = CGRect(x: x, y: y, width: w, height: h)
            
            context.addRect(rect)
        }
        context.strokePath()
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
