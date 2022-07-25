//
//  File.swift
//  
//
//  Created by 오하온 on 20/07/22.
//

import Foundation

public enum MiPayload: CaseIterable {
    case keyResponse
    
    case serialNumber
    case firmwareVersion
    
    
    case cmdGetInfo, cmdSetKey, cmdLogin, cmdAuth
    case cmdSendData, cmdSendDid, cmdSendKey, cmdSendInfo
    case rcvRdy, rcvOk, rcvTout, rcvErr
    
    public var name: String {
        get {
            switch self {
            case .keyResponse:     return "Authentication Key"
            case .serialNumber:    return "Serial Number"
            case .firmwareVersion: return "Firmware Version"


            case .cmdGetInfo:  return "CMD_GET_INFO"
            case .cmdSetKey:   return "CMD_SET_KEY"
            case .cmdLogin:    return "CMD_LOGIN"
            case .cmdAuth:     return "CMD_AUTH"

            case .cmdSendData: return "CMD_SEND_DATA"
            case .cmdSendDid:  return "CMD_SEND_DID"
            case .cmdSendKey:  return "CMD_SEND_KEY"
            case .cmdSendInfo: return "CMD_SEND_INFO"

            case .rcvRdy:      return "RCV_RDY"
            case .rcvOk:       return "RCV_OK"
            case .rcvTout:     return "RCV_TOUT"
            case .rcvErr:      return "RCV_ERR"
            }
        }
    }
    
    var payload: Data {
        get {
            switch self {
            case .keyResponse:     return Data([ 0x03, 0x22, 0x01, 0x50, 0x20 ])
            case .serialNumber:    return Data([ 0x03, 0x20, 0x01, 0x10, 0x0E ])
            case .firmwareVersion: return Data([ 0x03, 0x20, 0x01, 0x1A, 0x10 ])


            case .cmdGetInfo:      return Data([ 0xa2, 0x00, 0x00, 0x00 ])
            case .cmdSetKey:       return Data([ 0x15, 0x00, 0x00, 0x00 ])
            case .cmdLogin:        return Data([ 0x24, 0x00, 0x00, 0x00 ])
            case .cmdAuth:         return Data([ 0x13, 0x00, 0x00, 0x00 ])

            case .cmdSendData:     return Data([ 0x00, 0x00, 0x00, 0x03, 0x04, 0x00 ])
            case .cmdSendDid:      return Data([ 0x00, 0x00, 0x00, 0x00, 0x02, 0x00 ])
            case .cmdSendKey:      return Data([ 0x00, 0x00, 0x00, 0x0b, 0x01, 0x00 ])
            case .cmdSendInfo:     return Data([ 0x00, 0x00, 0x00, 0x0a, 0x02, 0x00 ])

            case .rcvRdy:          return Data([ 0x00, 0x00, 0x01, 0x01 ])
            case .rcvOk:           return Data([ 0x00, 0x00, 0x01, 0x00 ])
            case .rcvTout:         return Data([ 0x00, 0x00, 0x01, 0x05, 0x01, 0x00 ])
            case .rcvErr:          return Data([ 0x00, 0x00, 0x01, 0x05, 0x03, 0x00 ])
            }
        }
    }
}
