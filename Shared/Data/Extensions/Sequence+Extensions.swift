//
//  Cycle.swift
//  Sort2 (Shared)
//
//  Created by Nicholas Hubbard on 5/20/22.
//

import Foundation

public extension Sequence {
    /**
     Returns an iterator-sequence cycling infinitely through the sequence.
     ```
     let values = [1, 2, 3].cycle()
     // 1, 2, 3, 1, 2, 3, 1, ...
     ```
     - Returns: An iterator-sequence cycling infinitely through the sequence.
     */
    func cycle() -> CycleIterator<Self> {
        return CycleIterator(sequence: self)
    }
}

/// An iterator-sequence for cycling through a collection.
/// See the `cycle` and `cycle(times:)` Sequence and LazySequenceProtocol methods.
public struct CycleIterator<S: Sequence>: IteratorProtocol, LazySequenceProtocol {
    private let sequence: S
    private var iterator: S.Iterator
    private var times: Int

    fileprivate init(sequence: S, times: Int = -1) {
        self.sequence = sequence
        self.iterator = sequence.makeIterator()
        self.times = times
    }

    public mutating func next() -> S.Iterator.Element? {
        guard times != 0 else {
            return nil
        }

        if let next = iterator.next() {
            return next
        }

        times -= 1
        guard times != 0 else {
            return nil
        }

        iterator = sequence.makeIterator()
        return iterator.next()
    }
}
