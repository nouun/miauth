//
//  File.swift
//  
//
//  Created by 오하온 on 20/07/22.
//

import Foundation

public enum MiPayload: CaseIterable {
    case keyResponse
    
    case serialNumber
    case firmwareVersion
    
    public var name: String {
        get {
            switch self {
            case .keyResponse:     return "Authentication Key"
            case .serialNumber:    return "Serial Number"
            case .firmwareVersion: return "Firmware Version"
            }
        }
    }
    
    var payload: Data {
        get {
            switch self {
            case .keyResponse:     return Data([ 0x03, 0x22, 0x01, 0x50, 0x20 ])
            case .serialNumber:    return Data([ 0x03, 0x20, 0x01, 0x10, 0x0E ])
            case .firmwareVersion: return Data([ 0x03, 0x20, 0x01, 0x1A, 0x10 ])
            }
        }
    }
}
