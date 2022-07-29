//
//  File.swift
//  
//
//  Created by 오하온 on 29/07/22.
//

import Foundation

extension UInt16 {
    var toBytes: [UInt8] {
        var endian = CFByteOrderGetCurrent() == Int(CFByteOrderLittleEndian.rawValue) ? self.littleEndian : self.bigEndian
        let bytePtr = withUnsafePointer(to: &endian) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<UInt16>.size) {
                UnsafeBufferPointer(start: $0, count: MemoryLayout<UInt16>.size)
            }
        }
        return [UInt8](bytePtr)
    }
}
