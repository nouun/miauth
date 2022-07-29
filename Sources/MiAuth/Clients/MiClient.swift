//
//  File.swift
//
//
//  Created by 오하온 on 20/07/22.
//

import CoreBluetooth
import Foundation

public enum MiSequenceState: Int {
    case recvInfo = 0
    case sendKey = 1
    case recvKey = 2
    case sendDid = 3
    case confirm = 4
    case commSend = 5
    case commRecv = 6
}

private struct MiSequence {
    var state: MiSequenceState
    var function: (() -> Void)?
    
    init(state: MiSequenceState, function: (() -> Void)? = nil) {
        self.state = state
        self.function = function
    }
    
    func call() {
        self.function?()
    }
}

public final class MiClient: BaseClient {
    private var token: Data?
    private var upnpChar: CBCharacteristic?
    private var avdtpChar: CBCharacteristic?
    
    private var sequence: [MiSequence] = []
    private var sequenceIndex = 0
    private var state: MiSequenceState {
        self.sequence[self.sequenceIndex].state
    }
    
    private var expectedCommand = Data()
    private var expectedFrames: UInt16 = 0x0000
    private var receivedData = Data()
    private var sendData = Data()
    
    private var uartIgnore = 0
    private var uartIteration: Int32 = 0
    private var keys: [String:Data] = [:]
    private var remoteInfo = Data()
    private var remoteKey = Data()
    
    private var registerRestarting = false
    private var registerDid: Data?
    
    public convenience init(withToken token: Data? = nil) {
        self.init()
        self.token = token
    }
    
    public required init() {
        super.init()
        
        self.frameHeader = Data([0x55, 0xAB])
        self.services   += [.UPNP, .AVDTP ]
        self.clientDelegate = self
    }
    
    fileprivate func isState(_ state: MiSequenceState) -> Bool {
        self.sequence[self.sequenceIndex].state == state
    }
    
    private func nextState() {
        self.sequenceIndex += 1
        
        if self.sequenceIndex >= self.sequence.count {
            self.sequenceIndex = 0
        }
        
        print("Switching to state \(self.state)")
        self.sequence[self.sequenceIndex].call()
    }
    
    public func setState(to state: MiSequenceState) {
        let foundState = self.sequence
            .enumerated()
            .first(where: { $0.element.state.rawValue == state.rawValue })
        
        guard let sequenceIndex = foundState?.offset else {
            print("Unable to find state \(state) in current sequence.")
            return
        }
        
        self.sequenceIndex = sequenceIndex
        self.sequence[self.sequenceIndex].call()
    }
    
    private func clearBuffers() {
        self.expectedCommand = Data()
        self.expectedFrames = 0x0000
        
        self.receivedData = Data()
        self.sendData = Data()
        
        self.uartIteration = 0
        self.keys = [:]
        
        self.remoteInfo = Data()
        self.remoteKey = Data()
    }

    // MARK: - Writing
    
    private func writeAvdtpParcel(command: MiCommand) {
        self.writeAvdtp(command.payload)
    }
    
    private func writeAvdtpParcel(_ payload: Data) {
        guard let avdtpChar = self.avdtpChar else {
            print("AVDTP characteristic not discovered yet")
            return
        }
        
        self.writeParcel(payload, to: avdtpChar)
    }
    
    private func writeAvdtp(command: MiCommand) {
        self.writeAvdtp(command.payload)
    }
    
    private func writeAvdtp(_ payload: Data) {
        guard let avdtpChar = self.avdtpChar else {
            print("AVDTP characteristic not discovered yet")
            return
        }
        
        self.writeChunked(payload, to: avdtpChar)
    }
    
    private func writeUpnpParcel(command: MiCommand) {
        self.writeUpnpParcel(command.payload)
    }
    
    private func writeUpnpParcel(_ payload: Data) {
        guard let upnpChar = self.upnpChar else {
            print("UPNP characteristic not discovered yet")
            return
        }
        
        self.writeParcel(payload, to: upnpChar)
    }
    
