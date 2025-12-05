//
//  EasyVision.swift
//  EasyVision
//
//  Created by yakang wang on 2025/12/3.
//

import Foundation
import Vision
import UIKit
import CoreImage
import CoreVideo
import AVFoundation
import ImageIO

// MARK: - Vision Input

/// 统一的 Vision 输入源
public enum VisionInput {
    case image(UIImage)
    case ciImage(CIImage)
    case pixelBuffer(CVPixelBuffer)
    case sampleBuffer(CMSampleBuffer)
    case cgImage(CGImage)
    
    /// 获取图像尺寸
    public var size: CGSize {
        switch self {
        case .image(let img):
            return img.size
        case .ciImage(let img):
            return img.extent.size
        case .pixelBuffer(let pb):
            return CGSize(width: CVPixelBufferGetWidth(pb), height: CVPixelBufferGetHeight(pb))
        case .sampleBuffer(let sb):
            if let pb = CMSampleBufferGetImageBuffer(sb) {
                return CGSize(width: CVPixelBufferGetWidth(pb), height: CVPixelBufferGetHeight(pb))
            }
            return .zero
        case .cgImage(let img):
            return CGSize(width: img.width, height: img.height)
        }
    }
    
    /// 创建 RequestHandler
    func createHandler(options: [VNImageOption: Any]) throws -> VNImageRequestHandler {
        switch self {
        case .image(let img):
            guard let cgImage = img.cgImage else { throw EasyVisionError.invalidImage }
            return VNImageRequestHandler(cgImage: cgImage, orientation: img.cgImageOrientation, options: options)
        case .ciImage(let img):
            return VNImageRequestHandler(ciImage: img, options: options)
        case .pixelBuffer(let pb):
            return VNImageRequestHandler(cvPixelBuffer: pb, options: options)
        case .sampleBuffer(let sb):
            guard let pb = CMSampleBufferGetImageBuffer(sb) else { throw EasyVisionError.invalidSampleBuffer }
            return VNImageRequestHandler(cvPixelBuffer: pb, options: options)
        case .cgImage(let img):
            return VNImageRequestHandler(cgImage: img, options: options)
        }
    }
}

// MARK: - Internal Extensions

extension UIImage {
    var cgImageOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}



// MARK: - EasyVision Core

/// EasyVision 核心类
/// 提供 Vision 请求的执行入口，支持多种图像源
public class EasyVision {
    
    public static let shared = EasyVision()
    private init() {}
    
    // MARK: - Single Detection (Unified)
    
    /// 统一检测入口
    /// - Parameters:
    ///   - request: EasyVision 请求
    ///   - input: 输入源 (UIImage, CIImage, etc.)
    ///   - options: Vision 选项
    public func detect<R: EasyVisionRequest>(
        _ request: R,
        in input: VisionInput,
        options: [VNImageOption: Any] = [:]
    ) async throws -> [R.ResultType] {
        let size = input.size
        guard size != .zero else { throw EasyVisionError.invalidImage }
        
        return try await execute(request, size: size) {
            try input.createHandler(options: options)
        }
    }
    
    // MARK: - Convenience Overloads
    
    public func detect<R: EasyVisionRequest>(_ request: R, in image: UIImage, options: [VNImageOption: Any] = [:]) async throws -> [R.ResultType] {
        return try await detect(request, in: .image(image), options: options)
    }

    public func detect<R: EasyVisionRequest>(_ request: R, in ciImage: CIImage, options: [VNImageOption: Any] = [:]) async throws -> [R.ResultType] {
        return try await detect(request, in: .ciImage(ciImage), options: options)
    }

    public func detect<R: EasyVisionRequest>(_ request: R, in pixelBuffer: CVPixelBuffer, options: [VNImageOption: Any] = [:]) async throws -> [R.ResultType] {
        return try await detect(request, in: .pixelBuffer(pixelBuffer), options: options)
    }

    public func detect<R: EasyVisionRequest>(_ request: R, in sampleBuffer: CMSampleBuffer, options: [VNImageOption: Any] = [:]) async throws -> [R.ResultType] {
        return try await detect(request, in: .sampleBuffer(sampleBuffer), options: options)
    }
    
