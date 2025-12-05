//
//  VisionDemoViewModel.swift
//  EasyVision
//
//  Created by EasyVision on 2025/12/04.
//

import SwiftUI
import UIKit

@MainActor
class VisionDemoViewModel: ObservableObject {
    @Published var image: UIImage?
    @Published var resultImage: UIImage?
    @Published var isProcessing = false
    @Published var showingPicker = false
    @Published var errorMessage: String?
    
    init(defaultImageName: String? = nil) {
        if let name = defaultImageName, let img = UIImage(named: name) {
            self.image = img
        }
    }
    
    func processImage(action: @escaping (UIImage) async throws -> UIImage?) {
        guard let uiImage = image else { return }
        isProcessing = true
        errorMessage = nil
        resultImage = nil
        
        Task {
            do {
                let result = try await action(uiImage)
                self.resultImage = result
                self.isProcessing = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isProcessing = false
            }
        }
    }
    
    func reset() {
        resultImage = nil
        errorMessage = nil
    }
}
