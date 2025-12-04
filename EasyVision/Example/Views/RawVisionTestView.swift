import SwiftUI
import Vision
import UIKit

struct RawVisionTestView: View {
    @StateObject private var viewModel = VisionTestViewModel()
    
    var body: some View {
        VStack {
            Text("Raw Vision API Test")
                .font(.headline)
            
            if let display = viewModel.resultImage ?? viewModel.image {
                ZoomableImageView(image: display)
                    .frame(height: 300)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            } else {
                Color.gray.opacity(0.2)
                    .frame(height: 300)
                    .cornerRadius(10)
                    .overlay(Text("No Image"))
            }
            
            Text(viewModel.message)
                .padding()
                .multilineTextAlignment(.center)
            
            if viewModel.isProcessing {
                ProgressView()
            }
            
            HStack {
                Button("Pick Image") {
                    viewModel.showPicker = true
                }
                .buttonStyle(.bordered)
                
                if viewModel.image != nil {
                    Button("Detect Face (Raw)") {
                        viewModel.runDetection()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isProcessing)
                }
            }
        }
        .padding()
        .sheet(isPresented: $viewModel.showPicker) {
            ImagePicker(image: $viewModel.image)
        }
        .onChange(of: viewModel.image) { _ in
            viewModel.reset()
        }
    }
}
