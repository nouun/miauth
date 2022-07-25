import XCTest
import CryptoKit
@testable import MiAuth

final class MiCrytpoTests: XCTestCase {
    func testGenerateRandomKey() {
        XCTAssertEqual(16, MiCrypto.generateRandomKey().count)
    }
    
    func testGenerateKeyPair() {
        let (_, pubKey) = MiCrypto.generateKeyPair()
        let pubKeyData = MiCrypto.data(fromPublicKey: pubKey)
        XCTAssertEqual(64, pubKeyData.count)
    }
    
    func testConvertPrivateKey() {
        let (privKey, _) = MiCrypto.generateKeyPair()
        let privKeyData = MiCrypto.data(fromPrivateKey: privKey)
        let privKey2 = MiCrypto.data(toPrivateKey: privKeyData)!
        let privKeyData2 = MiCrypto.data(fromPrivateKey: privKey2)
        XCTAssertEqual(privKeyData, privKeyData2)
    }
    
    func testConvertPublicKey() {
        let (_, pubKey) = MiCrypto.generateKeyPair()
        let pubKeyData = MiCrypto.data(fromPublicKey: pubKey)
        let pubKey2 = MiCrypto.data(toPublicKey: pubKeyData)!
        let pubKeyData2 = MiCrypto.data(fromPublicKey: pubKey2)
        XCTAssertEqual(pubKeyData, pubKeyData2)
    }

    func testGeneratePrivateKey() {
        let expected = Data([ 0xB5, 0xDC, 0xA0, 0xAE, 0xC3, 0x1A, 0x89, 0x32, 0xD0, 0xF5, 0x3C, 0xBC, 0xBC, 0xF0, 0xCF, 0xDD,
                              0x83, 0x3C, 0x35, 0x5C, 0xAD, 0xA1, 0x02, 0x5C, 0xC0, 0x76, 0xE0, 0x13, 0x43, 0x9D, 0xDE, 0xC2,
                              0xB4, 0x01, 0x7B, 0x54, 0x6A, 0x11, 0xD7, 0x9A, 0x75, 0x8D, 0xB9, 0xD0, 0x15, 0xA2, 0xED, 0x89,
                              0x26, 0xCF, 0x82, 0x17, 0x9B, 0x59, 0x36, 0x79, 0x18, 0x7D, 0x62, 0x3B, 0x5E, 0x43, 0x0F, 0xCA ])
        
        let data = Data([ 0xB5, 0xDC, 0xA0, 0xAE, 0xC3, 0x1A, 0x89, 0x32, 0xD0, 0xF5, 0x3C, 0xBC, 0xBC, 0xF0,
                          0xCF, 0xDD, 0x83, 0x3C, 0x35, 0x5C, 0xAD, 0xA1, 0x02, 0x5C, 0xC0, 0x76, 0xE0, 0x13,
                          0x43, 0x9D, 0xDE, 0xC2, 0xB4, 0x01, 0x7B, 0x54, 0x6A, 0x11, 0xD7, 0x9A, 0x75, 0x8D,
                          0xB9, 0xD0, 0x15, 0xA2, 0xED, 0x89, 0x26, 0xCF, 0x82, 0x17, 0x9B, 0x59, 0x36, 0x79,
                          0x18, 0x7D, 0x62, 0x3B, 0x5E, 0x43, 0x0F, 0xCA, 0x55, 0x56, 0x10, 0xD6, 0x67, 0x7F,
                          0x63, 0x09, 0xA2, 0x3A, 0xF6, 0x18, 0x8C, 0xA9, 0x33, 0xA3, 0x6E, 0x8C, 0xC7, 0xCF,
                          0x28, 0x79, 0x1A, 0xFA, 0x3C, 0xD8, 0x09, 0xAD, 0xFC, 0x75, 0x58, 0x4E ])
        let privKey = MiCrypto.data(toPrivateKey: data)!
        let privData = MiCrypto.data(fromPrivateKey: privKey)
        let pubData = MiCrypto.data(fromPublicKey: privKey.publicKey)
        XCTAssertEqual(data, privData)
        XCTAssertEqual(expected, pubData)
    }

