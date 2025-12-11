import SwiftUI
import EasyVision
import Vision

struct DetectBarcodesView: View {
    @State private var selectedSymbology: String = "All"
    @State private var revision: Int = VNDetectBarcodesRequest.defaultRevision
    
    private let symbologies: [(String, [VNBarcodeSymbology]?)] = [
        ("All", nil),
        ("QR Code", [.qr]),
        ("EAN 13", [.ean13]),
        ("EAN 8", [.ean8]),
        ("UPC E", [.upce]),
        ("PDF417", [.pdf417])
    ]
    
    var body: some View {
        VisionDemoView(
            title: "条码检测",
            configView: {
                VStack(alignment: .leading) {
                    Picker("条码类型", selection: $selectedSymbology) {
                        ForEach(symbologies, id: \.0) { name, _ in
                            Text(name).tag(name)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Picker("Revision", selection: $revision) {
                        ForEach(VNDetectBarcodesRequest.supportedRevisions.sorted(), id: \.self) { rev in
                            Text("Revision \(rev)").tag(rev)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 5)
            },
            performRequest: { image in
                let syms = symbologies.first(where: { $0.0 == selectedSymbology })?.1
                let req = DetectBarcodesRequest(
                    config: ImageRequestConfig(revision: revision),
                    symbologies: syms
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