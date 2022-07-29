//
//  File.swift
//  
//
//  Created by 오하온 on 27/07/22.
//

import Foundation

enum MiCommand: CaseIterable {
    case cmdGetInfo, cmdSetKey, cmdLogin, cmdAuth
    case cmdSendData, cmdSendDid, cmdSendKey, cmdSendInfo
    case rcvRdy, rcvOk, rcvTout, rcvErr
    
    case rcvRespKey, rcvRespInfo
    case cfmRegisterOk, cfmRegisterErr
    case cfmLoginOk, cfmLoginErr
    
    case authErr0, authErr1, authErr2, authErr3
    
    static var errors: [Self] = [.authErr0, .authErr1, .authErr2, .authErr3]
    
    var payload: Data {
        get {
            switch self {
            case .cmdGetInfo:      return Data([0xa2, 0x00, 0x00, 0x00])
            case .cmdSetKey:       return Data([0x15, 0x00, 0x00, 0x00])
            case .cmdLogin:        return Data([0x24, 0x00, 0x00, 0x00])
            case .cmdAuth:         return Data([0x13, 0x00, 0x00, 0x00])

            case .cmdSendData:     return Data([0x00, 0x00, 0x00, 0x03, 0x04, 0x00])
            case .cmdSendDid:      return Data([0x00, 0x00, 0x00, 0x00, 0x02, 0x00])
            case .cmdSendKey:      return Data([0x00, 0x00, 0x00, 0x0b, 0x01, 0x00])
            case .cmdSendInfo:     return Data([0x00, 0x00, 0x00, 0x0a, 0x02, 0x00])

            case .rcvRdy:          return Data([0x00, 0x00, 0x01, 0x01])
            case .rcvOk:           return Data([0x00, 0x00, 0x01, 0x00])
            case .rcvTout:         return Data([0x00, 0x00, 0x01, 0x05, 0x01, 0x00])
            case .rcvErr:          return Data([0x00, 0x00, 0x01, 0x05, 0x03, 0x00])
                
            case .rcvRespKey:      return Data([0x00, 0x00, 0x00, 0x0d, 0x01, 0x00])
            case .rcvRespInfo:     return Data([0x00, 0x00, 0x00, 0x0c, 0x02, 0x00])

            case .cfmRegisterOk:   return Data([0x11, 0x00, 0x00, 0x00])
            case .cfmRegisterErr:  return Data([0x12, 0x00, 0x00, 0x00])
            case .cfmLoginOk:      return Data([0x21, 0x00, 0x00, 0x00])
            case .cfmLoginErr:     return Data([0x23, 0x00, 0x00, 0x00])

            case .authErr0:        return Data([0xe0, 0x00, 0x00, 0x00])
            case .authErr1:        return Data([0xe1, 0x00, 0x00, 0x00])
            case .authErr2:        return Data([0xe2, 0x00, 0x00, 0x00])
            case .authErr3:        return Data([0xe3, 0x00, 0x00, 0x00])
            }
        }
    }
}
