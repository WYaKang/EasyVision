import SwiftUI
import UIKit
import EasyVision
import PhotosUI

// MARK: - Image Picker (PHPicker)

/// 基于 PHPickerViewController 的图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var mode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.mode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    if let uiImage = image as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.image = uiImage
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Subviews for VisionDemoView

// 1. 图片展示视图
struct VisionDemoImageView: View {
    @ObservedObject var viewModel: VisionDemoViewModel
    
    var body: some View {
        GeometryReader { geo in
            let availableHeight = geo.size.height
            let availableWidth = geo.size.width
            
            if let displayImage = viewModel.resultImage ?? viewModel.image {
                ZoomableImageView(image: displayImage)
                    .frame(width: availableWidth, height: availableHeight)
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
                    .frame(width: availableWidth, height: availableHeight)
                    .cornerRadius(10)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .padding(.bottom, 4)
                            Text("点击选择图片")
                        }
                        .foregroundColor(.gray)
                    )
                    .onTapGesture {
                        viewModel.showingPicker = true
                    }
                    .padding()
            }
        }
    }
}

// 2. 状态覆盖视图 (Loading / Error)
struct VisionDemoOverlayView: View {
    @ObservedObject var viewModel: VisionDemoViewModel
    
    var body: some View {
        Group {
            if viewModel.isProcessing {
                ZStack {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("处理中...")
                            .foregroundColor(.white)
                            .padding(.top, 8)
                    }
                    .padding()
                    .background(Material.regular)
                    .cornerRadius(12)
                }
            } else if let error = viewModel.errorMessage {
                VStack {
                    Spacer()
                    Text(error)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    // 3秒后自动隐藏错误
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if viewModel.errorMessage == error {
                            withAnimation {
                                viewModel.errorMessage = nil
                            }
                        }
                    }
                }
            }
        }
    }
}

// 3. 配置和控制视图
struct VisionDemoConfigView<Content: View>: View {
    @ObservedObject var viewModel: VisionDemoViewModel
    let configView: Content
    let performRequest: (UIImage) async throws -> UIImage?
    
    var body: some View {
        VStack(spacing: 12) {
            // 配置视图
            if !(configView is EmptyView) {
                ScrollView {
                    configView
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                .frame(maxHeight: 150)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
            }
            
            // 按钮
            HStack(spacing: 12) {
                if viewModel.image != nil {
                    Button(action: {
                        viewModel.processImage(action: performRequest)
                    }) {
                        Label("开始识别", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isProcessing ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(viewModel.isProcessing)
                }
                
                if viewModel.resultImage != nil {
                    Button(action: {
                        viewModel.saveResult()
                    }) {
                        Label("保存", systemImage: "square.and.arrow.down")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Main VisionDemoView

// 通用演示视图模板 (重构后)
struct VisionDemoView<Content: View>: View {
    let title: String
    @StateObject private var viewModel: VisionDemoViewModel
    let configView: Content
    let performRequest: (UIImage) async throws -> UIImage?
    
    init(title: String,
         defaultImageName: String? = nil,
         @ViewBuilder configView: () -> Content,
         performRequest: @escaping (UIImage) async throws -> UIImage?) {
        self.title = title
        self._viewModel = StateObject(wrappedValue: VisionDemoViewModel(defaultImageName: defaultImageName))
        self.configView = configView()
        self.performRequest = performRequest
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 图片区域
            VisionDemoImageView(viewModel: viewModel)
            
            // 2. 配置与控制区域
            VisionDemoConfigView(
                viewModel: viewModel,
                configView: configView,
                performRequest: performRequest
            )
        }
        .overlay(VisionDemoOverlayView(viewModel: viewModel))
        //.navigationTitle(title) // 导航标题通常由外部 NavigationView 控制
        .sheet(isPresented: $viewModel.showingPicker) {
            ImagePicker(image: $viewModel.image)
        }
        .alert(isPresented: $viewModel.showSaveAlert) {
            Alert(title: Text("提示"), message: Text(viewModel.saveAlertMessage), dismissButton: .default(Text("确定")))
        }
        .onChange(of: viewModel.image) { _ in
            viewModel.reset()
        }
    }
}

// 扩展以支持无配置视图的简便初始化
extension VisionDemoView where Content == EmptyView {
    init(title: String, defaultImageName: String? = nil, performRequest: @escaping (UIImage) async throws -> UIImage?) {
        self.init(title: title, defaultImageName: defaultImageName, configView: { EmptyView() }, performRequest: performRequest)
    }
}
