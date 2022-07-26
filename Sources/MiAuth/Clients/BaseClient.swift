//
//  File.swift
//  
//
//  Created by 오하온 on 20/07/22.
//

import CoreBluetooth
import Foundation

public class BaseClient: NSObject {
    private var autoDiscover: Bool
    private var manager: CBCentralManager!
    private var peripherals: [CBPeripheral] = []
    internal var peripheral: CBPeripheral?
    
    internal var txChar: CBCharacteristic?
    
    public var delegate: MiDeviceDelegate?
    
    internal var discoveredCharacteristics: [CBCharacteristic] = []
    internal var discoveredServices: [CBService] = []
    
    internal var clientDelegate: MiClientDelegate?
    internal var services: [MiUUID] = [ MiUUID.RX, MiUUID.TX ]
    internal var frameHeader: [UInt8] = []
    
    public init(autoDiscover: Bool = true) {
        self.autoDiscover = autoDiscover
        
        super.init()
        
        self.manager = CBCentralManager(delegate: self, queue: nil)
    }
    
    public func discover() {
        self.manager.scanForPeripherals(withServices: nil)
    }
    
    public func stopDiscovery() {
        self.manager.stopScan()
    }
    
    public func connect(to device: CBPeripheral) {
        self.manager.stopScan()
        self.manager.connect(device)
    }
    
    public func disconnect() {
        guard let device = self.peripheral else { return }
        
        self.manager.cancelPeripheralConnection(device)
    }
    
    public func write(payload: MiPayload) {
        self.write(value: payload.payload)
    }
    
    public func write(value: Data) {
        guard let txChar = self.txChar else {
            return
        }
        
        self.writeChunked(Data(self.frameHeader + value), to: txChar)
    }
    
    internal func writeChunked(_ data: Data, to characteristic: CBCharacteristic, withChuckSize chunkSize: Int = 20) {
        guard let peripheral = self.peripheral else {
            return
        }
        
        [UInt8](data).chunked(into: chunkSize).forEach { data in
            peripheral.writeValue(Data(data), for: characteristic, type: .withResponse)
        }
    }
}

extension BaseClient: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn && self.autoDiscover { self.discover() }
        
        self.delegate?.didUpdate(bleState: central.state)
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard peripherals.filter({ $0.name == peripheral.name }).isEmpty else { return }
        peripherals.append(peripheral)
        self.delegate?.didDiscover(device: peripheral)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.delegate?.didUpdate(miState: .failedToConnect(device: peripheral, error: error))
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        self.peripheral = peripheral
        self.delegate?.didUpdate(miState: .connected(device: peripheral))
        
        peripheral.discoverServices([])
        self.delegate?.didUpdate(miState: .fetchingServices)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.delegate?.didUpdate(miState: .disconnected(device: peripheral))
    }
}

extension BaseClient: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        self.delegate?.didUpdate(miState: .fetchingCharacteristics)
        
        let discoveredServiceUUIDs = self.discoveredServices.map { $0.uuid }
        let undiscoveredServices = services.filter { !discoveredServiceUUIDs.contains($0.uuid) }
        self.discoveredServices.append(contentsOf: undiscoveredServices)
        
        services.forEach { peripheral.discoverCharacteristics([], for: $0) }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        let discoveredCharUUIDs = self.discoveredCharacteristics.map { $0.uuid }
        let undiscoveredCharacteristics = characteristics.filter { !discoveredCharUUIDs.contains($0.uuid) }
        self.discoveredCharacteristics.append(contentsOf: undiscoveredCharacteristics)
        
        for characteristic in characteristics {
            guard let miUUID = self.services.first(where: { $0.uuid == characteristic.uuid }) else { continue }
            
            switch miUUID {
            case .TX:
                self.txChar = characteristic
            case .RX:
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
            default:
                self.clientDelegate?.peripheral(peripheral, discoveredCharacteristic: characteristic)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let value = characteristic.value, error == nil else { return }
        
        self.clientDelegate?.peripheral(peripheral, characteristic: characteristic, recievedValue: value)
    }
}
