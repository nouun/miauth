//
//  File.swift
//  
//
//  Created by 오하온 on 25/07/22.
//

import Foundation

public func crc16(_ bytes: Data) -> Data {
    let val = ~bytes.map(Int.init).reduce(0, +)
    return Data([0, 1].map { UInt8((val >> ($0 * 8)) & 0xff) })
}
