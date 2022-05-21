//
//  Range+Extensions.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/3/22.
//

import Foundation

func intRatio(x: Int, oldRange: ClosedRange<Int>, newRange: ClosedRange<Int>) -> Int {
    let oMin = oldRange.lowerBound
    let oMax = oldRange.upperBound
    let nMin = newRange.lowerBound
    let nMax = newRange.upperBound
    // Complete a range check.
    precondition(oMin != oMax, "Old range bounds cannot be equal!")
    precondition(nMin != nMax, "New range bounds cannot be equal!")
    // Check reversed input range.
    var reverseInput = false
    let oldMin = min(oMin, oMax)
    let oldMax = max(oMin, oMax)
    if oldMin != oMin {
        reverseInput = true
    }
    // Check reversed output range.
    var reverseOutput = false
    let newMin = min(nMin, nMax)
    let newMax = max(nMin, nMax)
    if newMin != nMin {
        reverseOutput = true
    }
    // Calculate portions.
    var portion = (x - oldMin) * (newMax - newMin) / (oldMax - oldMin)
    if reverseInput {
        portion = (oldMax - x) * (newMax - newMin) / (oldMax - oldMin)
    }
    // Calculate result.
    var result = portion + newMin
    if reverseOutput {
        result = newMax - portion
    }
    return result
}

func floatRatio(x: Float, oldRange: ClosedRange<Float>, newRange: ClosedRange<Float>) -> Float {
    let oMin = oldRange.lowerBound
    let oMax = oldRange.upperBound
    let nMin = newRange.lowerBound
    let nMax = newRange.upperBound
    // Complete a range check.
    precondition(oMin != oMax, "Old range bounds cannot be equal!")
    precondition(nMin != nMax, "New range bounds cannot be equal!")
    // Check reversed input range.
    var reverseInput = false
    let oldMin = min(oMin, oMax)
    let oldMax = max(oMin, oMax)
    if oldMin != oMin {
        reverseInput = true
    }
    // Check reversed output range.
    var reverseOutput = false
    let newMin = min(nMin, nMax)
    let newMax = max(nMin, nMax)
    if newMin != nMin {
        reverseOutput = true
    }
    // Calculate portions.
    var portion = (x - oldMin) * (newMax - newMin) / (oldMax - oldMin)
    if reverseInput {
        portion = (oldMax - x) * (newMax - newMin) / (oldMax - oldMin)
    }
    // Calculate result.
    var result = portion + newMin
    if reverseOutput {
        result = newMax - portion
    }
    return result
}