    public func detect<R: EasyVisionRequest>(_ request: R, in cgImage: CGImage, options: [VNImageOption: Any] = [:]) async throws -> [R.ResultType] {
        return try await detect(request, in: .cgImage(cgImage), options: options)
    }
    
    // MARK: - Batch Detection (detectAll)

    public func detectAll(
        _ requests: [AnyRequestBox],
        in input: VisionInput,
        options: [VNImageOption: Any] = [:]
    ) async throws -> [String: [Any]] {
        let size = input.size
        guard size != .zero else { throw EasyVisionError.invalidImage }
        
        return try await executeBatch(requests, size: size) {
            try input.createHandler(options: options)
        }
    }
    
    // Convenience Batch Overloads...
    public func detectAll(_ requests: [AnyRequestBox], in image: UIImage, options: [VNImageOption: Any] = [:]) async throws -> [String: [Any]] {
        return try await detectAll(requests, in: .image(image), options: options)
    }
    // ... (Other overloads can be added similarly if needed, keeping it minimal for now as per user request for elegance)

    // MARK: - Trajectory Detection (Sequence)

    public func detectTrajectoriesSequence(_ request: DetectTrajectoriesRequest, in frames: [CVPixelBuffer]) async throws -> [[TrajectoryResult]] {
        EasyVisionLogger.shared.debug("Starting trajectory sequence detection, frames: \(frames.count)")
        
        return try await withCheckedThrowingContinuation { continuation in
            let seq = VNSequenceRequestHandler()
            var allResults: [[TrajectoryResult]] = Array(repeating: [], count: frames.count)
            
            // 使用 Task 避免阻塞
            Task {
                do {
                    for (idx, pb) in frames.enumerated() {
                        let size = CGSize(width: CVPixelBufferGetWidth(pb), height: CVPixelBufferGetHeight(pb))
                        let context = VisionRequestContext(imageSize: size)
                        
                        let vnRequest = request.makeVNRequest(context: context) { _ in }
                        
                        #if targetEnvironment(simulator)
                        vnRequest.usesCPUOnly = true
                        #endif
                        
                        try seq.perform([vnRequest], on: pb)
                        
                        if let observations = vnRequest.results as? [VNTrajectoryObservation] {
                            let mapped = observations.map { obs -> TrajectoryResult in
                                let pts = obs.detectedPoints.map { p in
                                    CGPoint(x: CGFloat(p.x) * size.width,
                                            y: (1 - CGFloat(p.y)) * size.height)
                                }
                                return TrajectoryResult(timeRange: obs.timeRange, normalizedPoints: pts)
                            }
                            allResults[idx] = mapped
                        } else {
                            allResults[idx] = []
                        }
                    }
                    EasyVisionLogger.shared.info("Trajectory sequence detection complete")
                    continuation.resume(returning: allResults)
                } catch {
                    EasyVisionLogger.shared.error("Trajectory sequence detection failed: \(error)")
                    continuation.resume(throwing: EasyVisionError.visionError(error))
                }
            }
        }
    }

    public func detectTrajectoriesSequence(_ request: DetectTrajectoriesRequest, in sampleFrames: [CMSampleBuffer]) async throws -> [[TrajectoryResult]] {
        let frames: [CVPixelBuffer] = sampleFrames.compactMap { CMSampleBufferGetImageBuffer($0) }
        return try await detectTrajectoriesSequence(request, in: frames)
    }

    // MARK: - Streaming (AsyncThrowingStream)