    func testGenerateSecret() {
        let (privKey1, pubKey1) = MiCrypto.generateKeyPair()
        let (privKey2, pubKey2) = MiCrypto.generateKeyPair()
        let secret1 = MiCrypto.generateSecret(fromPrivateKey: privKey1, publicKey: pubKey2)
        let secret2 = MiCrypto.generateSecret(fromPrivateKey: privKey2, publicKey: pubKey1)
        XCTAssertEqual(secret1, secret2)
    }

    func testDeriveKey() {
        let expectedWithKey    = Data([0x40, 0xcc, 0xc0, 0xee, 0x05, 0x8c, 0x3a, 0x1d, 0x37, 0xc0, 0x8e, 0x6f, 0x72, 0xbc, 0x2c, 0x57,
                                       0xc0, 0xa4, 0x06, 0xaa, 0xa8, 0x01, 0xa0, 0xb1, 0xb7, 0x2f, 0x22, 0xc8, 0xc3, 0xec, 0x93, 0x0d,
                                       0x3f, 0x15, 0x1e, 0x2e, 0xb3, 0x8a, 0x23, 0x03, 0xd8, 0x62, 0x5a, 0x18, 0x08, 0x4d, 0xaa, 0x15,
                                       0x66, 0x74, 0x96, 0xdc, 0xfb, 0xc5, 0x3b, 0xa3, 0x07, 0x4c, 0xe3, 0x5d, 0x6c, 0x90, 0xd9, 0x87])
        let expectedWithoutKey = Data([0x10, 0x4e, 0xc0, 0xed, 0xa0, 0x32, 0xb6, 0xd2, 0x13, 0xc2, 0x45, 0x35, 0x9e, 0x58, 0x5d, 0x3b,
                                       0xfd, 0x4b, 0x7c, 0x5d, 0x68, 0x3c, 0x99, 0xf4, 0x9f, 0xd8, 0x6a, 0xaf, 0x0d, 0xe0, 0xf6, 0xb0,
                                       0xbf, 0xaf, 0xb8, 0x97, 0xe3, 0xb3, 0x72, 0x7a, 0xaa, 0x8f, 0x8a, 0xd6, 0xb2, 0x1a, 0x73, 0x7c,
                                       0x1d, 0x85, 0xc3, 0xaa, 0xe3, 0x40, 0x96, 0x9f, 0x26, 0x8d, 0x2d, 0x95, 0xca, 0x88, 0x48, 0xc1])

        let key = Data([0x5a, 0x3d, 0x98, 0x7d, 0x45, 0xf6, 0x48, 0x4a, 0xff, 0x82, 0xff, 0xde, 0x1e, 0x91, 0x05, 0xb7,
                        0xf6, 0xcc, 0x79, 0xfa, 0x74, 0x67, 0xf1, 0x2c, 0x58, 0x55, 0xad, 0x9e, 0x3f, 0x1d, 0x8f, 0x2f])
        var derived = MiCrypto.deriveKey(from: key, withSalt: Data([0x01, 0x02, 0x03, 0x04]))
        XCTAssertEqual(expectedWithKey, derived)

        derived = MiCrypto.deriveKey(from: key)
        XCTAssertEqual(expectedWithoutKey, derived)
    }

    func testHash() {
        let expected = Data([0x23, 0x5d, 0x7f, 0x91, 0x09, 0x74, 0xac, 0xb5, 0x94, 0xd7, 0x6a, 0x16, 0x52, 0xa8, 0x56, 0xce,
                             0x4f, 0x26, 0x9e, 0x30, 0x60, 0xd7, 0xc8, 0x51, 0x2e, 0x94, 0xb2, 0xda, 0x34, 0x5d, 0x30, 0x83])

        let key = Data([0xe2, 0xb2, 0x74, 0xf0, 0x81, 0x28, 0xa6, 0x2a, 0x95, 0x75, 0x28, 0x8b, 0xed, 0x16, 0x9b, 0x3e])
        let hash = MiCrypto.hash(key: key, withData: Data([0x01, 0x02, 0x03, 0x04]))
        XCTAssertEqual(expected.hex(), hash.hex())
    }

