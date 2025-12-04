//
//  EasyVisionLogger.swift
//  EasyVision
//
//  Created by EasyVision on 2025/12/04.
//

import Foundation
import OSLog

/// 日志级别
public enum EasyVisionLogLevel: String, Comparable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"
    
    var icon: String {
        switch self {
        case .debug: return "🛠"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
    
    private var weight: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        }
    }
    
    public static func < (lhs: EasyVisionLogLevel, rhs: EasyVisionLogLevel) -> Bool {
        return lhs.weight < rhs.weight
    }
}

/// EasyVision 日志管理器
/// 提供高性能、线程安全的日志记录，支持系统控制台 (OSLog) 和沙盒文件存储
public final class EasyVisionLogger {
    
    public static let shared = EasyVisionLogger()
    
    // MARK: - Configuration
    
    /// 是否输出到系统控制台 (OSLog)
    public var enableConsoleLog: Bool = true
    
    /// 是否保存到文件
    public var enableFileLog: Bool = true
    
    /// 最低日志级别（低于此级别的日志将被忽略）
    public var minLogLevel: EasyVisionLogLevel = .debug
    
    /// 日志子系统标识
    public let subsystem = Bundle.main.bundleIdentifier ?? "com.easyvision"
    
    /// 日志类别
    public let category = "EasyVision"
    
    // MARK: - Private Properties
    
    private let logger: Logger
    private let fileQueue = DispatchQueue(label: "com.easyvision.logger.file", qos: .utility)
    private let fileManager = FileManager.default
    private var logFileURL: URL?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    private init() {
        self.logger = Logger(subsystem: subsystem, category: category)
        setupLogFile()
    }
    
    // MARK: - Public Methods
    
    public func debug(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .debug, message: message, file: file, line: line)
    }
    
    public func info(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .info, message: message, file: file, line: line)
    }
    
    public func warning(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .warning, message: message, file: file, line: line)
    }
    
    public func error(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .error, message: message, file: file, line: line)
    }
    
    /// 统一日志入口
    private func log(level: EasyVisionLogLevel, message: String, file: String, line: Int) {
        guard level >= minLogLevel else { return }
        
        let fileName = (file as NSString).lastPathComponent
        // 格式：[Level] FileName:Line - Message
        let logMessage = "[\(level.rawValue)] \(fileName):\(line) - \(message)"
        
        // 1. 系统控制台输出 (OSLog)
        if enableConsoleLog {
            switch level {
            case .debug:
                logger.debug("\(logMessage, privacy: .public)")
            case .info:
                logger.info("\(logMessage, privacy: .public)")
            case .warning:
                logger.warning("\(logMessage, privacy: .public)")
            case .error:
                logger.error("\(logMessage, privacy: .public)")
            }
        }
        
        // 2. 文件写入 (异步串行队列)
        if enableFileLog {
            let timestamp = dateFormatter.string(from: Date())
            let fileLogString = "\(timestamp) \(logMessage)"
            
            fileQueue.async { [weak self] in
                self?.writeToFile(fileLogString)
            }
        }
    }
    
    // MARK: - File Handling
    
    private func setupLogFile() {
        // 获取 Documents/EasyVisionLogs 目录
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let logsDirectoryURL = documentsURL.appendingPathComponent("EasyVisionLogs")
        
        // 创建目录
        if !fileManager.fileExists(atPath: logsDirectoryURL.path) {
            do {
                try fileManager.createDirectory(at: logsDirectoryURL, withIntermediateDirectories: true)
            } catch {
                print("❌ [EasyVisionLogger] Failed to create logs directory: \(error)")
                return
            }
        }
        
        // 按日期生成文件名: easyvision_yyyy-MM-dd.log
        let dateString = dateFormatter.string(from: Date()).components(separatedBy: " ").first ?? "unknown"
        let fileName = "easyvision_\(dateString).log"
        logFileURL = logsDirectoryURL.appendingPathComponent(fileName)
        
        // 清理旧日志 (保留最近 7 天)
        cleanOldLogs(in: logsDirectoryURL)
    }
    
    private func writeToFile(_ string: String) {
        guard let fileURL = logFileURL else { return }
        
        let line = string + "\n"
        guard let data = line.data(using: .utf8) else { return }
        
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            } catch {
                print("❌ [EasyVisionLogger] Failed to write to log file: \(error)")
            }
        } else {
            do {
                try data.write(to: fileURL)
            } catch {
                print("❌ [EasyVisionLogger] Failed to create log file: \(error)")
            }
        }
    }
    
    private func cleanOldLogs(in directory: URL) {
        fileQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                let fileURLs = try self.fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)
                
                // 简单的清理策略：如果超过 7 个文件，删除最旧的
                if fileURLs.count > 7 {
                    let sortedFiles = fileURLs.sorted { url1, url2 in
                        let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                        let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                        return date1 < date2
                    }
                    
                    // 删除多余的文件
                    for i in 0..<(sortedFiles.count - 7) {
                        try? self.fileManager.removeItem(at: sortedFiles[i])
                    }
                }
            } catch {
                print("❌ [EasyVisionLogger] Failed to clean old logs: \(error)")
            }
        }
    }
    
    /// 获取当前日志文件路径（用于调试或分享）
    public func getCurrentLogPath() -> String? {
        return logFileURL?.path
    }
}
