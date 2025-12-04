import Foundation

/// EasyVision 统一错误定义
/// 提供详细的错误描述、失败原因及恢复建议
public enum EasyVisionError: Error, LocalizedError, CustomNSError {
    
    /// 图片数据无效或格式不支持
    case invalidImage
    
    /// SampleBuffer 无效
    case invalidSampleBuffer
    
    /// Vision 框架内部错误
    case visionError(Error)
    
    /// 未检测到任何结果
    case noResults
    
    /// 请求执行失败
    case requestFailed(Error)
    
    /// 配置错误
    case configurationError(String)
    
    /// 超时
    case timeout
    
    /// 未知错误
    case unknown
    
    // MARK: - LocalizedError
    
    public var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image data or format."
        case .invalidSampleBuffer:
            return "Invalid SampleBuffer."
        case .visionError(let error):
            return "Vision framework error: \(error.localizedDescription)"
        case .noResults:
            return "No results detected."
        case .requestFailed(let error):
            return "Request execution failed: \(error.localizedDescription)"
        case .configurationError(let msg):
            return "Configuration error: \(msg)"
        case .timeout:
            return "Operation timed out."
        case .unknown:
            return "Unknown error occurred."
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .invalidImage:
            return "The provided image or CGImage is nil or corrupted."
        case .invalidSampleBuffer:
            return "Unable to retrieve CVImageBuffer from CMSampleBuffer."
        case .visionError:
            return "The underlying Vision framework returned an error."
        case .noResults:
            return "The detection algorithm completed but found no targets."
        case .requestFailed:
            return "The request could not be completed."
        case .configurationError:
            return "Invalid parameter or setting."
        case .timeout:
            return "The operation took longer than expected."
        case .unknown:
            return nil
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidImage:
            return "Ensure the image is a valid UIImage, CGImage, or CIImage."
        case .invalidSampleBuffer:
            return "Check the camera output settings."
        case .visionError:
            return "Check device compatibility or request configuration."
        case .noResults:
            return "Try adjusting lighting, angle, or request parameters."
        case .requestFailed:
            return "Check the error details and retry."
        case .configurationError:
            return "Review the documentation for valid configuration values."
        case .timeout:
            return "Optimize the task or increase the timeout duration."
        case .unknown:
            return "Check logs for more details."
        }
    }
    
    // MARK: - CustomNSError
    
    public static var errorDomain: String {
        return "com.easyvision.error"
    }
    
    public var errorCode: Int {
        switch self {
        case .invalidImage: return 1001
        case .invalidSampleBuffer: return 1002
        case .visionError: return 1003
        case .noResults: return 1004
        case .requestFailed: return 1005
        case .configurationError: return 1006
        case .timeout: return 1007
        case .unknown: return 9999
        }
    }
    
    public var errorUserInfo: [String : Any] {
        var userInfo: [String: Any] = [:]
        userInfo[NSLocalizedDescriptionKey] = errorDescription
        userInfo[NSLocalizedFailureReasonErrorKey] = failureReason
        userInfo[NSLocalizedRecoverySuggestionErrorKey] = recoverySuggestion
        return userInfo
    }
}
