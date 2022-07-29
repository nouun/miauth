//
//  File.swift
//  
//
//  Created by 오하온 on 20/07/22.
//

import Foundation

public protocol Payload {
    var payload: Data { get }
}


// MARK: - Xiaomi payloads

public enum MiAddress: UInt8 {
    /*
     Addresses from https://github.com/etransport/ninebot-docs/wiki/protocol
     
     0x20 - request to ESC
     0x21 - request to BLE
     0x22 - request to BMS
     0x23 - reply from ESC
     0x24 - reply from BLE
     0x25 - reply from BMS
     0x01 - ?
     0xFF - ?
     */
    case esc = 0x20
    case ble = 0x21
    case bms = 0x22
}

public struct MiPayload: Payload {
    // MARK: - Predefined payloads
    public static let keyResponse      = Self(name: "keyResponse", addr: .bms, cmd: 0x01, arg: 0x50, data: Data([0x20]))
    
    
    // MARK: - Read payloads
    
    public static let escSerialNumber  = Self.createReadPayload(name: "escSerialNumber",  idx: 0x10, len: 0x0E)
    public static let escVersion       = Self.createReadPayload(name: "escVersion",       idx: 0x1A, len: 0x02)
    public static let bmsVersion       = Self.createReadPayload(name: "bmsVersion",       idx: 0x67, len: 0x02)
    public static let bleVersion       = Self.createReadPayload(name: "bleVersion",       idx: 0x68, len: 0x02)
    public static let batteryLevel     = Self.createReadPayload(name: "batteryLevel",     idx: 0x1A, len: 0x10)
    public static let remainingMileage = Self.createReadPayload(name: "remainingMileage", idx: 0x1A, len: 0x10)
    public static let speed            = Self.createReadPayload(name: "speed",            idx: 0x1A, len: 0x10)
    public static let totalMileage     = Self.createReadPayload(name: "totalMileage",     idx: 0x1A, len: 0x10)
    public static let currentMileage   = Self.createReadPayload(name: "currentMileage",   idx: 0x1A, len: 0x10)
    public static let totalRunTime     = Self.createReadPayload(name: "totalRunTime",     idx: 0x1A, len: 0x10)
    public static let frameTemperature = Self.createReadPayload(name: "frameTemperature", idx: 0x1A, len: 0x10)
    public static let escVoltage       = Self.createReadPayload(name: "escVoltage",       idx: 0x1A, len: 0x10)
    public static let batteryVoltage   = Self.createReadPayload(name: "batteryVoltage",   idx: 0x1A, len: 0x10)
    public static let batteryCurrent   = Self.createReadPayload(name: "batteryCurrent",   idx: 0x1A, len: 0x10)
    public static let averageSpeed     = Self.createReadPayload(name: "averageSpeed",     idx: 0x1A, len: 0x10)
    public static let lock             = Self.createReadPayload(name: "lock",             idx: 0x1A, len: 0x10)
    public static let unlock           = Self.createReadPayload(name: "unlock",           idx: 0x1A, len: 0x10)
    public static let ecoMode          = Self.createReadPayload(name: "ecoMode",          idx: 0x1A, len: 0x10)
    public static let reboot           = Self.createReadPayload(name: "reboot",           idx: 0x1A, len: 0x10)
    
    
    // MARK: - Write payloads
    
    public static let shutDown         = Self.createWritePayload(name: "shutDown",        idx: 0x79, val: 0x0001)
    
    public static let modeNormal       = Self.createWritePayload(name: "modeNormal",      idx: 0x1F, val: 0x0000)
    public static let modeEco          = Self.createWritePayload(name: "modeEco",         idx: 0x1F, val: 0x0001)
    public static let modeSport        = Self.createWritePayload(name: "modeSport",       idx: 0x1F, val: 0x0002)
    
    
    // MARK: - Payload groups
    
    public static let payloads: [MiPayload] = [
        escSerialNumber,
        escVersion, bmsVersion, bleVersion,
        remainingMileage, totalMileage, currentMileage,
        speed, averageSpeed,
        totalRunTime,
        frameTemperature,
        batteryLevel, escVoltage, batteryVoltage, batteryCurrent,
        lock, unlock,
        ecoMode, reboot, shutDown
    ]
    
    
    // MARK: - Helpers
    
    static func createWritePayload(name: String, idx: UInt8, val: UInt16) -> Self {
        Self(name: name, addr: .esc, cmd: 0x03, arg: idx, data: Data(val.toBytes))
    }
    
    static func createReadPayload(name: String, idx: UInt8, len: UInt8) -> Self {
        Self(name: name, addr: .esc, cmd: 0x01, arg: idx, data: Data([len]))
    }
    
    
    // MARK: - Payload data
    
    public let name: String
    private let address: MiAddress
    private let command: UInt8
    private let argument: UInt8
    private let data: Data
    
    init(name: String, addr: MiAddress, cmd: UInt8, arg: UInt8, data: Data) {
        self.name = name
        self.address = addr
        self.command = cmd
        self.argument = arg
        self.data = data
    }
    
    public var payload: Data {
        Data([
            UInt8(self.data.count + 2), // len
            self.address.rawValue,      // addr
            self.command,               // cmd
            self.argument               // arg
        ])
        .appending(self.data)           // payload
    }
}


// MARK: - Ninebot payloads

public enum NbAddress: UInt8 {
    /*
     Addresses from https://github.com/etransport/ninebot-docs/wiki/protocol
     
     0x20 - ESC
     0x21 - BLE
     0x22 - BMS
     0x23 - External BMS (ESC translates it to/from 0x22 but forwards to/from external port)
     0x00 - ? - ESC handles it as 0x20
     0x01 - ?
     0x3D, 0x3E, 0x3F - Application
     */
    case esc = 0x20
    case ble = 0x21
    case bms = 0x22
    case embs = 0x23
}

public struct NbPayload: Payload {
    // MARK: - Predefined payloads
//    public static let keyResponse = Self(address: .bms, command: 0x01, argument: 0x50, payload: Data([0x20]))
//
//    public static let serialNumber = Self(address: .esc, command: 0x01, argument: 0x10, payload: Data([0x0E]))
//    public static let firmwareVersion = Self(address: .esc, command: 0x01, argument: 0x1A, payload: Data([0x10]))
    
    
    // MARK: - Payload data
    
    private let sourceAddress: NbAddress
    private let destinationAddress: NbAddress
    private let command: UInt8
    private let argument: UInt8
    private let data: Data
    
    public init(srcAddr: NbAddress, destAddr: NbAddress, cmd: UInt8, arg: UInt8, data: Data) {
        self.sourceAddress = srcAddr
        self.destinationAddress = destAddr
        self.command = cmd
        self.argument = arg
        self.data = data
    }
    
    public var payload: Data {
        Data([
            UInt8(self.data.count + 2),       // len
            self.sourceAddress.rawValue,      // srcAddr
            self.destinationAddress.rawValue, // destAddr
            self.command,                     // cmd
            self.argument                     // arg
        ])
        .appending(self.data)                 // payload
    }
}
