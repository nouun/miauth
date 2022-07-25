//
//  File.swift
//  
//
//  Created by 오하온 on 20/07/22.
//

import CoreBluetooth
import Foundation

public class M365Client: BaseClient {
    private var key55ab: Data?
    private var keyChar: CBCharacteristic?
    
    private var chunkBuffer = Data()
    
    public required init() {
        super.init()
        
        self.frameHeader = [ 0x55, 0xAB ]
        self.services   += [ MiUUID.KEY ]
        self.clientDelegate = self
    }
    
    public override func write(value: Data) {
        guard let key = self.key55ab else { return }
        
        let len = Data(value[0..<1])
        var cmd = len + self.crypt(value.from(1) + Data([ 0x00, 0x00, 0x00, 0x00 ]), withKey: key)
        cmd.append(crc16(cmd))
        super.write(value: cmd)
    }
    
    func crypt(_ bytes: Data, withKey key: Data) -> Data {
        return Data(bytes.enumerated().map { $0.element ^ ($0.offset < key.count ? key[$0.offset] : 0) })
    }
}

extension M365Client: MiClientDelegate {
    func peripheral(_ peripheral: CBPeripheral, discoveredCharacteristic characteristic: CBCharacteristic) {
        self.keyChar = characteristic
        self.deviceDelegate?.didDeviceUpdate(state: .fetchingKey)
        
        // Fetch key
        peripheral.readValue(for: characteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, characteristic: CBCharacteristic, recievedValue data: Data) {
        var value = data
        
        self.logDelegate?.log("Recieved \(value.hex())")
        
        
        // Get M365 key
        
        if let keyChar = self.keyChar, keyChar.uuid == characteristic.uuid {
            self.key55ab = value
            self.logDelegate?.log("Got initial M365 key \(value.hex())")
            self.deviceDelegate?.didDeviceUpdate(state: .authenticating)
            self.write(payload: .keyResponse)
            return
        }
        
        
        // Handle chunked data
        
        let chunkValue = self.chunkBuffer + value
        if crc16(chunkValue.from(2, to: -2)) != chunkValue.suffix(2) {
            self.logDelegate?.log("CRC didn't match, appending data to chunk buffer")
            self.chunkBuffer = chunkValue
            return
        }
        
        if !self.chunkBuffer.isEmpty {
            value = chunkValue
            self.logDelegate?.log("CRC matches, recieved value \(value.hex())")
            self.chunkBuffer = Data()
        }
        
        self.logDelegate?.log("Encoded recieved \(value.hex())")
        
        
        // Decode response
        
        if let key = self.key55ab {
            let decrypted = self.crypt(value.from(3), withKey: key)
            value = decrypted.to(-4)
        }
        
        self.logDelegate?.log("Decoded recieved \(value.hex())")
        
        
        // Parse response
        
        if value.count > 6 {
            guard let cmd = value.from(2, to: 3).map({ String(format: "%02hhX", $0) }).first else { return }
            let value = value.from(3, to: -2)
            
            switch cmd {
            case "50":
                self.key55ab?.append(contentsOf: value.from(9))
                self.deviceDelegate?.didDeviceUpdate(state: .authenticated)
                self.logDelegate?.log("Got final M365 key \(self.key55ab?.hex() ?? "Error")")
            case "10": self.deviceDelegate?.didRecieve(value: .serial(number: asciiSerializer(bytes: value)))
            case "1A": self.deviceDelegate?.didRecieve(value: .firmware(version: versionSerializer(bytes: value)))
            // case "22": self.data.batteryLevel       = numberSerializer(bytes: value) + "%"
            // case "3E": self.data.bodyTemperature    = numberSerializer(bytes: value, factor: 10) + "°C"
            // case "29": self.data.totalMileage       = distanceSerializer(bytes: value) + "km"
            // case "47": self.data.voltage            = numberSerializer(bytes: value, format: "%.2f", factor: 100) + "V"
            // case "B5": self.data.currentSpeed       = numberSerializer(bytes: value, format: "%.2f", factor: 1000) + "km/h"
            // case "74": self.data.speedLimit         = numberSerializer(bytes: value, format: "%.2f", factor: 1000) + "km/h"
            // case "72": self.data.limitEnabled       = numberSerializer(bytes: value)
            default: self.logDelegate?.log("unrecognized value: cmd '\(cmd)' val: \(value.hex())")
            }
        }
    }
    
    func versionSerializer(bytes: Data) -> String {
        let bytesArray = bytes.map { String(format: "%02hhX", $0) }
        let majorVersion = Int(bytesArray[0])!
        let minorVersion = Int(bytesArray[1])!
        return String(majorVersion) + "." + String(minorVersion)
    }
    
    func asciiSerializer(bytes: Data) -> String {
        return String(data: bytes, encoding: String.Encoding.ascii)!
    }
    
    
    // // Maybe unneeded
    //
    // func swapBytes(data: Data) -> Data {
    //     var mdata = data
    //     let count = data.count / MemoryLayout<UInt16>.size
    //     mdata.withUnsafeMutableBytes { (i16ptr: UnsafeMutablePointer<UInt16>) in
    //         for i in 0..<count {
    //             i16ptr[i] = i16ptr[i].byteSwapped
    //         }
    //     }
    //     return mdata
    // }
    //
    // func distanceSerializer(bytes: Data) -> String {
    //     let bytesArray = swapBytes(data: bytes).map { String(format: "%02hhX", $0) }
    //     let major = Int(bytesArray[0] + bytesArray[1], radix: 16)!
    //     let minor = Int(bytesArray[2] + bytesArray[3], radix: 16)!
    //     return String(format: "%.2f", Double(major + minor * 65536)/1000)
    // }
    //
    // func numberSerializer(bytes: Data, format: String = "%.0f", factor: Int = 1) -> String {
    //     let hexString = swapBytes(data: bytes).map { String(format: "%02hhX", $0) }.joined()
    //     return String(format: format, Double(Int(hexString, radix: 16)!/factor))
    // }
}
