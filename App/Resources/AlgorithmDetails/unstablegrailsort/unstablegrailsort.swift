func swap(_ arr: inout [Int], _ a: Int, _ b: Int) {
    arr.swapAt(a, b)
}

func multiSwap(_ arr: inout [Int], _ a: Int, _ b: Int, _ count: Int) {
    for i in 0..<count { swap(&arr, a + i, b + i) }
}

func rotate(_ arr: inout [Int], _ posArg: Int, _ lenAArg: Int, _ lenBArg: Int) {
    var pos = posArg
    var lenA = lenAArg
    var lenB = lenBArg
    while lenA != 0 && lenB != 0 {
        if lenA <= lenB {
            multiSwap(&arr, pos, pos + lenA, lenA)
            pos += lenA
            lenB -= lenA
        } else {
            multiSwap(&arr, pos + (lenA - lenB), pos + lenA, lenB)
            lenA -= lenB
        }
    }
}

func insertSort(_ arr: inout [Int], _ pos: Int, _ len: Int) {
    if len < 2 { return }
    for i in 1..<len {
        var j = pos + i
        while j > pos && arr[j] < arr[j - 1] {
            swap(&arr, j, j - 1)
            j -= 1
        }
    }
}

func binSearch(_ arr: [Int], _ pos: Int, _ len: Int, _ keyPos: Int, _ isLeft: Bool) -> Int {
    var left = -1
    var right = len
    let key = arr[keyPos]
    while left < right - 1 {
        let mid = left + (right - left) / 2
        let cond = isLeft ? (arr[pos + mid] >= key) : (arr[pos + mid] > key)
        if cond { right = mid } else { left = mid }
    }
    return right
}

func mergeWithoutBuffer(_ arr: inout [Int], _ pos: Int, _ len1: Int, _ len2: Int) {
    if len1 == 0 || len2 == 0 { return }
    if len1 + len2 == 2 {
        if arr[pos] > arr[pos + 1] { swap(&arr, pos, pos + 1) }
        return
    }
    let mid1: Int
    let mid2: Int
    if len1 > len2 {
        mid1 = len1 / 2
        mid2 = binSearch(arr, pos + len1, len2, pos + mid1, true)
    } else {
        mid2 = len2 / 2
        mid1 = binSearch(arr, pos, len1, pos + len1 + mid2, false)
    }
    rotate(&arr, pos + mid1, len1 - mid1, mid2)
    mergeWithoutBuffer(&arr, pos, mid1, mid2)
    mergeWithoutBuffer(&arr, pos + mid1 + mid2, len1 - mid1, len2 - mid2)
}

func mergeLeft(_ arr: inout [Int], _ pos: Int, _ leftLen: Int, _ rightLenArg: Int, _ distArg: Int) {
    var left = 0
    var right = leftLen
    let rightLen = rightLenArg + leftLen
    var dist = distArg
    while right < rightLen {
        if left == leftLen || arr[pos + left] > arr[pos + right] {
            swap(&arr, pos + dist, pos + right); dist += 1; right += 1
        } else {
            swap(&arr, pos + dist, pos + left); dist += 1; left += 1
        }
    }
    if dist != left { multiSwap(&arr, pos + dist, pos + left, leftLen - left) }
}

func mergeRight(_ arr: inout [Int], _ pos: Int, _ leftLen: Int, _ rightLen: Int, _ dist: Int) {
    var mergedPos = leftLen + rightLen + dist - 1
    var right = leftLen + rightLen - 1
    var left = leftLen - 1
    while left >= 0 {
        if right < leftLen || arr[pos + left] > arr[pos + right] {
            swap(&arr, pos + mergedPos, pos + left); mergedPos -= 1; left -= 1
        } else {
            swap(&arr, pos + mergedPos, pos + right); mergedPos -= 1; right -= 1
        }
    }
    while right != mergedPos && right >= leftLen {
        swap(&arr, pos + mergedPos, pos + right); mergedPos -= 1; right -= 1
    }
}

func smartMergeWithBuffer(_ arr: inout [Int], _ pos: Int, _ leftOverLen: Int, _ blockLen: Int) -> Int {
    var dist = -blockLen
    var left = 0
    var right = leftOverLen
    var leftEnd = right
    var rightEnd = right + blockLen
    let length: Int
    while left < leftEnd && right < rightEnd {
        if arr[pos + left] <= arr[pos + right] {
            swap(&arr, pos + dist, pos + left); dist += 1; left += 1
        } else {
            swap(&arr, pos + dist, pos + right); dist += 1; right += 1
        }
    }
    if left < leftEnd {
        length = leftEnd - left
        while left < leftEnd {
            leftEnd -= 1; rightEnd -= 1
            swap(&arr, pos + leftEnd, pos + rightEnd)
        }
    } else {
        length = rightEnd - right
    }
    return length
}