    func testEncryptDID() {
        let expected = Data([0xae, 0xeb, 0xd7, 0x0f, 0x8c, 0x2b, 0xdf, 0x8c])

        let key = Data([0x4f, 0xeb, 0x71, 0x65, 0x98, 0x2b, 0xf1, 0xc6, 0x18, 0x3a, 0x51, 0xb8, 0xca, 0xdd, 0x0e, 0xec])
        let did = Data([0x01, 0x02, 0x03, 0x04])
        let ct = MiCrypto.encrypt(did: did, withKey: key)
        XCTAssertEqual(expected.hex(), ct?.hex())
    }
    
//    func testConvertKey() {
//        let key = MiCrypto.pem(toPrivateKey: "-----BEGIN PRIVATE KEY-----\n" +
//                                             "MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgayQ94bHP7lgRMLBw\n" +
//                                             "xjXIlXrFbwwsPUCxr4cy1s1uwYOhRANCAARJJeTPBRKfplEWpKMk/Ibu/UzRdnF/\n" +
//                                             "CTjMvSOH/VLQ79hRYsIMD8xyyoWosY9h75gKcOGm5/8V9SiYge5ZuPSv\n" +
//                                             "-----END PRIVATE KEY-----\n")!
//        print(key.x963Representation.hex(withSeparator: ""))
//        let key2 = MiCrypto.data(toPrivateKey: key.x963Representation)!
//        print(key2.x963Representation.hex(withSeparator: ""))
//    }

    func testEncryptUART() {
        let expected = Data([0x55, 0xab, 0x03, 0x00, 0x00, 0xad, 0xf3, 0x99, 0x08, 0x6b, 0x9e, 0x0b, 0xd0, 0x59, 0x36, 0x6a, 0xd1, 0x0d, 0xfa])

        let key  = Data([0x23, 0x9b, 0x3c, 0x7e, 0x92, 0xdc, 0x6d, 0x6d, 0x2f, 0xa1, 0x74, 0xa2, 0x15, 0xae, 0xdf, 0x2e])
        let iv   = Data([0x01, 0x02])
        let msg  = Data([0x55, 0xaa, 0x03, 0x20, 0x01, 0x10, 0x0e])
        let rand = Data([0x01, 0x02, 0x03, 0x04])
        let ct = MiCrypto.encryptUart(withKey: key, iv: iv, massage: msg, rand: rand)
        XCTAssertEqual(expected, ct)
    }

    func testDecryptUART() {
        let expected = Data([0x23, 0x01, 0x10, 0x32, 0x35, 0x37, 0x30, 0x30, 0x2f, 0x30, 0x30, 0x30, 0x30, 0x31, 0x33, 0x33,
                             0x37, 0xcd, 0x65, 0xc3, 0x22])
        
        let encrypted = Data([0x55, 0xab, 0x10, 0x01, 0x00, 0x4c, 0x4e, 0x49, 0xc6, 0x5c, 0x20, 0x84, 0x35, 0xf7, 0xe0, 0x50,
                              0xe5, 0x69, 0x04, 0xad, 0xb8, 0xfe, 0x6e, 0x2e, 0xb1, 0x29, 0x7c, 0xf9, 0xe0, 0xaf, 0xba, 0xf2])
        let key = Data([0x88, 0x7e, 0xd6, 0xae, 0x8e, 0xa3, 0x18, 0x95, 0x46, 0xa5, 0x5f, 0x0d, 0x0a, 0x62, 0x16, 0xce])
        let iv = Data([0x65, 0x9b, 0x73, 0x62])
        let ct = MiCrypto.decryptUart(withKey: key, iv: iv, message: encrypted)
        XCTAssertEqual(expected, ct)
    }

