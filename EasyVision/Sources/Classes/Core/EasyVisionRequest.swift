//
//  EasyVisionRequest.swift
//  EasyVision
//
//  Created by yakang wang on 2025/12/3.
//

import Vision
import UIKit

// MARK: - Context

/// 请求上下文，包含构建请求所需的环境信息
public struct VisionRequestContext {
    /// 图像尺寸 (像素)
    public let imageSize: CGSize
    
    public init(imageSize: CGSize) {
        self.imageSize = imageSize
    }
}

// MARK: - Core Protocol

/// EasyVision 请求协议
/// 定义了如何创建 Vision 请求以及如何处理结果
public protocol EasyVisionRequest {
    /// 结果类型
    associatedtype ResultType
    
    /// 创建原生的 VNRequest
    /// - Parameters:
    ///   - context: 请求上下文（包含图片尺寸等）
    ///   - completion: 结果回调
    /// - Returns: 配置好的 VNRequest 实例
    func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[ResultType], Error>) -> Void) -> VNRequest
}

// MARK: - Base Implementation

/// 基础请求配置
public struct ImageRequestConfig {
    public var usesCPUOnly: Bool
    public var preferBackgroundProcessing: Bool
    public var revision: Int?
    public var regionOfInterest: CGRect?
    
    public init(
        usesCPUOnly: Bool = false,
        preferBackgroundProcessing: Bool = true,
        revision: Int? = nil,
        regionOfInterest: CGRect? = nil
    ) {
        self.usesCPUOnly = usesCPUOnly
        self.preferBackgroundProcessing = preferBackgroundProcessing
        self.revision = revision
        self.regionOfInterest = regionOfInterest
    }
}

/// 抽象基类：提供通用的配置管理和辅助方法
/// 推荐所有具体的 Vision 请求继承此类
open class ImageBasedRequest<R>: EasyVisionRequest {
    public typealias ResultType = R
    
    public var config: ImageRequestConfig
    
    public init(config: ImageRequestConfig = ImageRequestConfig()) {
        self.config = config
    }
    
    /// 子类必须实现此方法
    open func makeVNRequest(context: VisionRequestContext, completion: @escaping (Result<[R], Error>) -> Void) -> VNRequest {
        fatalError("Subclasses must implement makeVNRequest(context:completion:)")
    }
    
    // MARK: - Helper Methods for Subclasses
    
    /// 通用请求构建器 (Standard Builder)
    /// 适用于大多数标准的 Vision 请求：创建 -> 配置 -> 映射结果
    ///
    /// - Parameters:
    ///   - requestType: VNRequest 的类型
    ///   - observationType: 期望的 VNObservation 类型
    ///   - creation: (可选) 自定义创建逻辑，接受 completionHandler 作为参数
    ///   - configuration: (可选) 额外的配置逻辑
    ///   - transform: 结果映射逻辑
    ///   - completion: 外部传入的完成回调
    public func create<VNReq: VNRequest, Obs: VNObservation>(
        _ requestType: VNReq.Type,
        observationType: Obs.Type,
        creation: ((VNRequestCompletionHandler?) -> VNReq)? = nil,
        configuration: ((VNReq) -> Void)? = nil,
        transform: @escaping (Obs) -> R?,
        completion: @escaping (Result<[R], Error>) -> Void
    ) -> VNRequest {
        
        // 1. 定义 Completion Handler
        let handler: VNRequestCompletionHandler = { [weak self] req, error in
            self?.handleCompletion(request: req, error: error, transform: transform, completion: completion)
        }
        
        // 2. 创建 Request
        // 如果提供了 creation，则使用它创建 request，并传入 handler
        // 否则使用 VNReq 的默认初始化方法 (需支持 completionHandler 参数)
        let request = creation?(handler) ?? VNReq(completionHandler: handler)
        
        // 3. 应用通用配置
        applyCommonConfig(to: request)
        
        // 4. 应用自定义配置
        configuration?(request)
        
        return request
    }
    
    /// 处理请求完成的回调
    private func handleCompletion<Obs: VNObservation>(
        request: VNRequest,
        error: Error?,
        transform: @escaping (Obs) -> R?,
        completion: @escaping (Result<[R], Error>) -> Void
    ) {
        if let error = error {
            EasyVisionLogger.shared.error("\(type(of: request)) failed: \(error.localizedDescription)")
            completion(.failure(EasyVisionError.visionError(error)))
            return
        }
        
        guard let results = request.results as? [Obs] else {
            // 结果为空或类型不匹配
            if request.results == nil {
                EasyVisionLogger.shared.debug("\(type(of: request)) returned no results")
                completion(.success([]))
            } else {
                let gotType = type(of: request.results?.first)
                EasyVisionLogger.shared.warning("\(type(of: request)) type mismatch: expected \(Obs.self), got \(gotType)")
                completion(.success([]))
            }
            return
        }
        
        let mapped = results.compactMap(transform)
        completion(.success(mapped))
    }
    
