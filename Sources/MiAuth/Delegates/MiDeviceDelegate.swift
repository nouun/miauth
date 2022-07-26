//
//  File.swift
//  
//
//  Created by 오하온 on 20/07/22.
//

import CoreBluetooth
import Foundation

public enum MiState {
    case failedToConnect(device: CBPeripheral, error: Error?)
    case connected(device: CBPeripheral)
    case disconnected(device: CBPeripheral)
    
    case fetchingServices
    case fetchingCharacteristics
    
    case fetchingKey
    case authenticating
    case authenticated
}

public enum MiValue {
    case serial(number: String)
    case firmware(version: String)
}

public protocol MiDeviceDelegate {
    func didDiscover(device: CBPeripheral)
    func didRecieve(value: MiValue)
    func didUpdate(miState: MiState)
    
    func didUpdate(bleState: CBManagerState)
}

extension MiDeviceDelegate {
    func didUpdate(bleState: CBManagerState) {}
}