    func testRegister() {
        let expectedSecret  = Data([0xfa, 0xc3, 0xa6, 0xfd, 0x59, 0x1d, 0xce, 0xa2, 0x1f, 0x9f, 0x4f, 0xef, 0xe2, 0x97, 0x80, 0x4f,
                                    0x49, 0x29, 0x15, 0x27, 0xae, 0x81, 0x8b, 0x28, 0x5f, 0x4a, 0x75, 0xa6, 0xfa, 0xb7, 0x2a, 0xf8])
        let expectedDerived = Data([0x0c, 0xf5, 0x61, 0x50, 0x03, 0x81, 0x0d, 0x89, 0xc2, 0x33, 0xa1, 0x2a, 0x8f, 0xc5, 0x10, 0x0e,
                                    0x31, 0x29, 0x9d, 0x80, 0xc4, 0xc2, 0x90, 0xdc, 0x7d, 0x33, 0xf1, 0x9e, 0xc4, 0x2e, 0xa4, 0x8a,
                                    0x95, 0xc5, 0x54, 0x4f, 0x10, 0x5f, 0xe7, 0xeb, 0xb8, 0xb3, 0x92, 0x33, 0xc6, 0x54, 0x2b, 0x1f,
                                    0xff, 0x90, 0xb2, 0x20, 0x62, 0x65, 0x08, 0x0b, 0xf5, 0x16, 0x36, 0x5f, 0xd8, 0xd7, 0x58, 0xfe])
        let expectedDIDKey  = Data([0xc4, 0x2e, 0xa4, 0x8a, 0x95, 0xc5, 0x54, 0x4f, 0x10, 0x5f, 0xe7, 0xeb, 0xb8, 0xb3, 0x92, 0x33])
        let expectedDIDCT   = Data([0x64, 0x67, 0x35, 0xcc, 0x7a, 0x96, 0x37, 0x3a, 0xab, 0xbd, 0x93, 0xaf, 0xa0, 0x89, 0xbb, 0x6c,
                                    0xd2, 0xd0, 0x80, 0x30, 0x21, 0x01, 0x00, 0x7a])

        let data = Data([0x49, 0x25, 0xe4, 0xcf, 0x05, 0x12, 0x9f, 0xa6, 0x51, 0x16, 0xa4, 0xa3, 0x24, 0xfc, 0x86, 0xee,
                         0xfd, 0x4c, 0xd1, 0x76, 0x71, 0x7f, 0x09, 0x38, 0xcc, 0xbd, 0x23, 0x87, 0xfd, 0x52, 0xd0, 0xef,
                         0xd8, 0x51, 0x62, 0xc2, 0x0c, 0x0f, 0xcc, 0x72, 0xca, 0x85, 0xa8, 0xb1, 0x8f, 0x61, 0xef, 0x98,
                         0x0a, 0x70, 0xe1, 0xa6, 0xe7, 0xff, 0x15, 0xf5, 0x28, 0x98, 0x81, 0xee, 0x59, 0xb8, 0xf4, 0xaf,
                         0x6b, 0x24, 0x3d, 0xe1, 0xb1, 0xcf, 0xee, 0x58, 0x11, 0x30, 0xb0, 0x70, 0xc6, 0x35, 0xc8, 0x95,
                         0x7a, 0xc5, 0x6f, 0x0c, 0x2c, 0x3d, 0x40, 0xb1, 0xaf, 0x87, 0x32, 0xd6, 0xcd, 0x6e, 0xc1, 0x83])
        let privKey = MiCrypto.data(toPrivateKey: data)!

        let remoteInfo        = Data([0x01, 0x00, 0x00, 0x00, 0x00, 0x62, 0x6c, 0x74, 0x2e, 0x34, 0x2e, 0x31,
                                      0x38, 0x6e, 0x35, 0x38, 0x32, 0x36, 0x36, 0x6b, 0x67, 0x67, 0x30, 0x30])
        let remotePubKeyBytes = Data([0x2a, 0xfe, 0x2a, 0x8c, 0x1c, 0x56, 0xe5, 0xe7, 0x07, 0x21, 0x66, 0x5c, 0xd2, 0x0d, 0x01, 0x72,
                                      0x73, 0x11, 0x1e, 0xca, 0xec, 0xeb, 0x1e, 0x4d, 0x64, 0x1e, 0x7b, 0x7a, 0x12, 0x2a, 0x9c, 0x30,
                                      0x41, 0xe5, 0xcb, 0xc9, 0x62, 0xee, 0xfb, 0xdb, 0x15, 0x5f, 0xfd, 0x95, 0x84, 0x7a, 0x0d, 0x87,
                                      0x62, 0x80, 0x32, 0x91, 0xfc, 0x28, 0x66, 0xc5, 0x67, 0x2c, 0xee, 0xe0, 0xe7, 0x7d, 0x77, 0xfc])
        let remotePubKey = MiCrypto.data(toPublicKey: remotePubKeyBytes)!

        let secret = MiCrypto.generateSecret(fromPrivateKey: privKey, publicKey: remotePubKey)!
        let derived = MiCrypto.deriveKey(from: secret)
        let didKey = derived.from(28, to: 44)
        let didCT = MiCrypto.encrypt(did: remoteInfo.from(4), withKey: didKey)
        XCTAssertEqual(expectedSecret, secret)
        XCTAssertEqual(expectedDerived, derived)
        XCTAssertEqual(expectedDIDKey, didKey)
        XCTAssertEqual(expectedDIDCT, didCT)
    }

