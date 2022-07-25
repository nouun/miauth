//
//  MiUUID.swift
//  
//
//  Created by 오하온 on 18/07/22.
//

import CoreBluetooth

enum MiUUID: String, CaseIterable {
    case UART  = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
    case TX    = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
    case RX    = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
    case AUTH  = "0000FE95-0000-1000-8000-00805F9B34FB"
    case UPNP  = "0010"
    case AVDTP = "0019"
    case KEY   = "0014"
    
    var uuid: CBUUID {
        return CBUUID(string: self.rawValue)
    }
}
