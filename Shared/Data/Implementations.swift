//
//  Array+Extensions.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/11/22.
//

import Foundation
import CollectionConcurrencyKit

extension SortViewModel {
    // MARK: - Logarithmic - Quick Sort
    // Based on the original inspiration for this app (github:Myphz/sortvisualizer)
    @MainActor
    func _quickSort(_ array: inout [SortItem], _ left: Int, _ right: Int) async {
        func _subCompare1(i: Int, j: Int, pivot: Int, _ by: (Int, Int) -> Bool = (>=)) async -> Bool {
            let result = try? await compare(firstIndex: pivot, secondIndex: i, by: by)
            guard result != nil else {
                return false
            }
            return result! && i < j
        }
        func _subCompare2(pivot: Int, j: Int, _ by: (Int, Int) -> Bool = (>=)) async -> Bool {
            let result = try? await compare(firstIndex: pivot, secondIndex: j, by: by)
            guard result != nil else {
                return false
            }
            return result!
        }
        guard (!Task.isCancelled && left <= right && left >= 0 && right >= 0) else {
            return
        }
        let pivot = left
        await changeColor(index: left, color: .red)
        var i = left
        var j = right
        await changeColor(index: j, color: .blue)
        while i < j {
            guard running else {
                return
            }
            while await _subCompare1(i: i, j: j, pivot: pivot) {
                await resetColor(index: i)
                i++
                await changeColor(index: i, color: .green)
            }
            while await !_subCompare2(pivot: pivot, j: j) {
                await resetColor(index: j)
                j--
                await changeColor(index: j, color: .blue)
            }
            await changeColor(index: pivot, color: .red)
            if i < j {
                await swap(i, j)
            }
        }
        await swap(pivot, j)
        for index in [i, j, pivot] {
            await resetColor(index: index)
        }
        await _quickSort(&array, left, j - 1)
        await _quickSort(&array, j + 1, right)
    }
    
    @MainActor
    func quickSort() async {
        var proxy: [SortItem] = data
        await _quickSort(&proxy, 0, proxy.count - 1)
        proxy = data
    }
    