    func testLogin() {
        let expectedRemoteInfo = Data([0x47, 0x14, 0x67, 0xea, 0x7e, 0xd6, 0x06, 0x4f, 0x8d, 0xd7, 0x2f, 0x41, 0x6c, 0x07, 0x9d, 0xcb,
                                       0x3b, 0xb7, 0x8e, 0x3c, 0x94, 0xa5, 0x1e, 0x97, 0xb9, 0x8e, 0xf7, 0x62, 0x3a, 0x77, 0x98, 0xe5])
        let expectedInfo       = Data([0xbb, 0xb9, 0x9b, 0x6a, 0x6f, 0x1a, 0xe4, 0x19, 0xe3, 0xb1, 0x3d, 0xb9, 0x35, 0x14, 0xf3, 0xe1,
                                       0x2a, 0x18, 0x43, 0x03, 0x3f, 0x27, 0x63, 0x92, 0xee, 0xa9, 0x90, 0x68, 0xaf, 0xfc, 0xa7, 0x53])
        let expectedDevKey     = Data([0x3c, 0x2f, 0xda, 0xe6, 0x9f, 0x87, 0x46, 0x66, 0x3a, 0x7d, 0x91, 0x02, 0x97, 0x24, 0xb0, 0x72])
        let expectedAppKey     = Data([0x12, 0xa4, 0x12, 0x2d, 0xbe, 0x3c, 0xf6, 0x0f, 0x3b, 0xdc, 0xb3, 0x71, 0x39, 0xc3, 0x46, 0x11])
        let expectedDevIV      = Data([0xcd, 0x01, 0x60, 0x50])
        let expectedAppIV      = Data([0xc8, 0x7d, 0xe6, 0xf1])

        let token      = Data([0x0c, 0xf5, 0x61, 0x50, 0x03, 0x81, 0x0d, 0x89, 0xc2, 0x33, 0xa1, 0x2a])
        let randomKey  = Data([0xa8, 0x69, 0x97, 0x83, 0xc1, 0xf0, 0x3c, 0x7b, 0x73, 0xa0, 0x46, 0xcd, 0xb6, 0x13, 0xa9, 0xbf])
        let remoteKey  = Data([0x90, 0xfd, 0xec, 0x0e, 0xce, 0x05, 0x01, 0x6d, 0x7f, 0x11, 0x6b, 0x50, 0xfc, 0xa4, 0xb4, 0xbf])

        let salt = randomKey + remoteKey
        let saltInv = remoteKey + randomKey

        let derivedKey = MiCrypto.deriveKey(from: token, withSalt: salt)
        let devKey = derivedKey.to(16)
        let appKey = derivedKey.from(16, to: 32)
        let devIv  = derivedKey.from(32, to: 36)
        let appIv  = derivedKey.from(36, to: 40)
        let info = MiCrypto.hash(key: appKey, withData: salt)
        let remoteInfo = MiCrypto.hash(key: devKey, withData: saltInv)

        XCTAssertEqual(expectedRemoteInfo, remoteInfo)
        XCTAssertEqual(expectedInfo, info)
        XCTAssertEqual(expectedDevKey, devKey)
        XCTAssertEqual(expectedAppKey, appKey)
        XCTAssertEqual(expectedDevIV,  devIv)
        XCTAssertEqual(expectedAppIV,  appIv)
    }
}