    private func writeUpnp(command: MiCommand) {
        self.writeUpnp(command.payload)
    }
    
    private func writeUpnp(_ payload: Data) {
        guard let upnpChar = self.upnpChar else {
            print("UPNP characteristic not discovered yet")
            return
        }
        
        self.writeChunked(payload, to: upnpChar)
    }
    
    internal override func encrypt(data: Data) -> Data {
        guard let appKey = self.keys["appKey"],
              let appIv = self.keys["appIv"] else {
            print("keys not set")
            return data
        }
        
        guard let encrypted = MiCrypto.encryptUart(withKey: appKey, iv: appIv, massage: data, it: self.uartIteration) else {
            print("Failed to encrypt data, falling back to unencrypted data")
            return data
        }
        
        return encrypted
    }
    
    public override func write(value: Data) {
        self.setState(to: .commRecv)
        
        self.uartIteration += 1
        self.expectedCommand = value.from(2, to: 4)
        if self.expectedCommand[0] == 1,
           let last = value.last {
            self.expectedFrames = UInt16(last) + 2
        }
        
        super.write(value: value)
    }
    
    private func decrypt(data: Data) -> (destination: UInt8, command: Data, decoded: Data)? {
        guard let devKey = keys["devKey"],
              let devIv = keys["devIv"],
              let decoded = MiCrypto.decryptUart(withKey: devKey, iv: devIv, message: data) else {
            return nil
        }
        
        return (decoded[0], decoded.from(1, to: 3), decoded.from(3, to: -4))
    }
}

// MARK: - Login and Register

extension MiClient {
    public func login(withToken token: Data) {
        self.clearBuffers()
        self.token = token
        
        let randomKey = MiCrypto.generateRandomKey()
        
        self.sequence = [
            MiSequence(state: .sendKey, function: {
                self.sendData = randomKey

                self.writeUpnp(command: .cmdLogin)
                self.writeAvdtp(command: .cmdSendKey)
            }),
            MiSequence(state: .recvKey),
            MiSequence(state: .recvInfo, function: {
                self.remoteKey = self.receivedData
            }),
            MiSequence(state: .sendDid, function: {
                self.remoteInfo = self.receivedData
                
                guard let (sendData, expectedRemoteInfo, keys) = self.calculateLoginInfo(withRandomKey: randomKey) else { return }
                self.sendData = sendData
                self.keys = keys
                
                if expectedRemoteInfo != self.remoteInfo {
                    print("Expected remote info isn't equal to remote info, try registering again")
                    print("Expected: " + expectedRemoteInfo.hex())
                    print("Actual: " + self.remoteInfo.hex())
                    self.delegate?.didUpdate(miState: .invalidToken)
                    return
                }
                
                self.writeAvdtp(command: .cmdSendInfo)
            }),
            MiSequence(state: .confirm),
            MiSequence(state: .commSend),
            MiSequence(state: .commRecv)
        ]
        self.sequenceIndex = 0
        self.sequence[self.sequenceIndex].call()
    }
    
