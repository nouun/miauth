//
//  File.swift
//  
//
//  Created by 오하온 on 20/07/22.
//

import CoreBluetooth
import Foundation

protocol MiClientDelegate {
    func peripheral(_ peripheral: CBPeripheral, discoveredCharacteristic characteristic: CBCharacteristic)
    func peripheral(_ peripheral: CBPeripheral, characteristic: CBCharacteristic, recievedValue data: Data)
}
