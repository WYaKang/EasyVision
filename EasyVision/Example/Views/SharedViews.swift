import SwiftUI
import UIKit
import EasyVision

// 通用图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var mode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.mode.wrappedValue.dismiss()
        }
    }
}

// 通用演示视图模板
struct VisionDemoView<Result>: View {
    let title: String
    @StateObject private var viewModel = VisionDemoViewModel()
    let performRequest: (UIImage) async throws -> UIImage?
    
    var body: some View {
        VStack(spacing: 20) {
            // 图片区域
            if let displayImage = viewModel.resultImage ?? viewModel.image {
                ZoomableImageView(image: displayImage)
                    .frame(height: 400)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .overlay(
                        Button(action: { viewModel.showingPicker = true }) {
                            Image(systemName: "photo.on.rectangle")
                                .padding(8)
                                .background(Material.thinMaterial)
                                .clipShape(Circle())
                        }
                        .padding(8),
                        alignment: .topTrailing
                    )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
                    .cornerRadius(10)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                            Text("点击选择图片")
                        }
                        .foregroundColor(.gray)
                    )
                    .onTapGesture {
                        viewModel.showingPicker = true
                    }
                    .padding()
            }
            
            // 控制区域
            VStack {
                if viewModel.isProcessing {
                    ProgressView("处理中...")
                        .padding()
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                Spacer()
                
                if viewModel.image != nil {
                    Button(action: {
                        viewModel.processImage(action: performRequest)
                    }) {
                        Label("开始识别", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isProcessing ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(viewModel.isProcessing)
                    .padding()
                }
            }
        }
        .navigationTitle(title)
        .sheet(isPresented: $viewModel.showingPicker) {
            ImagePicker(image: $viewModel.image)
        }
        .onChange(of: viewModel.image) { _ in
            viewModel.reset()
        }
    }
}