    public func register(withDid did: Data? = nil) {
        self.clearBuffers()
        let (privKey, pubKey) = MiCrypto.generateKeyPair()
        
        let timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
            guard let peripheral = self.peripheral else {
                print("Not connected to a device")
                return
            }
    
            self.clearBuffers()
            self.upnpChar = nil
            self.avdtpChar = nil
            
            self.registerRestarting = true
            self.registerDid = did
            
            self.disconnect()
            self.delegate?.didUpdate(miState: .waitingForButtonPress)
            print("Press the power button within the next 5 seconds")
            Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                self.connect(to: peripheral)
            }
        }
        
        self.sequence = [
            MiSequence(state: .recvInfo, function: {
                self.writeUpnp(command: .cmdGetInfo)
            }),
            MiSequence(state: .sendKey, function: {
                self.remoteInfo = self.receivedData.from(4)
                if self.remoteInfo.count != 20 {
                    print("Invalid remote info length")
                    return
                }
                
                self.sendData = MiCrypto.data(fromPublicKey: pubKey)
                self.writeUpnp(command: .cmdSetKey)
                self.writeAvdtp(command: .cmdSendData)
            }),
            MiSequence(state: .recvKey, function: nil),
            MiSequence(state: .sendDid, function: {
                self.remoteKey = self.receivedData
                
                guard let (did, token) = self.calculateDID(withPrivateKey: privKey) else { return }
                self.sendData = did
                self.token = token
                
                self.writeAvdtp(command: .cmdSendDid)
            }),
            MiSequence(state: .confirm, function: {
                timer.invalidate()
                self.writeUpnp(command: .cmdAuth)
            }),
            MiSequence(state: .commSend, function: {
                guard let token = self.token else {
                    print("Token not set")
                    return
                }
                
                self.delegate?.didUpdate(miState: .registered(token: token))
            })
        ]
        self.sequenceIndex = 0
        
        self.sequence[self.sequenceIndex].call()
    }
}

// MARK: - Data handling

extension MiClient {
    private func handleReceive(frame: UInt16, data: Data) {
        if frame == 0 {
            self.expectedFrames = UInt16(data[4]) + 0x100 * UInt16(data[5])
            print("Expecting \(self.expectedFrames) frames")
            self.receivedData = Data()
            self.writeAvdtp(command: .rcvRdy)
        } else {
            self.receivedData += data.from(2)
        }
        
        if frame == self.expectedFrames {
            print("Received \(self.receivedData.hex())")
            self.writeAvdtp(command: .rcvOk)
            self.nextState()
        }
    }
    
    private func handleSend(frame: UInt16, data: Data) {
        if frame != 0x0000 {
            print("Mi unknown error, try registering")
            return
        }
        
        switch data {
        case MiCommand.rcvRdy.payload:
            print("Ready to receive key")
            self.writeAvdtpParcel(self.sendData)
        case MiCommand.rcvTout.payload:
            print("Receive timeout")
        case MiCommand.rcvErr.payload:
            print("Error receiving data")
        case MiCommand.rcvOk.payload:
            print("Confirmed received key")
            self.nextState()
        default:
            print("Mi unknown send response")
        }
    }
    
    private func handleConfirm(frame: UInt16, data: Data) {
        switch data {
        case MiCommand.cfmRegisterOk.payload:
            print("Mi register successful")
        case MiCommand.cfmRegisterErr.payload:
            print("Mi register failed")
        case MiCommand.cfmLoginOk.payload:
            self.delegate?.didUpdate(miState: .authenticated)
            print("Mi login successful")
        case MiCommand.cfmLoginErr.payload:
            print("Mi login successful")
        default:
            print("Mi unknown confirm response")
        }
        
        self.nextState()
    }
    
    private func handleCommReceive(data: Data) {
        if data.to(2) == self.frameHeader {
            if data[2] != self.expectedFrames {
                print("Rogue packet header received, started ignoring")
                self.uartIgnore += 1
                return
            }
            
            self.expectedFrames = UInt16(data[2])
        }
        
        if self.uartIgnore != 0 {
            print("Message ignored")
            if self.uartIgnore > 3 {
                print("Command never came")
                self.setState(to: .commSend)
            }
            
            return
        }
        
        self.receivedData += data
        
        if self.receivedData.count < self.expectedFrames * 2 { return }
        guard let (dst, cmd, dec) = self.decrypt(data: self.receivedData) else { return }
        
        if self.expectedFrames == dec.count * 2 && dst >= 0x23 && cmd == self.expectedCommand {
            self.receivedData = dec
            self.setState(to: .commSend)
        }
    }
}

// MARK: - Cryptography

