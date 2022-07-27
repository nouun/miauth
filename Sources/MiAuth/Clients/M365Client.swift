//
//  File.swift
//  
//
//  Created by 오하온 on 20/07/22.
//

import CoreBluetooth
import Foundation

public final class M365Client: BaseClient {
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
        guard characteristic.uuid == MiUUID.KEY.uuid else { return }
        
        self.keyChar = characteristic
        self.delegate?.didUpdate(miState: .fetchingKey)
        
        // Fetch key
        peripheral.readValue(for: characteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, characteristic: CBCharacteristic, recievedValue data: Data) {
        var value = data
        
        
        // Get M365 key
        
        if let keyChar = self.keyChar, keyChar.uuid == characteristic.uuid {
            self.key55ab = value
            self.delegate?.didUpdate(miState: .authenticating)
            self.write(payload: .keyResponse)
            return
        }
        
        
        // Handle chunked data
        
        let chunkValue = self.chunkBuffer + value
        if crc16(chunkValue.from(2, to: -2)) != chunkValue.suffix(2) {
            self.chunkBuffer = chunkValue
            return
        }
        
        if !self.chunkBuffer.isEmpty {
            value = chunkValue
            self.chunkBuffer = Data()
        }
        
        
        // Decode response
        
        if let key = self.key55ab {
            value = self.crypt(value.from(3), withKey: key).to(-4)
        }
        
        
        // Parse response
        
        if value.count > 6 {
            guard let cmd = value.from(2, to: 3).map({ String(format: "%02hhX", $0) }).first else { return }
            let value = value.from(3, to: -2)
            
            switch cmd {
            case "50":
                self.key55ab?.append(contentsOf: value.from(9))
                self.delegate?.didUpdate(miState: .authenticated)
            case "10": self.delegate?.didRecieve(value: .serial(number: asciiSerializer(bytes: value)))
            case "1A": self.delegate?.didRecieve(value: .firmware(version: versionSerializer(bytes: value)))
            default: print("unrecognized value: cmd: '\(cmd)' val: '\(value.hex())'")
            }
        }
    }
    
    func versionSerializer(bytes: Data) -> String {
        return bytes
            .map { String(format: "%02hhX", $0) }
            .to(2)
            .joined(separator: ".")
    }
    
    func asciiSerializer(bytes: Data) -> String {
        return String(data: bytes, encoding: String.Encoding.ascii)!
    }
}
