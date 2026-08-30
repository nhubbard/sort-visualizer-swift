func swap2(_ arr: inout [Int], _ i: Int, _ j: Int) {
    arr.swapAt(i, j)
}

func reverseInclusive(_ arr: inout [Int], _ lo: Int, _ hi: Int) {
    var lo = lo
    var hi = hi
    while lo < hi {
        swap2(&arr, lo, hi)
        lo += 1
        hi -= 1
    }
}

// -- Fixed-size sorting networks ----------------------------------------------------------------

func swapTwo(_ arr: inout [Int], _ start: Int) {
    if arr[start] > arr[start + 1] {
        swap2(&arr, start, start + 1)
    }
}

func swapThree(_ arr: inout [Int], _ start: Int) {
    if arr[start] > arr[start + 1] {
        if arr[start] <= arr[start + 2] {
            swap2(&arr, start, start + 1)
        } else if arr[start + 1] > arr[start + 2] {
            swap2(&arr, start, start + 2)
        } else {
            let temp = arr[start]
            arr[start] = arr[start + 1]
            arr[start + 1] = arr[start + 2]
            arr[start + 2] = temp
        }
    } else if arr[start + 1] > arr[start + 2] {
        if arr[start] > arr[start + 2] {
            let temp = arr[start + 2]
            arr[start + 2] = arr[start + 1]
            arr[start + 1] = arr[start]
            arr[start] = temp
        } else {
            swap2(&arr, start + 2, start + 1)
        }
    }
}

func swapFour(_ arr: inout [Int], _ start: Int) {
    if arr[start] > arr[start + 1] {
        swap2(&arr, start, start + 1)
    }
    if arr[start + 2] > arr[start + 3] {
        swap2(&arr, start + 2, start + 3)
    }
    if arr[start + 1] > arr[start + 2] {
        if arr[start] <= arr[start + 2] {
            if arr[start + 1] <= arr[start + 3] {
                swap2(&arr, start + 1, start + 2)
            } else {
                let temp = arr[start + 1]
                arr[start + 1] = arr[start + 2]
                arr[start + 2] = arr[start + 3]
                arr[start + 3] = temp
            }
        } else if arr[start] > arr[start + 3] {
            swap2(&arr, start + 1, start + 3)
            swap2(&arr, start, start + 2)
        } else if arr[start + 1] <= arr[start + 3] {
            let temp = arr[start + 1]
            arr[start + 1] = arr[start]
            arr[start] = arr[start + 2]
            arr[start + 2] = temp
        } else {
            let temp = arr[start + 1]
            arr[start + 1] = arr[start]
            arr[start] = arr[start + 2]
            arr[start + 2] = arr[start + 3]
            arr[start + 3] = temp
        }
    }
}

func swapFive(_ arr: inout [Int], _ start: Int, _ end: inout Int) {
    end = start + 4
    var pta = end
    end += 1
    var ptt = pta
    pta -= 1

    if arr[pta] > arr[ptt] {
        let key = arr[ptt]
        arr[ptt] = arr[pta]
        ptt -= 1
        pta -= 1

        if pta > start, arr[pta - 1] > key {
            arr[ptt] = arr[pta]
            ptt -= 1
            pta -= 1
            arr[ptt] = arr[pta]
            ptt -= 1
            pta -= 1
        }

        if pta >= start, arr[pta] > key {
            arr[ptt] = arr[pta]
            ptt -= 1
            pta -= 1
        }

        arr[ptt] = key
    }
}

func tailSwapEight(_ arr: inout [Int], _ start: Int, _ end: inout Int) {
    var pta = end
    end += 1
    var ptt = pta
    pta -= 1

    if arr[pta] > arr[ptt] {
        let key = arr[ptt]
        arr[ptt] = arr[pta]
        ptt -= 1
        pta -= 1

        if arr[pta - 2] > key {
            for _ in 0 ..< 3 {
                arr[ptt] = arr[pta]
                ptt -= 1
                pta -= 1
            }
        }

        if pta > start, arr[pta - 1] > key {
            arr[ptt] = arr[pta]
            ptt -= 1
            pta -= 1
            arr[ptt] = arr[pta]
            ptt -= 1
            pta -= 1
        }

        if pta >= start, arr[pta] > key {
            arr[ptt] = arr[pta]
            ptt -= 1
            pta -= 1
        }

        arr[ptt] = key
    }
}

