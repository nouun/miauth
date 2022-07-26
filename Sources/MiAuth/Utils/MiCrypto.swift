//
//  File.swift
//  
//
//  Created by 오하온 on 21/07/22.
//

import CommonCrypto
import CryptoKit
import Foundation

public class MiCrypto {
    private typealias HMAC = CryptoKit.HMAC
    private typealias HKDF = CryptoKit.HKDF
    
    typealias Key = SymmetricKey
    typealias PrivateKey = P256.KeyAgreement.PrivateKey
    typealias PublicKey = P256.KeyAgreement.PublicKey
    
    /// Generate a cryptographically secure random 16 byte key.
    ///
    /// - Returns: Generated 16 byteY key
    static func generateRandomKey() -> Data {
        return SymmetricKey(size: .init(bitCount: 16 * 8)).withUnsafeBytes { Data($0) }
    }
    
    /// Generate a key pair using SECP256R1.
    ///
    /// - Returns: Private and public key pair
    static func generateKeyPair() -> (PrivateKey, PublicKey) {
        let privateKey = PrivateKey()
        return (privateKey, privateKey.publicKey)
    }
    
    /// Convert a public key into it's ANSI x9.63 representation.
    ///
    /// - Returns: The ANSI x9.63 representation
    static func data(fromPublicKey key: PublicKey) -> Data {
        return key.x963Representation.from(1)
    }
    
    static func data(toPublicKey data: Data) -> PublicKey? {
        return try? PublicKey(x963Representation: [0x04] + data)
    }
    
    static func pem(toPublicKey pem: String) -> PublicKey? {
        return try? PublicKey(pemRepresentation: pem)
    }
    
    static func data(fromPrivateKey key: PrivateKey) -> Data {
        return key.x963Representation.from(1)
    }
    
    static func data(toPrivateKey data: Data) -> PrivateKey? {
        return try? PrivateKey(x963Representation: [0x04] + data)
    }
    
    static func pem(toPrivateKey pem: String) -> PrivateKey? {
        return try? PrivateKey(pemRepresentation: pem)
    }
    
    static func generateSecret(fromPrivateKey privateKey: PrivateKey, publicKey: PublicKey) -> Data? {
        return try? privateKey.sharedSecretFromKeyAgreement(with: publicKey).withUnsafeBytes { Data($0) }
    }
    
    cgstatic func deriveKey(from input: Data, withSalt salt: Data? = nil) -> Data {
        let info: Data
        if salt.isSome() {
            info = "mible-login-info".data(using: .utf8)!
        } else {
            info = "mible-setup-info".data(using: .utf8)!
        }
        
        let key: Key
        if let salt = salt {
            key = HKDF<SHA256>.deriveKey(inputKeyMaterial: Key(data: input), salt: salt, info: info, outputByteCount: 64)
        } else {
            key = HKDF<SHA256>.deriveKey(inputKeyMaterial: Key(data: input), info: info, outputByteCount: 64)
        }
        
        return key.withUnsafeBytes { Data($0) }
    }
    
    static func hash(key: Data, withData data: Data? = nil) -> Data {
        var hmac = HMAC<SHA256>(key: Key(data: key))
        if let data = data { hmac.update(data: data) }
        return hmac.finalize().withUnsafeBytes { Data($0) }
    }
    
    static func encrypt(did: Data, withKey key: Data) -> Data? {
        let aad = Data([0x64, 0x65, 0x76, 0x49, 0x44])
        let nonce = Data([0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b])
        
        let ccm = AESCCM(key: key, iv: nonce, adata: aad, tagLength: 4)
        return ccm.encrypt(data: did)
    }
    
    static func encryptUart(withKey key: Data, iv: Data, massage: Data, it: Int32 = 0, rand: Data? = nil) -> Data? {
        let message = massage.from(2)
        let size = message.to(1)
        let dataInput = message.from(1) + rand.or(Data.random(4))
        
        let it = Data.from(int: it).pad(toLength: 4, with: 0)
        let nonce = iv + Data([0, 0, 0, 0]) + it
        
        let ccm = AESCCM(key: key, iv: nonce, adata: nil, tagLength: 4)
        guard let ct = ccm.encrypt(data: dataInput) else {
            return nil
        }
        
        let header = Data([0x55, 0xab])
        let data = size + it.to(2) + ct
        let crc = crc16(data)
        
        return header + data + crc
    }
    
    static func decryptUart(withKey key: Data, iv: Data, message: Data) -> Data? {
        let header = message.to(2)
        if header != Data([0x55, 0xab]) {
            print("Invalid header: \(header)")
            return nil
        }
        
        let it = message.from(3, to: 5)
        let ct = message.from(5, to: -2)
        
        let nonce = iv + Data([0, 0, 0, 0]) + it + Data([0, 0])

        let ccm = AESCCM(key: key, iv: nonce, adata: nil, tagLength: 4)
        return ccm.decrypt(data: ct)
    }
}
