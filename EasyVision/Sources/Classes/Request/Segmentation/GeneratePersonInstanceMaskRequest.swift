import UIKit
import Vision

public struct PersonInstanceMaskResult {
    public let pixelBuffer: CVPixelBuffer
    public let allInstances: IndexSet
}

public class GeneratePersonInstanceMaskRequest: ImageBasedRequest<PersonInstanceMaskResult> {
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[PersonInstanceMaskResult], Error>) -> Void) -> VNRequest {
        return create(
            VNGeneratePersonInstanceMaskRequest.self,
            observationType: VNInstanceMaskObservation.self,
            transform: { obs in
                return PersonInstanceMaskResult(
                    pixelBuffer: obs.instanceMask,
                    allInstances: obs.allInstances
                )
            },
            completion: completion
        )
    }
}
