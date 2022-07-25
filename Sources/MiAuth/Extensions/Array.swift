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
}