    // MARK: - Logarithmic - Merge Sort
    // Based on original inspiration (github:Myphz/sortvisualizer)
    @MainActor
    func _mergeSort(_ start: Int, _ end: Int) async {
        if (start >= end - 1) {
            return
        }
        // ~ is bitwise NOT operator; the JS version uses a unique ~~ operator for double bitwise NOT.
        let mid = start + ~(~((end - start) / 2))
        await _mergeSort(start, mid)
        await _mergeSort(mid, end)
        var cache = Array(repeating: data[0], count: end - start)
        var k = mid
        // This was previously a C-style for loop with *two* updates, written as such:
        // for (var i = start, r = 0; i < mid; r++, i++)
        var r = 0
        for i in start..<mid {
            if (!running) {
                return
            }
            let kVal = await getValue(index: k)!
            let iVal = await getValue(index: i)!
            while k < end && kVal < iVal {
                cache[r] = data[k]
                r++
                k++
            }
            cache[r] = data[i]
            r++
        }
        for i in 0..<(k - start) {
            if (!running) {
                return
            }
            data[i + start] = cache[i]
            data[i + start].value = 1 + i + start
            await changeColor(index: i + start, color: .red)
            if (sound) {
                toner.play(carrierFrequency: floatRatio(
                    x: Float(i + start),
                    oldRange: Float(0)...Float(data.endIndex - 1),
                    newRange: Float(200)...Float(600)
                ))
            }
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000))
            await resetColor(index: i + start)
        }
    }
    
    @MainActor
    func mergeSort() async {
        await _mergeSort(0, data.count)
    }

    // MARK: - Logarithmic - Heap Sort
    @MainActor
    func _heapify(_ length: Int, _ i: Int) async {
        let indices = data.indices
        if (!running) {
            return
        }
        var largest = i
        let left = i * 2 + 1
        let right = left + 1
        if indices.contains(left) && indices.contains(largest) {
            let firstCompare = try! await compare(firstIndex: left, secondIndex: largest)
            if left < length && firstCompare {
                largest = left
            }
        }
        if indices.contains(right) && indices.contains(largest) {
            let secondCompare = try! await compare(firstIndex: right, secondIndex: largest)
            if right < length && secondCompare {
                largest = right
            }
        }
        if largest != i {
            await swap(i, largest)
            await _heapify(length, largest)
        }
    }
    
    @MainActor
    func heapSort() async {
        let length = data.count
        var i = length / 2 - 1
        var k = length - 1
        while i >= 0 {
            if (!running) {
                return
            }
            await _heapify(length, i)
            i--
        }
        while k >= 0 {
            if (!running) {
                return
            }
            await swap(0, k)
            await _heapify(k, 0)
            k--
        }
    }
    
    // MARK: - Quadratic - Bubble Sort
    // Based on inspiration (github:Myphz/sortvisualizer)
    @MainActor
    func bubbleSort() async {
        for i in 1..<data.count {
            for j in 0..<(data.count - i) {
                if !running {
                    return
                }
                if try! await compare(firstIndex: j, secondIndex: j + 1) {
                    await swap(j, j + 1)
                }
            }
        }
    }
    
    // MARK: - Quadratic - Selection Sort
    // This is the one algorithm that I didn't rewrite following the JS implementation; it ended up taking 400x longer and required a ton of iterations and concurrency helpers.
    @MainActor
    func selectionSort(by areInIncreasingOrder: ((SortItem, SortItem) -> Bool) = (<)) async {
        guard !Task.isCancelled else {
            return
        }
        for i in 0..<(data.count-1) {
            var key = i
            for j in i+1..<data.count where try! await compare(firstIndex: key, secondIndex: j) {
                key = j
            }
            guard i != key else { continue }
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000))
            await swap(i, key)
        }
    }
    
    // MARK: - Quadratic - Insertion Sort
    @MainActor
    func insertionSort() async {
        while data != data.sorted() {
            for i in (1..<data.count) {
                if !running {
                    return
                }
                var j = i
                while j > 0 {
                    if data[j] < data[j - 1] {
                        await swap(j, j - 1)
                    }
                    j--
                }
            }
        }
    }
    
    // MARK: - Quadratic - Gnome Sort
    @MainActor
    func gnomeSort() async {
        var i = 1
        var j = 2
        while i < data.count {
            if !running {
                return
            }
            if try! await !compare(firstIndex: i - 1, secondIndex: i) {
                i = j
                j++
            } else {
                await swap(i - 1, i)
                i--
                if i == 0 {
                    i = j
                    j++
                }
            }
        }
    }
    
    // MARK: - Quadratic - Shaker Sort
    @MainActor
    func shakerSort() async {
        var sorted = true
        while sorted {
            for i in 0..<(data.count - 1) {
                if !running {
                    return
                }
                if try! await compare(firstIndex: i, secondIndex: i + 1) {
                    await swap(i, i + 1)
                    sorted = true
                }
            }
            if !sorted {
                break
            }
            sorted = false
            for j in (1..<(data.count - 1)).reversed() {
                if !running {
                    return
                }
                if try! await compare(firstIndex: j - 1, secondIndex: j) {
                    await swap(j - 1, j)
                    sorted = true
                }
            }
        }
    }
    
    // MARK: - Quadratic - Odd-Even Sort
    @MainActor
    func oddEvenSort() async {
        var sorted = false
        while !sorted {
            sorted = true
            for first in [1, 0] {
                for i in stride(from: first, to: data.count - 1, by: 2) {
                    if !running {
                        return
                    }
                    if try! await compare(firstIndex: i, secondIndex: i + 1) {
                        await swap(i, i + 1)
                        sorted = false
                    }
                }
            }
        }
    }
    
    // MARK: - Quadratic - Pancake Sort
    @MainActor
    func _flip(_ k: Int) async {
        var k = k
        var left = 0
        while left < k {
            if !running {
                return
            }
            await swap(left, k)
            k--
            left++
        }
    }
    
    @MainActor
    func _maxIndex(_ k: Int) async -> Int {
        var index = 0
        for i in 0..<k {
            if try! await compare(firstIndex: i, secondIndex: index) {
                index = i
            }
        }
        return index
    }
    
    @MainActor
    func pancakeSort() async {
        var n = data.count
        while n > 1 {
            if !running {
                return
            }
            let maxIndex = await _maxIndex(n)
            if maxIndex != n {
                await _flip(maxIndex)
                await _flip(n - 1)
            }
            n--
        }
    }
    
    // MARK: Weird - Bitonic Sort
    // TODO: Implement bitonic sort
    
    // MARK: Weird - Radix Sort
    // TODO: Implement radix sort
    
    // MARK: Weird - Shell Sort
    // TODO: Implement shell sort
    
    // MARK: Weird - Comb Sort
    // TODO: Implement comb sort
    
    // MARK: Weird - Bogo Sort
    // TODO: Implement bogo sort
    
    // MARK: Weird - Stooge Sort
    // TODO: Implement stooge sort
}
