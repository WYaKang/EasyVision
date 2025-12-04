import SwiftUI
import EasyVision

struct ExampleListView: View {
    var body: some View {
        NavigationView {
            List {
                Section("Debug") {
                    NavigationLink("Raw Vision Test") {
                        RawVisionTestView()
                    }
                }

                Section("1. 人脸分析") {
                    NavigationLink("人脸检测 (FaceRect)") {
                        FaceRectView()
                    }
                    NavigationLink("关键点检测 (Landmarks)") {
                        FaceLandmarksView()
                    }
                    NavigationLink("人脸质量 (Quality)") {
                        FaceQualityView()
                    }
                }
                
                Section("2. 文本识别") {
                    NavigationLink("文字识别 (OCR)") {
                        RecognizeTextView()
                    }
                }
                
                Section("3. 矩形与条码") {
                    NavigationLink("条码/二维码 (Barcodes)") {
                        DetectBarcodesView()
                    }
                    NavigationLink("矩形检测 (Rectangles)") {
                        DetectRectanglesView()
                    }
                }
                
                Section("4. 姿态分析") {
                    NavigationLink("人体姿态 (Body Pose)") {
                        HumanBodyPoseView()
                    }
                    NavigationLink("手部姿态 (Hand Pose)") {
                        HumanHandPoseView()
                    }
                }
                
                Section("5. 特征分析") {
                    NavigationLink("显著性检测 (Saliency)") {
                        SaliencyView()
                    }
                    NavigationLink("轮廓检测 (Contours)") {
                        ContoursView()
                    }
                }
                
                Section("6. 分割与掩码") {
                    NavigationLink("人体分割 (Person Segmentation)") {
                        PersonSegmentationView()
                    }
                }
                
                Section("7. 视频与跟踪") {
                    NavigationLink("轨迹检测 (Trajectories)") {
                        Text("视频流功能需在真机或模拟器视频源测试，暂提供静态图接口演示")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("EasyVision Examples")
        }
    }
}

struct ExampleListView_Previews: PreviewProvider {
    static var previews: some View {
        ExampleListView()
    }
}
