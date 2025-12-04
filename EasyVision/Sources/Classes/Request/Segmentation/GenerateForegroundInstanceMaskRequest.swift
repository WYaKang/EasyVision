import UIKit
import Vision

public struct ForegroundInstanceMaskResult {
    public let pixelBuffer: CVPixelBuffer
    // VNInstanceMaskObservation 没有公开的 InstanceMask 类型，allInstances 返回的是 IndexSet
    // 实际上我们通常需要的是实例的 mask 或者索引
    // 文档显示 allInstances 是 IndexSet，代表 mask 中的标签值
    public let allInstances: IndexSet
}

public class GenerateForegroundInstanceMaskRequest: ImageBasedRequest<ForegroundInstanceMaskResult> {
    public override func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[ForegroundInstanceMaskResult], Error>) -> Void) -> VNRequest {
        return create(
            VNGenerateForegroundInstanceMaskRequest.self,
            observationType: VNInstanceMaskObservation.self,
                        transform: { obs in
                // 该请求返回单个 Observation，包含全图 mask 和实例信息
                // mask 位于 instanceMask (CVPixelBuffer)
                return ForegroundInstanceMaskResult(
                    pixelBuffer: obs.instanceMask,
                    allInstances: obs.allInstances
                )
            },
            completion: completion
        )
    }
}
