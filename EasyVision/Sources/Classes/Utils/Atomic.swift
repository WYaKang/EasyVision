//
//  Atomic.swift
//  EasyVision
//
//  Created by EasyVision on 2025/12/04.
//

import Foundation

/// 简单的原子操作包装器
/// 用于在并发环境下安全地读写值
public final class Atomic<T> {
    private let lock = NSLock()
    private var _value: T
    
    public init(_ value: T) {
        self._value = value
    }
    
    /// 获取当前值
    public var value: T {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _value = newValue
        }
    }
    
    /// 比较并交换 (CAS)
    /// - Parameters:
    ///   - expected: 期望的当前值
    ///   - new: 如果当前值等于期望值，则写入的新值
    /// - Returns: 是否交换成功
    public func compareAndSwap(expected: T, new: T) -> Bool where T: Equatable {
        lock.lock()
        defer { lock.unlock() }
        if _value == expected {
            _value = new
            return true
        }
        return false
    }
    
    /// 安全地修改值并返回旧值
    public func modify(_ block: (inout T) -> Void) -> T {
        lock.lock()
        defer { lock.unlock() }
        let oldValue = _value
        block(&_value)
        return oldValue
    }
}