extension MiClient {
    private func calculateDID(withPrivateKey privateKey: MiCrypto.PrivateKey) -> (did: Data, token: Data)? {
        guard let remotePublicKey = MiCrypto.data(toPublicKey: self.remoteKey) else { return nil }
        guard let sharedKey = MiCrypto.generateSecret(fromPrivateKey: privateKey, publicKey: remotePublicKey) else { return nil }
        
        let derivedSharedKey = MiCrypto.deriveKey(from: sharedKey)
        
        let token = derivedSharedKey.to(12)
        let bindKey = derivedSharedKey.from(12, to: 28)
        let key = derivedSharedKey.from(28, to: 44)
        
        let did = self.remoteInfo
        guard let didCt = MiCrypto.encrypt(did: did, withKey: key) else { return nil }
        
        print("token: \(token.hex())")
        print("bingKey: \(bindKey.hex())")
        print("key: \(key.hex())")
        print("did: \(did.hex())")
        print("didCt: \(didCt.hex())")
        
        return (didCt, token)
    }
    
    private func calculateLoginInfo(withRandomKey randomKey: Data) -> (info: Data, expectedRemoteInfo: Data, keys: [String:Data])? {
        guard let token = self.token else {
            print("Login token not specified")
            return nil
        }
        let salt = randomKey + self.remoteKey
        let saltInv = self.remoteKey + randomKey
        
        let derivedKey = MiCrypto.deriveKey(from: token, withSalt: salt)
        let keys = [
            "devKey": derivedKey.to(16),
            "appKey": derivedKey.from(16, to: 32),
            "devIv": derivedKey.from(32, to: 36),
            "appIv": derivedKey.from(36, to: 40)
        ]
        
        let info = MiCrypto.hash(key: keys["appKey"]!, withData: salt)
        let expectedRemoteInfo = MiCrypto.hash(key: keys["devKey"]!, withData: saltInv)
        
        print("HKDF: \(derivedKey.hex())")
        keys.map { "\($0.key): \($0.value)" }.forEach { print($0) }
        
        return (info, expectedRemoteInfo, keys)
    }
}

// MARK: - MiClientDelegate Implementation

extension MiClient: MiClientDelegate {
    func connectedTo(peripheral: CBPeripheral) -> Bool {
        return !self.registerRestarting
    }
    
    func disconnectedFrom(peripheral: CBPeripheral) -> Bool {
        return !self.registerRestarting
    }
    
    func peripheral(_ peripheral: CBPeripheral, discoveredCharacteristic characteristic: CBCharacteristic) {
        if characteristic.uuid == MiUUID.UPNP.uuid {
            print("Found UPNP char")
            self.upnpChar = characteristic
        }
        if characteristic.uuid == MiUUID.AVDTP.uuid {
            print("Found AVDTP char")
            self.avdtpChar = characteristic
        }
        
        if self.avdtpChar.isSome() && self.upnpChar.isSome() {
            if self.registerRestarting {
                print("Restarting registration")
                self.registerRestarting = false
                self.register(withDid: self.registerDid)
            } else {
                self.delegate?.didUpdate(miState: .authenticationReady)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, characteristic: CBCharacteristic, recievedValue data: Data) {
        let value = data
        
        print("Received: \(data.hex())")
        
        if value.isIn(MiCommand.errors.map { $0.payload }) {
            print("Auth failed. Previous session not reset, missing BLE DID or something.")
            self.delegate?.didUpdate(miState: .authenticationError(error: value))
            return
        }
        
        if self.state == .commRecv {
            self.handleCommReceive(data: data)
            return
        }
            
        if !(value.isIn(MiCommand.allCases.map { $0.payload }) || (value[0] > 0x00 && value[0] <= self.expectedFrames)) { return }
        
        var frame = UInt16(value[0])
        if value.count > 1 {
            frame += 0x100 * UInt16(data[1])
        }
        
        if self.state.isIn([.recvInfo, .recvKey]) {
            if data.count < 6 {
                print("Invalid data")
                return
            }
            
            self.handleReceive(frame: frame, data: data)
        } else if self.state.isIn([.sendDid, .sendKey]) {
            self.handleSend(frame: frame, data: data)
        } else if self.state == .confirm {
            self.handleConfirm(frame: frame, data: data)
        }
    }
}
