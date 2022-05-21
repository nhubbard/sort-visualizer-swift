//
//  ShellSortImpl.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 5/21/22.
//

import Foundation

extension SortViewModel {
    @MainActor
    func shellSort() async {
        guard !Task.isCancelled else {
            return
        }
        let n = data.count
        var interval = ~(~(n / 2))
        var j: Int
        while interval > 0 {
            for i in interval..<n {
                if !running {
                    return
                }
                let temp = data[i]
                j = i
                let value = await getValue(index: j - interval)!
                while j >= interval && value > temp.value {
                    if !running {
                        return
                    }
                    await swap(j, j - interval)
                    await changeColor(index: j, color: .red)
                    data[j].value = j + 1
                    // TODO: toner.play(await calculateFrequency(j))
                    await delay()
                    await resetColor(index: j)
                    j -= interval
                }
                data[j] = temp
                // TODO: toner.play(await calculateFrequency(j))
                data[j].value = j + 1
                await changeColor(index: j, color: .blue)
                await delay()
                await resetColor(index: j)
            }
            interval = ~(~(interval / 2))
        }
    }
}
