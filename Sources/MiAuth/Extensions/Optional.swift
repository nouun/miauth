//
//  File.swift
//  
//
//  Created by 오하온 on 23/07/22.
//

import Foundation

extension Optional {
    func isSome() -> Bool {
        return self != nil
    }
    
    func isNone() -> Bool {
        return self == nil
    }
    
    func or(_ fallback: Wrapped) -> Wrapped {
        if let value = self { return value }
        return fallback
    }
    
    func or(call fallbackFunction: () -> Wrapped) -> Wrapped {
        if let value = self { return value }
        return fallbackFunction()
    }
}
