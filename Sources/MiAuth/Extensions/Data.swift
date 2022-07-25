//
//  Array.swift
//
//
//  Created by 오하온 on 19/07/22.
//

import Foundation

func +(left: Data, right: Data) -> Data {
    var out = Data(capacity: left.count + right.count)
    out.append(left)
    out.append(right)
    return out
}

func +=(left: inout Data, right: Data) {
    left = left + right
}

extension Data {
    func chunked(into size: Int) -> [Self] {
        return stride(from: 0, to: count, by: size).map {
            self.from($0, to: Swift.min($0 + size, count))
        }
    }
    
    func from(_ start: Int, to end: Int? = nil) -> Self {
        let start = start < 0 ? self.count + start : start
        
        guard var end = end else {
            return Self(self[start...])
        }
        
        end = end < 0 ? self.count + end : end
        return Self(self[start..<end])
    }
    
    func to(_ end: Int) -> Self {
        self.from(0, to: end)
    }
    
    func hex(withSeparator separator: String = " ") -> String {
        self.map { String(format: "%02hhX", $0) }
            .joined(separator: separator)
    }
    
    func pad(toLength length: Int, with value: Element) -> Self {
        Self(repeating: value, count: Swift.max(length - self.count, 0)) + self
    }
    
    static func from(int: Int32) -> Data {
        var int = int
        return Data(bytes: &int, count: MemoryLayout.size(ofValue: int))
    }
    
    static func random(_ byteLength: Int) -> Self {
        Self((0..<byteLength).map { _ in UInt8.random(in: UInt8.min ... UInt8.max) })
    }
}
