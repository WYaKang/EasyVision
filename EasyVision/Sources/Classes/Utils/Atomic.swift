//
//  Atomic.swift
//  EasyVision
//
//  Created by EasyVision on 2025/12/04.
//

import Foundation
import os

/// 高性能原子操作包装器
/// 使用 os_unfair_lock 替代 NSLock 以获得更低的开销
/// 注意：os_unfair_lock 是互斥锁，不可重入
public final class Atomic<T> {
    private var _lock = os_unfair_lock()
    private var _value: T
    
    public init(_ value: T) {
        self._value = value
    }
    
    /// 获取当前值
    public var value: T {
        get {
            os_unfair_lock_lock(&_lock)
            defer { os_unfair_lock_unlock(&_lock) }
            return _value
        }
        set {
            os_unfair_lock_lock(&_lock)
            defer { os_unfair_lock_unlock(&_lock) }
            _value = newValue
        }
    }
    
    /// 比较并交换 (CAS)
    /// - Parameters:
    ///   - expected: 期望的当前值
    ///   - new: 如果当前值等于期望值，则写入的新值
    /// - Returns: 是否交换成功
    public func compareAndSwap(expected: T, new: T) -> Bool where T: Equatable {
        os_unfair_lock_lock(&_lock)
        defer { os_unfair_lock_unlock(&_lock) }
        if _value == expected {
            _value = new
            return true
        }
        return false
    }
    
    /// 安全地修改值并返回旧值
    public func modify(_ block: (inout T) -> Void) -> T {
        os_unfair_lock_lock(&_lock)
        defer { os_unfair_lock_unlock(&_lock) }
        let oldValue = _value
        block(&_value)
        return oldValue
    }
}