    public func trajectoriesStream<S: AsyncSequence>(_ request: DetectTrajectoriesRequest, frames: S) -> AsyncThrowingStream<[TrajectoryResult], Error> where S.Element == CVPixelBuffer {
        AsyncThrowingStream { continuation in
            let seq = VNSequenceRequestHandler()
            Task {
                do {
                    EasyVisionLogger.shared.debug("Starting trajectory stream")
                    for try await pb in frames {
                        let size = CGSize(width: CVPixelBufferGetWidth(pb), height: CVPixelBufferGetHeight(pb))
                        let context = VisionRequestContext(imageSize: size)
                        
                        var out: [TrajectoryResult] = []
                        let vnRequest = request.makeVNRequest(context: context) { result in
                            switch result {
                            case .success(let arr):
                                out = arr
                            case .failure(let err):
                                continuation.finish(throwing: err)
                            }
                        }
                        
                        #if targetEnvironment(simulator)
                        vnRequest.usesCPUOnly = true
                        #endif
                        
                        try seq.perform([vnRequest], on: pb)
                        continuation.yield(out)
                    }
                    EasyVisionLogger.shared.info("Trajectory stream finished")
                    continuation.finish()
                } catch {
                    EasyVisionLogger.shared.error("Trajectory stream failed: \(error)")
                    continuation.finish(throwing: EasyVisionError.visionError(error))
                }
            }
        }
    }
    
    // ... (Other stream methods can follow similar pattern or use VisionInput if applicable for Sequence)
    
    // MARK: - Private Helper Methods
    
    private func execute<R: EasyVisionRequest>(
        _ request: R,
        size: CGSize,
        handlerCreator: () throws -> VNImageRequestHandler
    ) async throws -> [R.ResultType] {
        EasyVisionLogger.shared.debug("Starting detection for \(R.self), Size: \(size)")
        
        return try await withCheckedThrowingContinuation { continuation in
            let atomic = Atomic(false)
            
            func resume(with result: Result<[R.ResultType], Error>) {
                if atomic.compareAndSwap(expected: false, new: true) {
                    continuation.resume(with: result)
                } else {
                    EasyVisionLogger.shared.warning("Attempted to resume continuation multiple times for \(R.self)")
                }
            }
            
            let context = VisionRequestContext(imageSize: size)
            let vnRequest = request.makeVNRequest(context: context) { result in
                switch result {
                case .success(let data):
                    EasyVisionLogger.shared.info("Detection success: \(data.count) items for \(R.self)")
                    resume(with: .success(data))
                case .failure(let error):
                    EasyVisionLogger.shared.error("Detection failed: \(error)")
                    resume(with: .failure(error))
                }
            }
            
            #if targetEnvironment(simulator)
            vnRequest.usesCPUOnly = true
            #endif
            
            do {
                let handler = try handlerCreator()
                try handler.perform([vnRequest])
            } catch {
                EasyVisionLogger.shared.error("Handler perform failed: \(error)")
                resume(with: .failure(EasyVisionError.visionError(error)))
            }
        }
    }
    
    private func executeBatch(
        _ requests: [AnyRequestBox],
        size: CGSize,
        handlerCreator: () throws -> VNImageRequestHandler
    ) async throws -> [String: [Any]] {
        EasyVisionLogger.shared.debug("Starting batch detection, count: \(requests.count)")
        
        return try await withCheckedThrowingContinuation { continuation in
            var storage: [String: [Any]] = [:]
            var firstError: Error?
            
            let context = VisionRequestContext(imageSize: size)
            let vnRequests: [VNRequest] = requests.map { box in
                box.make(context: context) { result in
                    switch result {
                    case .success(let arr):
                        storage[box.name] = arr
                    case .failure(let err):
                        if firstError == nil { firstError = err }
                    }
                }
            }
            
            #if targetEnvironment(simulator)
            vnRequests.forEach { $0.usesCPUOnly = true }
            #endif
            
            do {
                let handler = try handlerCreator()
                try handler.perform(vnRequests)
                
                if let err = firstError {
                    EasyVisionLogger.shared.error("Batch detection failed with first error: \(err)")
                    continuation.resume(throwing: err)
                } else {
                    EasyVisionLogger.shared.info("Batch detection success")
                    continuation.resume(returning: storage)
                }
            } catch {
                EasyVisionLogger.shared.error("Batch handler perform failed: \(error)")
                continuation.resume(throwing: EasyVisionError.visionError(error))
            }
        }
    }
}
