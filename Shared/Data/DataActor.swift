//
//  DataActor.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/16/22.
//

import Foundation

actor DataActor {
    private var data: [SortItem] = SortItem.syncSequenceOf(numItems: 128)
    
    func getData() -> [SortItem] {
        return data
    }
    
    func setData(_ data: [SortItem]) {
        self.data = data
    }
}
