//
//  File.swift
//
//
//  Created by 오하온 on 20/07/22.
//

import CoreBluetooth
import Foundation

private struct MiSequence {
    enum State: Int {
        case initial = -1
        case recvInfo = 0
        case sendKey = 1
        case recvKey = 2
        case sendDid = 3
        case confirm = 4
        case comm = 5
    }
    
    private var state: State
    private var function: (() -> Void)?
    
    init(state: State, function: (() -> Void)? = nil) {
        self.state = state
        self.function = function
    }
}

public class MiClient: BaseClient {
    private var token: Data?
    private var upnpChar: CBCharacteristic?
    private var avdtpChar: CBCharacteristic?
    
    private var sequence: [MiSequence] = []
    private var sequenceIndex = 0
    
    private var chunkBuffer = Data()
    
    public convenience init(withToken token: Data? = nil) {
        self.init()
        self.token = token
    }
    
    public required init() {
        super.init()
        
        self.frameHeader = [ 0x55, 0xAB ]
        self.services   += [ MiUUID.UPNP, MiUUID.AVDTP ]
        self.clientDelegate = self
    }
    
    func register() {
        self.sequence = [
            MiSequence(state: .initial, function: nil),
            MiSequence(state: .recvInfo, function: {
                guard let upnpChar = self.upnpChar else {
                    self.logDelegate?.log("UPNP characteristic not discovered")
                    return
                }
                
                self.writeChunked(MiPayload.cmdGetInfo.payload, to: upnpChar)
            }),
            MiSequence(state: .sendKey, function: {
                
            }),
            MiSequence(state: .recvKey, function: nil),
            MiSequence(state: .sendDid, function: {
            }),
            MiSequence(state: .confirm, function: {
            }),
            MiSequence(state: .comm, function: nil)
        ]
        self.sequenceIndex = 0
    }
}

extension MiClient: MiClientDelegate {
    func peripheral(_ peripheral: CBPeripheral, discoveredCharacteristic characteristic: CBCharacteristic) {
        if characteristic.uuid == MiUUID.UPNP.uuid {
            self.logDelegate?.log("Found UPNP char")
            
            if self.token == nil {
                self.logDelegate?.log("Registering token")
                self.register()
            }
            self.upnpChar = characteristic
        }
        if characteristic.uuid == MiUUID.AVDTP.uuid {
            self.logDelegate?.log("Found AVDTP char")
            self.avdtpChar = characteristic
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, characteristic: CBCharacteristic, recievedValue data: Data) {
        let value = data
        
        self.logDelegate?.log("Recieved \(value.hex())")
    }
}