func swapSix(_ arr: inout [Int], _ start: Int, _ end: inout Int) {
    swapFive(&arr, start, &end)
    tailSwapEight(&arr, start, &end)
}

func swapSeven(_ arr: inout [Int], _ start: Int, _ end: inout Int) {
    swapSix(&arr, start, &end)
    tailSwapEight(&arr, start, &end)
}

func swapEight(_ arr: inout [Int], _ start: Int, _ end: inout Int) {
    swapSeven(&arr, start, &end)
    tailSwapEight(&arr, start, &end)
}

/// ~4 items: one of the fixed sorting networks above. 5+: an unguarded insertion sort --
/// swapFive/Six/Seven/Eight handle the first 5-8 elements by hand, then a binary-search insertion
/// (the `while top > 1` loop) places everything past index 8.
func tailSwap(_ arr: inout [Int], _ start: Int, _ nmemb: Int) {
    switch nmemb {
    case 0, 1:
        return
    case 2:
        swapTwo(&arr, start)
        return
    case 3:
        swapThree(&arr, start)
        return
    case 4:
        swapFour(&arr, start)
        return
    case 5:
        swapFour(&arr, start)
        var end = 0
        swapFive(&arr, start, &end)
        return
    case 6:
        swapFour(&arr, start)
        var end = 0
        swapSix(&arr, start, &end)
        return
    case 7:
        swapFour(&arr, start)
        var end = 0
        swapSeven(&arr, start, &end)
        return
    case 8:
        swapFour(&arr, start)
        var end = 0
        swapEight(&arr, start, &end)
        return
    default:
        break
    }

    swapFour(&arr, start)
    var end = 0
    swapEight(&arr, start, &end)
    end = start + 8
    var offset = 8

    while offset < nmemb {
        var top = offset
        offset += 1
        var pta = end
        end += 1
        let ptt = pta
        pta -= 1

        if arr[pta] <= arr[ptt] {
            continue
        }

        let temp = arr[ptt]
        while top > 1 {
            let mid = top / 2
            if arr[pta - mid] > temp {
                pta -= mid
            }
            top -= mid
        }

        var i = ptt
        while i > pta {
            arr[i] = arr[i - 1]
            i -= 1
        }
        arr[pta] = temp
    }
}

// -- Parity merges --------------------------------------------------------------------------

func parityMerge4(_ arr: inout [Int], _ start: Int, _ dest: inout [Int], _ auxOffset: Int) {
    var auxP = auxOffset
    var ptl = start
    var ptr = start + 4

    for _ in 0 ..< 3 {
        if arr[ptl] <= arr[ptr] {
            dest[auxP] = arr[ptl]
            ptl += 1
        } else {
            dest[auxP] = arr[ptr]
            ptr += 1
        }
        auxP += 1
    }
    if arr[ptl] <= arr[ptr] {
        dest[auxP] = arr[ptl]
    } else {
        dest[auxP] = arr[ptr]
    }

    ptl = start + 3
    ptr = start + 7
    auxP += 4

    for _ in 0 ..< 3 {
        if arr[ptl] > arr[ptr] {
            dest[auxP] = arr[ptl]
            ptl -= 1
        } else {
            dest[auxP] = arr[ptr]
            ptr -= 1
        }
        auxP -= 1
    }
    if arr[ptl] > arr[ptr] {
        dest[auxP] = arr[ptl]
    } else {
        dest[auxP] = arr[ptr]
    }
}

func parityMerge8(_ arr: inout [Int], _ from: [Int], _ start: Int) {
    var mainP = start
    var ptl = 0
    var ptr = 8

    for _ in 0 ..< 7 {
        if from[ptl] <= from[ptr] {
            arr[mainP] = from[ptl]
            ptl += 1
        } else {
            arr[mainP] = from[ptr]
            ptr += 1
        }
        mainP += 1
    }
    if from[ptl] <= from[ptr] {
        arr[mainP] = from[ptl]
    } else {
        arr[mainP] = from[ptr]
    }

    ptl = 7
    ptr = 15
    mainP += 8

    for _ in 0 ..< 7 {
        if from[ptl] > from[ptr] {
            arr[mainP] = from[ptl]
            ptl -= 1
        } else {
            arr[mainP] = from[ptr]
            ptr -= 1
        }
        mainP -= 1
    }
    if from[ptl] > from[ptr] {
        arr[mainP] = from[ptl]
    } else {
        arr[mainP] = from[ptr]
    }
}

