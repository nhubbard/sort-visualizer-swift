func swap(_ arr: inout [Int], _ a: Int, _ b: Int) {
    arr.swapAt(a, b)
}

func compareValues(_ a: Int, _ b: Int) -> Int {
    return a > b ? 1 : (a < b ? -1 : 0)
}

func multiSwap(_ arr: inout [Int], _ a: Int, _ b: Int, _ count: Int) {
    for i in 0 ..< count {
        swap(&arr, a + i, b + i)
    }
}

func rotate(_ arr: inout [Int], _ posArg: Int, _ lenAArg: Int, _ lenBArg: Int) {
    var pos = posArg
    var lenA = lenAArg
    var lenB = lenBArg
    while lenA != 0, lenB != 0 {
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
    if len < 2 {
        return
    }
    for i in 1 ..< len {
        var j = pos + i
        while j > pos, arr[j] < arr[j - 1] {
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
        if cond {
            right = mid
        } else {
            left = mid
        }
    }
    return right
}

func findKeys(_ arr: inout [Int], _ pos: Int, _ len: Int, _ numKeys: Int) -> Int {
    var dist = 1
    var foundKeys = 1
    var firstKey = 0
    while dist < len && foundKeys < numKeys {
        let loc = binSearch(arr, pos + firstKey, foundKeys, pos + dist, true)
        if loc == foundKeys || arr[pos + dist] != arr[pos + firstKey + loc] {
            rotate(&arr, pos + firstKey, foundKeys, dist - (firstKey + foundKeys))
            firstKey = dist - foundKeys
            rotate(&arr, pos + (firstKey + loc), foundKeys - loc, 1)
            foundKeys += 1
        }
        dist += 1
    }
    rotate(&arr, pos, firstKey, foundKeys)
    return foundKeys
}

func mergeWithoutBuffer(_ arr: inout [Int], _ posArg: Int, _ len1Arg: Int, _ len2Arg: Int) {
    var pos = posArg
    var len1 = len1Arg
    var len2 = len2Arg
    if len1 == 0 || len2 == 0 {
        return
    }
    if len1 < len2 {
        while len1 != 0 {
            let loc = binSearch(arr, pos + len1, len2, pos, true)
            if loc != 0 {
                rotate(&arr, pos, len1, loc)
                pos += loc
                len2 -= loc
            }
            if len2 == 0 {
                break
            }
            repeat {
                pos += 1
                len1 -= 1
            } while len1 != 0 && arr[pos] <= arr[pos + len1]
        }
    } else {
        while len2 != 0 {
            let loc = binSearch(arr, pos, len1, pos + len1 + len2 - 1, false)
            if loc != len1 {
                rotate(&arr, pos + loc, len1 - loc, len2)
                len1 = loc
            }
            if len1 == 0 {
                break
            }
            repeat {
                len2 -= 1
            } while len2 != 0 && arr[pos + len1 - 1] <= arr[pos + len1 + len2 - 1]
        }
    }
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
    if dist != left {
        multiSwap(&arr, pos + dist, pos + left, leftLen - left)
    }
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
    while right != mergedPos, right >= leftLen {
        swap(&arr, pos + mergedPos, pos + right); mergedPos -= 1; right -= 1
    }
}

func smartMergeWithoutBuffer(_ arr: inout [Int], _ posArg: Int, _ leftOverLen: Int, _ leftOverFrag: Int, _ regBlockLen: Int) -> (Int, Int) {
    if regBlockLen == 0 {
        return (leftOverLen, leftOverFrag)
    }
    var pos = posArg
    var len1 = leftOverLen
    var len2 = regBlockLen
    let typeFrag = 1 - leftOverFrag
    if len1 != 0, (compareValues(arr[pos + len1 - 1], arr[pos + len1]) - typeFrag) >= 0 {
        while len1 != 0 {
            let foundLen = binSearch(arr, pos + len1, len2, pos, typeFrag != 0)
            if foundLen != 0 {
                rotate(&arr, pos, len1, foundLen)
                pos += foundLen
                len2 -= foundLen
            }
            if len2 == 0 {
                return (len1, leftOverFrag)
            }
            repeat {
                pos += 1
                len1 -= 1
            } while len1 != 0 && (compareValues(arr[pos], arr[pos + len1]) - typeFrag) < 0
        }
    }
    return (len2, typeFrag)
}

func smartMergeWithBuffer(_ arr: inout [Int], _ pos: Int, _ leftOverLen: Int, _ leftOverFrag: Int, _ blockLen: Int) -> (Int, Int) {
    var dist = -blockLen
    var left = 0
    var right = leftOverLen
    var leftEnd = right
    var rightEnd = right + blockLen
    let typeFrag = 1 - leftOverFrag
    while left < leftEnd, right < rightEnd {
        if (compareValues(arr[pos + left], arr[pos + right]) - typeFrag) < 0 {
            swap(&arr, pos + dist, pos + left); dist += 1; left += 1
        } else {
            swap(&arr, pos + dist, pos + right); dist += 1; right += 1
        }
    }
    let length: Int
    var fragment = leftOverFrag
    if left < leftEnd {
        length = leftEnd - left
        while left < leftEnd {
            leftEnd -= 1; rightEnd -= 1
            swap(&arr, pos + leftEnd, pos + rightEnd)
        }
    } else {
        length = rightEnd - right
        fragment = typeFrag
    }
    return (length, fragment)
}

func mergeBuffersLeft(
    _ arr: inout [Int], _ keysPos: Int, _ midkey: Int, _ pos: Int, _ blockCount: Int, _ blockLen: Int,
    _ havebuf: Bool, _ aBlockCount: Int, _ lastLen: Int
) {
    if blockCount == 0 {
        let aBlocksLen = aBlockCount * blockLen
        if havebuf {
            mergeLeft(&arr, pos, aBlocksLen, lastLen, -blockLen)
        } else {
            mergeWithoutBuffer(&arr, pos, aBlocksLen, lastLen)
        }
        return
    }
    var leftOverLen = blockLen
    var leftOverFrag = (arr[keysPos] < arr[midkey]) ? 0 : 1
    var processIndex = blockLen
    for keyIndex in 1 ..< blockCount {
        var restToProcess = processIndex - leftOverLen
        let nextFrag = (arr[keysPos + keyIndex] < arr[midkey]) ? 0 : 1
        if nextFrag == leftOverFrag {
            if havebuf {
                multiSwap(&arr, pos + restToProcess - blockLen, pos + restToProcess, leftOverLen)
            }
            restToProcess = processIndex
            leftOverLen = blockLen
        } else {
            let result = havebuf
                ? smartMergeWithBuffer(&arr, pos + restToProcess, leftOverLen, leftOverFrag, blockLen)
                : smartMergeWithoutBuffer(&arr, pos + restToProcess, leftOverLen, leftOverFrag, blockLen)
            leftOverLen = result.0
            leftOverFrag = result.1
        }
        processIndex += blockLen
        _ = restToProcess
    }
    var restToProcess = processIndex - leftOverLen
    if lastLen != 0 {
        if leftOverFrag != 0 {
            if havebuf {
                multiSwap(&arr, pos + restToProcess - blockLen, pos + restToProcess, leftOverLen)
            }
            restToProcess = processIndex
            leftOverLen = blockLen * aBlockCount
            leftOverFrag = 0
        } else {
            leftOverLen += blockLen * aBlockCount
        }
        if havebuf {
            mergeLeft(&arr, pos + restToProcess, leftOverLen, lastLen, -blockLen)
        } else {
            mergeWithoutBuffer(&arr, pos + restToProcess, leftOverLen, lastLen)
        }
    } else {
        if havebuf {
            multiSwap(&arr, pos + restToProcess, pos + restToProcess - blockLen, leftOverLen)
        }
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
    if len % 2 == 1 {
        swap(&arr, pos + len - 1, pos + len - 3)
    }
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

func combineBlocks(_ arr: inout [Int], _ keyPos: Int, _ pos: Int, _ lenArg: Int, _ buildLen: Int, _ regBlockLen: Int, _ havebuf: Bool) {
    var len = lenArg
    let combineLen = len / (2 * buildLen)
    var leftOver = len % (2 * buildLen)
    if leftOver <= buildLen {
        len -= leftOver
        leftOver = 0
    }
    for i in 0 ... combineLen {
        if i == combineLen && leftOver == 0 {
            break
        }
        let blockPos = pos + i * 2 * buildLen
        let blockCount = (i == combineLen ? leftOver : 2 * buildLen) / regBlockLen
        insertSort(&arr, keyPos, blockCount + (i == combineLen ? 1 : 0))
        var midkey = buildLen / regBlockLen
        for index in 1 ..< blockCount {
            var leftIndex = index - 1
            for rightIndex in index ..< blockCount {
                let a = arr[blockPos + leftIndex * regBlockLen]
                let b = arr[blockPos + rightIndex * regBlockLen]
                if a > b || (a == b && arr[keyPos + leftIndex] > arr[keyPos + rightIndex]) {
                    leftIndex = rightIndex
                }
            }
            if leftIndex != index - 1 {
                multiSwap(&arr, blockPos + (index - 1) * regBlockLen, blockPos + leftIndex * regBlockLen, regBlockLen)
                swap(&arr, keyPos + (index - 1), keyPos + leftIndex)
                if midkey == index - 1 || midkey == leftIndex {
                    midkey ^= (index - 1) ^ leftIndex
                }
            }
        }
        var aBlockCount = 0
        let lastLen = (i == combineLen) ? (leftOver % regBlockLen) : 0
        if lastLen != 0 {
            while aBlockCount < blockCount,
                  arr[blockPos + blockCount * regBlockLen] < arr[blockPos + (blockCount - aBlockCount - 1) * regBlockLen]
            {
                aBlockCount += 1
            }
        }
        mergeBuffersLeft(&arr, keyPos, keyPos + midkey, blockPos, blockCount - aBlockCount, regBlockLen, havebuf, aBlockCount, lastLen)
    }
    if havebuf {
        while len > 0 {
            len -= 1
            swap(&arr, pos + len, pos + len - regBlockLen)
        }
    }
}

func lazyStableSort(_ arr: inout [Int], _ pos: Int, _ len: Int) {
    var dist = 1
    while dist < len {
        if arr[pos + dist - 1] > arr[pos + dist] {
            swap(&arr, pos + dist - 1, pos + dist)
        }
        dist += 2
    }
    var part = 2
    while part < len {
        var left = 0
        let right = len - 2 * part
        while left <= right {
            mergeWithoutBuffer(&arr, pos + left, part, part)
            left += 2 * part
        }
        let rest = len - left
        if rest > part {
            mergeWithoutBuffer(&arr, pos + left, part, rest - part)
        }
        part *= 2
    }
}

func commonSort(_ arr: inout [Int], _ pos: Int, _ len: Int) {
    if len <= 16 {
        insertSort(&arr, pos, len)
        return
    }
    var blockLen = 1
    while blockLen * blockLen < len {
        blockLen *= 2
    }
    var numKeys = (len - 1) / blockLen + 1
    let keysFound = findKeys(&arr, pos, len, numKeys + blockLen)
    var bufferEnabled = true
    if keysFound < numKeys + blockLen {
        if keysFound < 4 {
            lazyStableSort(&arr, pos, len)
            return
        }
        numKeys = blockLen
        while numKeys > keysFound {
            numKeys /= 2
        }
        bufferEnabled = false
        blockLen = 0
    }
    let dist = blockLen + numKeys
    var buildLen = bufferEnabled ? blockLen : numKeys
    buildBlocks(&arr, pos + dist, len - dist, buildLen)
    while true {
        buildLen *= 2
        if len - dist <= buildLen {
            break
        }
        var regBlockLen = blockLen
        var buildBufEnabled = bufferEnabled
        if !bufferEnabled {
            if numKeys > 4, (numKeys / 8) * numKeys >= buildLen {
                regBlockLen = numKeys / 2
                buildBufEnabled = true
            } else {
                var calcKeys = 1
                var i = buildLen * keysFound / 2
                while calcKeys < numKeys, i != 0 {
                    calcKeys *= 2
                    i /= 8
                }
                regBlockLen = (2 * buildLen) / calcKeys
            }
        }
        combineBlocks(&arr, pos, pos + dist, len - dist, buildLen, regBlockLen, buildBufEnabled)
    }
    insertSort(&arr, pos, dist)
    mergeWithoutBuffer(&arr, pos, dist, len - dist)
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
