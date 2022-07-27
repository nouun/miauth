//
//  File.swift
//  
//
//  Created by 오하온 on 27/07/22.
//

import Foundation

extension Equatable {
    func isIn(_ array: [Self]) -> Bool {
        !array.filter { $0 == self }.isEmpty
    }
}