func parityMerge16(_ arr: inout [Int], _ start: Int, _ aux: inout [Int]) {
    if arr[start + 3] <= arr[start + 4], arr[start + 7] <= arr[start + 8],
       arr[start + 11] <= arr[start + 12]
    {
        return
    }

    parityMerge4(&arr, start, &aux, 0)
    parityMerge4(&arr, start + 8, &aux, 8)
    parityMerge8(&arr, aux, start)
}

// -- Bottom-up tail merge -----------------------------------------------------------------------

func partialBackwardMerge(_ arr: inout [Int], _ aux: inout [Int], _ start: Int, _ nmemb: Int, _ block: Int) {
    var m = start + block
    var e = start + nmemb - 1
    let r = m
    m -= 1

    if arr[m] <= arr[r] {
        return
    }
    while arr[m] <= arr[e] {
        e -= 1
    }

    for i in r ..< (r + (e - m)) {
        aux[i - r] = arr[i]
    }

    var s = e - r
    arr[e] = arr[m]
    e -= 1
    m -= 1

    if arr[start] <= aux[0] {
        repeat {
            while arr[m] > aux[s] {
                arr[e] = arr[m]
                e -= 1
                m -= 1
            }
            arr[e] = aux[s]
            e -= 1
            s -= 1
        } while s >= 0
    } else {
        repeat {
            while arr[m] <= aux[s] {
                arr[e] = aux[s]
                e -= 1
                s -= 1
            }
            arr[e] = arr[m]
            e -= 1
            m -= 1
        } while m >= start
        repeat {
            arr[e] = aux[s]
            e -= 1
            s -= 1
        } while s >= 0
    }
}

func tailMerge(_ arr: inout [Int], _ aux: inout [Int], _ start: Int, _ nmemb: Int, _ block: Int) {
    let pte = start + nmemb
    var block = block

    while block < nmemb {
        var pta = start
        while pta + block < pte {
            if pta + block * 2 < pte {
                partialBackwardMerge(&arr, &aux, pta, block * 2, block)
                pta += block * 2
                continue
            }
            partialBackwardMerge(&arr, &aux, pta, pte - pta, block)
            break
        }
        block *= 2
    }
}

// -- Quad merge -----------------------------------------------------------------------------

func forwardMergeRead(_ arr: [Int], _ aux: [Int], _ toAux: Bool, _ i: Int) -> Int {
    toAux ? arr[i] : aux[i]
}

func forwardMergeWrite(_ arr: inout [Int], _ aux: inout [Int], _ toAux: Bool, _ i: Int, _ value: Int) {
    if toAux {
        aux[i] = value
    } else {
        arr[i] = value
    }
}

func forwardMerge(
    _ arr: inout [Int], _ aux: inout [Int], _ start: Int, _ auxStart: Int, _ block: Int, _ toAux: Bool
) {
    var mergeP = toAux ? auxStart : start
    var l = toAux ? start : auxStart
    var r = toAux ? (start + block) : (auxStart + block)
    let m = r
    let e = r + block

    if forwardMergeRead(arr, aux, toAux, r - 1) <= forwardMergeRead(arr, aux, toAux, e - 1) {
        while l < m {
            if forwardMergeRead(arr, aux, toAux, l) <= forwardMergeRead(arr, aux, toAux, r) {
                forwardMergeWrite(&arr, &aux, toAux, mergeP, forwardMergeRead(arr, aux, toAux, l))
                mergeP += 1
                l += 1
            } else {
                forwardMergeWrite(&arr, &aux, toAux, mergeP, forwardMergeRead(arr, aux, toAux, r))
                mergeP += 1
                r += 1
            }
        }
        while r < e {
            forwardMergeWrite(&arr, &aux, toAux, mergeP, forwardMergeRead(arr, aux, toAux, r))
            mergeP += 1
            r += 1
        }
    } else {
        while r < e {
            if forwardMergeRead(arr, aux, toAux, l) > forwardMergeRead(arr, aux, toAux, r) {
                forwardMergeWrite(&arr, &aux, toAux, mergeP, forwardMergeRead(arr, aux, toAux, r))
                mergeP += 1
                r += 1
            } else {
                forwardMergeWrite(&arr, &aux, toAux, mergeP, forwardMergeRead(arr, aux, toAux, l))
                mergeP += 1
                l += 1
            }
        }
        while l < m {
            forwardMergeWrite(&arr, &aux, toAux, mergeP, forwardMergeRead(arr, aux, toAux, l))
            mergeP += 1
            l += 1
        }
    }
}

