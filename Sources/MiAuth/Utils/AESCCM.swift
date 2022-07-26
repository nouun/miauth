//
//  AESCCM.swift
//  
//
//  Created by 오하온 on 25/07/22.
//

import CommonCrypto
import Foundation

struct AESCCM {
    private let key: Data
    private let initialiazationVector: Data
    private let associatedData: Data
    private let tagLength: Int
    private let blockSize: Int
    private let bufferSize: Int
    
    init(key: Data, iv: Data, adata: Data?, tagLength: Int) {
        self.key = key
        self.initialiazationVector = iv
        self.associatedData = adata.or(Data())
        self.tagLength = tagLength
        
        self.blockSize = 16
        self.bufferSize = 1024 * blockSize
    }
    
    func decrypt(data: Data) -> Data? {
        let data = data.subdata(in: 0..<data.count-self.tagLength)
        
        var counter = self.generateCounterBlock()
        
        var out = Data()
        
        for block in data.chunked(into: self.bufferSize) {
            for subBlock in block.chunked(into: self.blockSize) {
                for j in stride(from: 15, to: 0, by: -1) {
                    counter[j] = (counter[j] + 1) & 255
                    
                    if counter[j] != UInt8("\0") {
                        break
                    }
                }
                
                guard let counterCipher = self.aesEncrypt(data: counter) else { return nil }
                let counterXor = self.xor(data: subBlock, with: counterCipher)
                
                out.append(counterXor)
            }
        }
        
        return out
    }
    
    func encrypt(data: Data) -> Data? {
        var counter = self.generateCounterBlock()
        guard let counterCypher = self.aesEncrypt(data: counter) else { return nil }
        
        var out = Data()
        var lastSubBlock = Data(repeating: 0x00, count: self.blockSize)
        var exitNext = -1
        
        for block in data.chunked(into: self.bufferSize) {
            var encrypted = Data()
            
            for subBlock in block.chunked(into: self.blockSize) {
                let napl = self.formattingNAP(forBlock: subBlock, exitNext: exitNext, data: data)
                
                if exitNext == -1 {
                    exitNext = 0
                    
                    for naplChunk in napl.chunked(into: self.blockSize) {
                        let xoredData = self.xor(data: naplChunk, with: lastSubBlock)
                        guard let cypherData = self.aesEncrypt(data: xoredData) else { return nil }
                        lastSubBlock = cypherData
                    }
                } else {
                    let xoredData = self.xor(data: napl, with: lastSubBlock)
                    guard let cypherData = self.aesEncrypt(data: xoredData) else { return nil }
                    lastSubBlock = cypherData
                }
                
                for j in stride(from: 15, to: 0, by: -1) {
                    counter[j] = (counter[j] + 1) & 255
                    
                    if counter[j] != UInt8("\0") {
                        break
                    }
                }
                
                guard let counterCypher = aesEncrypt(data: counter) else { return nil }
                let xor = self.xor(data: subBlock, with: counterCypher)
                encrypted.append(xor)
            }
            
            out.append(contentsOf: encrypted)
        }
        
        let tag = self.xor(data: lastSubBlock, with: counterCypher).to(self.tagLength)
        out.append(tag)
        
        return out
    }
    
    private func xor(data bytes1: Data, with bytes2: Data) -> Data {
        Data(zip(bytes1, bytes2).map { (byte1, byte2) in byte1 ^ byte2 })
    }
    
    private func aesEncrypt(data: Data) -> Data? {
        // Convert Data to NSData to work with Objective-C CommonCrypto
        let data = data as NSData
        let key = self.key as NSData
        let iv = self.initialiazationVector as NSData
        
        let cryptData = NSMutableData(length: data.length)!
        var cryptLength: size_t = 0
        
        let cryptStatus = CCCrypt(CCOperation(kCCEncrypt),
                                  CCAlgorithm(kCCAlgorithmAES128),
                                  CCOptions(kCCOptionECBMode),
                                  key.bytes, key.length, iv.bytes,
                                  data.bytes, data.length,
                                  cryptData.mutableBytes, cryptData.length,
                                  &cryptLength)
        
        if cryptStatus != kCCSuccess {
            return nil
        }
        
        return cryptData as Data
    }
    
    private func generateCounterBlock() -> Data {
        let iv = self.initialiazationVector
        
        return Data()
            .appending(contentsOf: [UInt8(0x0 | ((14 - iv.count) & 0x07))])
            .appending(iv)
            .padEnd(toBlockSize: self.blockSize, with: 0x00)
        
    }
    
    private func formattingNAP(forBlock block: Data, exitNext: Int, data: Data) -> Data {
        if exitNext == -1 {
            var out = self.getHeader(withPayloadLength: data.count)
            
            if self.associatedData.count > 0 {
                out += self.getAssociatedData()
            }
            
            return out
                .appending(block)
                .padEnd(toBlockSize: self.blockSize, with: 0x00)
        }
        
        return block.padEnd(toBlockSize: self.blockSize, with: 0x00)
    }
    
    private func getAssociatedData() -> Data {
        var value = self.associatedData.count
        
        var out = Data()
        
        if value == 0 {
            out.append(contentsOf: [0x00])
        } else {
            let data = [0, 0]
                .map { _ in
                    let byte = UInt8(value & 0xFF)
                    value >>= 8
                    return byte
                }
                .reversed()
            out.append(Data(data))
        }
        
        return out
            .appending(self.associatedData)
            .padEnd(toBlockSize: self.blockSize, with: 0x00)
    }
    
    private func getHeader(withPayloadLength len: Int) -> Data {
        var out = Data(repeating: 0x00, count: self.blockSize)
        var len = len
        let qLen = 15 - self.initialiazationVector.count
        var fl = 0x00
        fl |= (self.associatedData.count > 0) ? 0x40 : 0x00
        fl |= (((self.tagLength - 2) / 2) & 0x07) << 3
        fl |= (qLen - 1) & 0x07
        out[0] = UInt8(fl)
        
        for i in stride(from: 0, to: qLen, by: 1) {
            out[self.blockSize - i - 1] = UInt8(len & 255)
            len >>= 8
        }
        
        self.initialiazationVector.enumerated().forEach { out[$0.offset + 1] = $0.element }
        
        return out
    }
}
