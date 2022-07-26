//
//  Array.swift
//  
//
//  Created by 오하온 on 19/07/22.
//

import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Self(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
    
    func from(_ start: Int, to end: Int? = nil) -> Self {
        let start = start < 0 ? self.count + start : start
        
        guard var end = end else {
            return Self(self[start...])
        }
        
        end = end < 0 ? self.count + end : end
        return Self(self[start..<end])
    }
    
    func to(_ end: Int) -> Self {
        self.from(0, to: end)
    }
}