    /// 应用通用配置 (CPU, Background, Revision, ROI)
    private func applyCommonConfig(to request: VNRequest) {
        if #available(iOS 17.0, *) {
            // usesCPUOnly handled by system
        } else {
            request.usesCPUOnly = config.usesCPUOnly
        }
        
        request.preferBackgroundProcessing = config.preferBackgroundProcessing
        
        if let revision = config.revision {
            request.revision = revision
        }
        
        if let roi = config.regionOfInterest, let imageReq = request as? VNImageBasedRequest {
            imageReq.regionOfInterest = roi
        }
    }
}

// MARK: - Compatibility & Utility Extensions

public extension EasyVisionRequest {
    // 保持旧接口的兼容性，将其转发到新接口
    func makeVNRequest(imageSize: CGSize, completion: @escaping (Result<[ResultType], Error>) -> Void) -> VNRequest {
        return makeVNRequest(context: VisionRequestContext(imageSize: imageSize), completion: completion)
    }
}

// MARK: - Coordinate Conversion Utilities

public extension ImageBasedRequest {
    
    /// 坐标转换：归一化 [0,1] -> 像素坐标 (UIKit Origin Top-Left)
    func convertRect(_ boundingBox: CGRect, imageSize: CGSize) -> CGRect {
        let w = boundingBox.width * imageSize.width
        let h = boundingBox.height * imageSize.height
        let x = boundingBox.minX * imageSize.width
        // Vision 原点在左下，UIKit 在左上
        let y = (1 - boundingBox.minY - boundingBox.height) * imageSize.height
        return CGRect(x: x, y: y, width: w, height: h)
    }
    
    /// 关键点转换
    func convertRegionPoints(_ region: VNFaceLandmarkRegion2D?, in boundingBox: CGRect, imageSize: CGSize) -> [CGPoint]? {
        guard let region = region else { return nil }
        let rect = convertRect(boundingBox, imageSize: imageSize)
        return region.normalizedPoints.map { p in
            CGPoint(x: rect.minX + p.x * rect.width,
                    y: rect.minY + (1 - p.y) * rect.height)
        }
    }
    
    /// 矩形观测值转换
    func convertRectangleObservation(_ rectObs: VNRectangleObservation, imageSize: CGSize) -> CGRect {
        let tl = CGPoint(x: rectObs.topLeft.x * imageSize.width, y: (1 - rectObs.topLeft.y) * imageSize.height)
        let tr = CGPoint(x: rectObs.topRight.x * imageSize.width, y: (1 - rectObs.topRight.y) * imageSize.height)
        let bl = CGPoint(x: rectObs.bottomLeft.x * imageSize.width, y: (1 - rectObs.bottomLeft.y) * imageSize.height)
        let br = CGPoint(x: rectObs.bottomRight.x * imageSize.width, y: (1 - rectObs.bottomRight.y) * imageSize.height)
        
        let minX = min(tl.x, tr.x, bl.x, br.x)
        let maxX = max(tl.x, tr.x, bl.x, br.x)
        let minY = min(tl.y, tr.y, bl.y, br.y)
        let maxY = max(tl.y, tr.y, bl.y, br.y)
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

// MARK: - Type Erasure

/// 类型擦除容器 (AnyRequest)
public struct AnyRequestBox {
    public let name: String
    private let _make: (VisionRequestContext, @escaping (Result<[Any], Error>) -> Void) -> VNRequest
    
    public init<R: EasyVisionRequest>(_ request: R, name: String? = nil) {
        self.name = name ?? String(describing: R.self)
        self._make = { context, completion in
            request.makeVNRequest(context: context) { result in
                switch result {
                case .success(let items):
                    completion(.success(items.map { $0 as Any }))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    public func make(context: VisionRequestContext, completion: @escaping (Result<[Any], Error>) -> Void) -> VNRequest {
        return _make(context, completion)
    }
    
    // 兼容旧接口
    public func make(_ imageSize: CGSize, completion: @escaping (Result<[Any], Error>) -> Void) -> VNRequest {
        return _make(VisionRequestContext(imageSize: imageSize), completion)
    }
}
