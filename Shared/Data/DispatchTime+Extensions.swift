//
//  DispatchTime+Extensions.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/14/22.
//

import Foundation

func floatDelay(millis: Float) -> DispatchTime {
    return DispatchTime.now() + DispatchTimeInterval.microseconds(Int(millis * 1000))
}
