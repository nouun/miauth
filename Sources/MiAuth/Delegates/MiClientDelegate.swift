//
//  File.swift
//  
//
//  Created by 오하온 on 20/07/22.
//

import CoreBluetooth
import Foundation

internal protocol MiClientDelegate {
    func connectedTo(peripheral: CBPeripheral) -> Bool
    func disconnectedFrom(peripheral: CBPeripheral) -> Bool
    
    func peripheral(_ peripheral: CBPeripheral, discoveredCharacteristic characteristic: CBCharacteristic)
    func peripheral(_ peripheral: CBPeripheral, characteristic: CBCharacteristic, recievedValue data: Data)
}

extension MiClientDelegate {
    func connectedTo(peripheral: CBPeripheral) -> Bool {
        return true
    }
    
    func disconnectedFrom(peripheral: CBPeripheral) -> Bool {
        return true
    }
}