func quadMergeBlock(_ arr: inout [Int], _ start: Int, _ aux: inout [Int], _ block: Int) {
    let blockX2 = block * 2
    var cMax = start + block

    if arr[cMax - 1] <= arr[cMax] {
        cMax += blockX2

        if arr[cMax - 1] <= arr[cMax] {
            cMax -= block

            if arr[cMax - 1] <= arr[cMax] {
                return
            }

            var pts = 0
            var c = start
            repeat {
                aux[pts] = arr[c]
                c += 1
                pts += 1
            } while c < cMax

            cMax = c + blockX2
            repeat {
                aux[pts] = arr[c]
                c += 1
                pts += 1
            } while c < cMax

            forwardMerge(&arr, &aux, start, 0, blockX2, false)
            return
        }

        var pts = 0
        var c = start
        cMax = start + blockX2
        repeat {
            aux[pts] = arr[c]
            c += 1
            pts += 1
        } while c < cMax
    } else {
        forwardMerge(&arr, &aux, start, 0, block, true)
    }

    forwardMerge(&arr, &aux, start + blockX2, blockX2, block, true)
    forwardMerge(&arr, &aux, start, 0, blockX2, false)
}

func quadMerge(_ arr: inout [Int], _ aux: inout [Int], _ start: Int, _ nmemb: Int, _ block: Int) {
    let pte = start + nmemb
    var block = block * 4

    while block * 2 <= nmemb {
        var pta = start
        repeat {
            quadMergeBlock(&arr, pta, &aux, block / 4)
            pta += block
        } while pta + block <= pte
        tailMerge(&arr, &aux, pta, pte - pta, block / 4)
        block *= 4
    }
    tailMerge(&arr, &aux, start, nmemb, block / 4)
}

// -- Pre-sort pass --------------------------------------------------------------------------