func mergeBuffersLeft(_ arr: inout [Int], _ pos: Int, _ blockCount: Int, _ blockLen: Int, _ aBlockCount: Int, _ lastLen: Int) {
    if blockCount == 0 {
        mergeLeft(&arr, pos, aBlockCount * blockLen, lastLen, -blockLen)
        return
    }
    var leftOverLen = blockLen
    var processIndex = blockLen
    for _ in 1..<blockCount {
        let restToProcess = processIndex - leftOverLen
        leftOverLen = smartMergeWithBuffer(&arr, pos + restToProcess, leftOverLen, blockLen)
        processIndex += blockLen
    }
    let restToProcess = processIndex - leftOverLen
    if lastLen != 0 {
        leftOverLen += blockLen * aBlockCount
        mergeLeft(&arr, pos + restToProcess, leftOverLen, lastLen, -blockLen)
    } else {
        multiSwap(&arr, pos + restToProcess, pos + restToProcess - blockLen, leftOverLen)
    }
}

func buildBlocks(_ arr: inout [Int], _ posArg: Int, _ len: Int, _ buildLen: Int) {
    var pos = posArg
    var dist = 1
    while dist < len {
        let extraDist = (arr[pos + dist - 1] > arr[pos + dist]) ? 1 : 0
        swap(&arr, pos + dist - 3, pos + dist - 1 + extraDist)
        swap(&arr, pos + dist - 2, pos + dist - extraDist)
        dist += 2
    }
    if len % 2 == 1 { swap(&arr, pos + len - 1, pos + len - 3) }
    pos -= 2
    var part = 2
    while part < buildLen {
        var left = 0
        let right = len - 2 * part
        while left <= right {
            mergeLeft(&arr, pos + left, part, part, -part)
            left += 2 * part
        }
        let rest = len - left
        if rest > part {
            mergeLeft(&arr, pos + left, part, rest - part, -part)
        } else {
            rotate(&arr, pos + left - part, part, rest)
        }
        pos -= part
        part *= 2
    }
    let restToBuild = len % (2 * buildLen)
    var leftOverPos = len - restToBuild
    if restToBuild <= buildLen {
        rotate(&arr, pos + leftOverPos, restToBuild, buildLen)
    } else {
        mergeRight(&arr, pos + leftOverPos, buildLen, restToBuild - buildLen, buildLen)
    }
    while leftOverPos > 0 {
        leftOverPos -= 2 * buildLen
        mergeRight(&arr, pos + leftOverPos, buildLen, buildLen, buildLen)
    }
}

func combineBlocks(_ arr: inout [Int], _ pos: Int, _ lenArg: Int, _ buildLen: Int, _ regBlockLen: Int) {
    var len = lenArg
    let combineLen = len / (2 * buildLen)
    var leftOver = len % (2 * buildLen)
    if leftOver <= buildLen {
        len -= leftOver
        leftOver = 0
    }
    for i in 0...combineLen {
        if i == combineLen && leftOver == 0 { break }
        let blockPos = pos + i * 2 * buildLen
        let blockCount = (i == combineLen ? leftOver : 2 * buildLen) / regBlockLen
        for index in 1..<blockCount {
            var leftIndex = index - 1
            for rightIndex in index..<blockCount {
                let a = arr[blockPos + leftIndex * regBlockLen]
                let b = arr[blockPos + rightIndex * regBlockLen]
                let cmp = a > b ? 1 : (a < b ? -1 : 0)
                if cmp > 0 || (cmp == 0 && arr[blockPos + (leftIndex + 1) * regBlockLen - 1] >
                                arr[blockPos + (rightIndex + 1) * regBlockLen - 1]) {
                    leftIndex = rightIndex
                }
            }
            if leftIndex != index - 1 {
                multiSwap(&arr, blockPos + (index - 1) * regBlockLen, blockPos + leftIndex * regBlockLen, regBlockLen)
            }
        }
        var aBlockCount = 0
        let lastLen = (i == combineLen) ? (leftOver % regBlockLen) : 0
        if lastLen != 0 {
            while aBlockCount < blockCount &&
                    arr[blockPos + blockCount * regBlockLen] < arr[blockPos + (blockCount - aBlockCount - 1) * regBlockLen] {
                aBlockCount += 1
            }
        }
        mergeBuffersLeft(&arr, blockPos, blockCount - aBlockCount, regBlockLen, aBlockCount, lastLen)
    }
    while len > 0 {
        len -= 1
        swap(&arr, pos + len, pos + len - regBlockLen)
    }
}

func commonSort(_ arr: inout [Int], _ pos: Int, _ len: Int) {
    if len <= 16 {
        insertSort(&arr, pos, len)
        return
    }
    var blockLen = 1
    while blockLen * blockLen < len { blockLen *= 2 }
    var buildLen = blockLen
    buildBlocks(&arr, pos + blockLen, len - blockLen, buildLen)
    while true {
        buildLen *= 2
        if len - blockLen <= buildLen { break }
        combineBlocks(&arr, pos + blockLen, len - blockLen, buildLen, blockLen)
    }
    insertSort(&arr, pos, blockLen)
    mergeWithoutBuffer(&arr, pos, blockLen, len - blockLen)
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    commonSort(&arr, 0, n)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