/// Pre-sorting pass: a 4-item sorting network applied across the whole range, with a side
/// detector for strictly-decreasing runs -- reversed in place rather than merged. If the *entire*
/// range turns out strictly decreasing, one reversal finishes the sort outright (returns 1);
/// otherwise this finishes with parity-merge passes over what's left (returns 0).
func quadSwap(_ arr: inout [Int], _ start: Int, _ nmemb: Int) -> Int {
    var swapBuf = [Int](repeating: 0, count: 16)
    var pta = start
    var count = nmemb / 4
    var pts = 0

    swapper: while count > 0 {
        count -= 1

        innerA: while true {
            if arr[pta] > arr[pta + 1] {
                if arr[pta + 2] > arr[pta + 3] {
                    if arr[pta + 1] > arr[pta + 2] {
                        pts = pta
                        pta += 4
                        break innerA
                    }
                    swap2(&arr, pta + 2, pta + 3)
                }
                swap2(&arr, pta, pta + 1)
            } else if arr[pta + 2] > arr[pta + 3] {
                swap2(&arr, pta + 2, pta + 3)
            }

            if arr[pta + 1] > arr[pta + 2] {
                if arr[pta] <= arr[pta + 2] {
                    if arr[pta + 1] <= arr[pta + 3] {
                        swap2(&arr, pta + 1, pta + 2)
                    } else {
                        let temp = arr[pta + 1]
                        arr[pta + 1] = arr[pta + 2]
                        arr[pta + 2] = arr[pta + 3]
                        arr[pta + 3] = temp
                    }
                } else if arr[pta] > arr[pta + 3] {
                    swap2(&arr, pta + 1, pta + 3)
                    swap2(&arr, pta, pta + 2)
                } else if arr[pta + 1] <= arr[pta + 3] {
                    let temp = arr[pta + 1]
                    arr[pta + 1] = arr[pta]
                    arr[pta] = arr[pta + 2]
                    arr[pta + 2] = temp
                } else {
                    let temp = arr[pta + 1]
                    arr[pta + 1] = arr[pta]
                    arr[pta] = arr[pta + 2]
                    arr[pta + 2] = arr[pta + 3]
                    arr[pta + 3] = temp
                }
            }
            pta += 4
            continue swapper
        }

        innerB: while true {
            if count > 0 {
                count -= 1

                if arr[pta] > arr[pta + 1] {
                    if arr[pta + 2] > arr[pta + 3] {
                        if arr[pta + 1] > arr[pta + 2] {
                            if arr[pta - 1] > arr[pta] {
                                pta += 4
                                continue innerB
                            }
                        }
                        swap2(&arr, pta + 2, pta + 3)
                    }
                    swap2(&arr, pta, pta + 1)
                } else if arr[pta + 2] > arr[pta + 3] {
                    swap2(&arr, pta + 2, pta + 3)
                }

                if arr[pta + 1] > arr[pta + 2] {
                    if arr[pta] <= arr[pta + 2] {
                        if arr[pta + 1] <= arr[pta + 3] {
                            swap2(&arr, pta + 1, pta + 2)
                        } else {
                            let temp = arr[pta + 1]
                            arr[pta + 1] = arr[pta + 2]
                            arr[pta + 2] = arr[pta + 3]
                            arr[pta + 3] = temp
                        }
                    } else if arr[pta] > arr[pta + 3] {
                        swap2(&arr, pta, pta + 2)
                        swap2(&arr, pta + 1, pta + 3)
                    } else if arr[pta + 1] <= arr[pta + 3] {
                        let temp = arr[pta]
                        arr[pta] = arr[pta + 2]
                        arr[pta + 2] = arr[pta + 1]
                        arr[pta + 1] = temp
                    } else {
                        let temp = arr[pta]
                        arr[pta] = arr[pta + 2]
                        arr[pta + 2] = arr[pta + 3]
                        arr[pta + 3] = arr[pta + 1]
                        arr[pta + 1] = temp
                    }
                }

                reverseInclusive(&arr, pts, pta - 1)
                pta += 4
                continue swapper
            }

            if pts == start {
                var remainder = nmemb % 4
                if remainder == 3 {
                    remainder = arr[pta + 1] > arr[pta + 2] ? 2 : -1
                }
                if remainder == 2 {
                    remainder = arr[pta] > arr[pta + 1] ? 1 : -1
                }
                if remainder == 1 {
                    remainder = arr[pta - 1] > arr[pta] ? 0 : -1
                }
                if remainder == 0 {
                    reverseInclusive(&arr, pts, pts + nmemb - 1)
                    return 1
                }
            }

            reverseInclusive(&arr, pts, pta - 1)
            break swapper
        }
    }

    tailSwap(&arr, pta, nmemb % 4)

    pta = start
    count = nmemb / 16
    while count > 0 {
        count -= 1
        parityMerge16(&arr, pta, &swapBuf)
        pta += 16
    }

    if nmemb % 16 > 4 {
        tailMerge(&arr, &swapBuf, pta, nmemb % 16, 4)
    }

    return 0
}

// -- Entry point -----------------------------------------------------------------------------

/// Top-level dispatch by size: under 16 is a plain tailSwap; under 256 pre-sorts via quadSwap then
/// finishes with tailMerge; 256 and up finishes with the full quadMerge pass instead.
func sort(_ arr: inout [Int]) {
    let n = arr.count
    if n < 16 {
        tailSwap(&arr, 0, n)
    } else if n < 256 {
        if quadSwap(&arr, 0, n) == 0 {
            var buffer = [Int](repeating: 0, count: 128)
            tailMerge(&arr, &buffer, 0, n, 16)
        }
    } else {
        if quadSwap(&arr, 0, n) == 0 {
            var buffer = [Int](repeating: 0, count: n / 2)
            quadMerge(&arr, &buffer, 0, n, 16)
        }
    }
}

var array: [Int] = [
    55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79, 21, 88, 5, 51,
    66, 29, 44, 12, 90, 1, 58, 33, 71, 19, 60, 45, 27, 82, 6, 95, 38, 63, 9, 50,
]
sort(&array)
print(array)
