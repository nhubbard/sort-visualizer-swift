fun swap(arr: Array<Int>, a: Int, b: Int) {
  val t = arr[a]
  arr[a] = arr[b]
  arr[b] = t
}

fun compareValues(a: Int, b: Int): Int = a.compareTo(b)

fun multiSwap(arr: Array<Int>, a: Int, b: Int, count: Int) {
  for (i in 0 until count) swap(arr, a + i, b + i)
}

fun rotate(arr: Array<Int>, posArg: Int, lenAArg: Int, lenBArg: Int) {
  var pos = posArg
  var lenA = lenAArg
  var lenB = lenBArg
  while (lenA != 0 && lenB != 0) {
    if (lenA <= lenB) {
      multiSwap(arr, pos, pos + lenA, lenA)
      pos += lenA
      lenB -= lenA
    } else {
      multiSwap(arr, pos + (lenA - lenB), pos + lenA, lenB)
      lenA -= lenB
    }
  }
}

fun insertSort(arr: Array<Int>, pos: Int, len: Int) {
  for (i in 1 until len) {
    var j = pos + i
    while (j > pos && arr[j] < arr[j - 1]) {
      swap(arr, j, j - 1)
      j--
    }
  }
}

fun binSearch(arr: Array<Int>, pos: Int, len: Int, keyPos: Int, isLeft: Boolean): Int {
  var left = -1
  var right = len
  val key = arr[keyPos]
  while (left < right - 1) {
    val mid = left + (right - left) / 2
    val cond = if (isLeft) arr[pos + mid] >= key else arr[pos + mid] > key
    if (cond) right = mid else left = mid
  }
  return right
}

fun findKeys(arr: Array<Int>, pos: Int, len: Int, numKeys: Int): Int {
  var dist = 1
  var foundKeys = 1
  var firstKey = 0
  while (dist < len && foundKeys < numKeys) {
    val loc = binSearch(arr, pos + firstKey, foundKeys, pos + dist, true)
    if (loc == foundKeys || arr[pos + dist] != arr[pos + firstKey + loc]) {
      rotate(arr, pos + firstKey, foundKeys, dist - (firstKey + foundKeys))
      firstKey = dist - foundKeys
      rotate(arr, pos + (firstKey + loc), foundKeys - loc, 1)
      foundKeys++
    }
    dist++
  }
  rotate(arr, pos, firstKey, foundKeys)
  return foundKeys
}

fun mergeWithoutBuffer(arr: Array<Int>, posArg: Int, len1Arg: Int, len2Arg: Int) {
  var pos = posArg
  var len1 = len1Arg
  var len2 = len2Arg
  if (len1 == 0 || len2 == 0) return
  if (len1 < len2) {
    while (len1 != 0) {
      val loc = binSearch(arr, pos + len1, len2, pos, true)
      if (loc != 0) {
        rotate(arr, pos, len1, loc)
        pos += loc
        len2 -= loc
      }
      if (len2 == 0) break
      do {
        pos++
        len1--
      } while (len1 != 0 && arr[pos] <= arr[pos + len1])
    }
  } else {
    while (len2 != 0) {
      val loc = binSearch(arr, pos, len1, pos + len1 + len2 - 1, false)
      if (loc != len1) {
        rotate(arr, pos + loc, len1 - loc, len2)
        len1 = loc
      }
      if (len1 == 0) break
      do {
        len2--
      } while (len2 != 0 && arr[pos + len1 - 1] <= arr[pos + len1 + len2 - 1])
    }
  }
}

fun mergeLeft(arr: Array<Int>, pos: Int, leftLen: Int, rightLenArg: Int, distArg: Int) {
  var left = 0
  var right = leftLen
  var rightLen = rightLenArg + leftLen
  var dist = distArg
  while (right < rightLen) {
    if (left == leftLen || arr[pos + left] > arr[pos + right]) {
      swap(arr, pos + dist, pos + right); dist++; right++
    } else {
      swap(arr, pos + dist, pos + left); dist++; left++
    }
  }
  if (dist != left) multiSwap(arr, pos + dist, pos + left, leftLen - left)
}

fun mergeRight(arr: Array<Int>, pos: Int, leftLen: Int, rightLen: Int, dist: Int) {
  var mergedPos = leftLen + rightLen + dist - 1
  var right = leftLen + rightLen - 1
  var left = leftLen - 1
  while (left >= 0) {
    if (right < leftLen || arr[pos + left] > arr[pos + right]) {
      swap(arr, pos + mergedPos, pos + left); mergedPos--; left--
    } else {
      swap(arr, pos + mergedPos, pos + right); mergedPos--; right--
    }
  }
  while (right != mergedPos && right >= leftLen) {
    swap(arr, pos + mergedPos, pos + right); mergedPos--; right--
  }
}

fun smartMergeWithoutBuffer(arr: Array<Int>, posArg: Int, leftOverLen: Int, leftOverFrag: Int, regBlockLen: Int): Pair<Int, Int> {
  if (regBlockLen == 0) return Pair(leftOverLen, leftOverFrag)
  var pos = posArg
  var len1 = leftOverLen
  var len2 = regBlockLen
  val typeFrag = 1 - leftOverFrag
  if (len1 != 0 && (compareValues(arr[pos + len1 - 1], arr[pos + len1]) - typeFrag) >= 0) {
    while (len1 != 0) {
      val foundLen = binSearch(arr, pos + len1, len2, pos, typeFrag != 0)
      if (foundLen != 0) {
        rotate(arr, pos, len1, foundLen)
        pos += foundLen
        len2 -= foundLen
      }
      if (len2 == 0) return Pair(len1, leftOverFrag)
      do {
        pos++
        len1--
      } while (len1 != 0 && (compareValues(arr[pos], arr[pos + len1]) - typeFrag) < 0)
    }
  }
  return Pair(len2, typeFrag)
}

fun smartMergeWithBuffer(arr: Array<Int>, pos: Int, leftOverLen: Int, leftOverFrag: Int, blockLen: Int): Pair<Int, Int> {
  var dist = -blockLen
  var left = 0
  var right = leftOverLen
  var leftEnd = right
  var rightEnd = right + blockLen
  val typeFrag = 1 - leftOverFrag
  while (left < leftEnd && right < rightEnd) {
    if ((compareValues(arr[pos + left], arr[pos + right]) - typeFrag) < 0) {
      swap(arr, pos + dist, pos + left); dist++; left++
    } else {
      swap(arr, pos + dist, pos + right); dist++; right++
    }
  }
  val length: Int
  var fragment = leftOverFrag
  if (left < leftEnd) {
    length = leftEnd - left
    while (left < leftEnd) {
      leftEnd--; rightEnd--
      swap(arr, pos + leftEnd, pos + rightEnd)
    }
  } else {
    length = rightEnd - right
    fragment = typeFrag
  }
  return Pair(length, fragment)
}

fun mergeBuffersLeft(
  arr: Array<Int>, keysPos: Int, midkey: Int, pos: Int, blockCount: Int, blockLen: Int,
  havebuf: Boolean, aBlockCount: Int, lastLen: Int
) {
  if (blockCount == 0) {
    val aBlocksLen = aBlockCount * blockLen
    if (havebuf) mergeLeft(arr, pos, aBlocksLen, lastLen, -blockLen)
    else mergeWithoutBuffer(arr, pos, aBlocksLen, lastLen)
    return
  }
  var leftOverLen = blockLen
  var leftOverFrag = if (arr[keysPos] < arr[midkey]) 0 else 1
  var processIndex = blockLen
  for (keyIndex in 1 until blockCount) {
    var restToProcess = processIndex - leftOverLen
    val nextFrag = if (arr[keysPos + keyIndex] < arr[midkey]) 0 else 1
    if (nextFrag == leftOverFrag) {
      if (havebuf) multiSwap(arr, pos + restToProcess - blockLen, pos + restToProcess, leftOverLen)
      restToProcess = processIndex
      leftOverLen = blockLen
    } else {
      val result = if (havebuf) smartMergeWithBuffer(arr, pos + restToProcess, leftOverLen, leftOverFrag, blockLen)
      else smartMergeWithoutBuffer(arr, pos + restToProcess, leftOverLen, leftOverFrag, blockLen)
      leftOverLen = result.first
      leftOverFrag = result.second
    }
    processIndex += blockLen
  }
  var restToProcess = processIndex - leftOverLen
  if (lastLen != 0) {
    if (leftOverFrag != 0) {
      if (havebuf) multiSwap(arr, pos + restToProcess - blockLen, pos + restToProcess, leftOverLen)
      restToProcess = processIndex
      leftOverLen = blockLen * aBlockCount
      leftOverFrag = 0
    } else {
      leftOverLen += blockLen * aBlockCount
    }
    if (havebuf) mergeLeft(arr, pos + restToProcess, leftOverLen, lastLen, -blockLen)
    else mergeWithoutBuffer(arr, pos + restToProcess, leftOverLen, lastLen)
  } else {
    if (havebuf) multiSwap(arr, pos + restToProcess, pos + restToProcess - blockLen, leftOverLen)
  }
}

fun buildBlocks(arr: Array<Int>, posArg: Int, len: Int, buildLen: Int) {
  var pos = posArg
  var dist = 1
  while (dist < len) {
    val extraDist = if (arr[pos + dist - 1] > arr[pos + dist]) 1 else 0
    swap(arr, pos + dist - 3, pos + dist - 1 + extraDist)
    swap(arr, pos + dist - 2, pos + dist - extraDist)
    dist += 2
  }
  if (len % 2 == 1) swap(arr, pos + len - 1, pos + len - 3)
  pos -= 2
  var part = 2
  while (part < buildLen) {
    var left = 0
    val right = len - 2 * part
    while (left <= right) {
      mergeLeft(arr, pos + left, part, part, -part)
      left += 2 * part
    }
    val rest = len - left
    if (rest > part) mergeLeft(arr, pos + left, part, rest - part, -part)
    else rotate(arr, pos + left - part, part, rest)
    pos -= part
    part *= 2
  }
  val restToBuild = len % (2 * buildLen)
  var leftOverPos = len - restToBuild
  if (restToBuild <= buildLen) rotate(arr, pos + leftOverPos, restToBuild, buildLen)
  else mergeRight(arr, pos + leftOverPos, buildLen, restToBuild - buildLen, buildLen)
  while (leftOverPos > 0) {
    leftOverPos -= 2 * buildLen
    mergeRight(arr, pos + leftOverPos, buildLen, buildLen, buildLen)
  }
}

fun combineBlocks(arr: Array<Int>, keyPos: Int, pos: Int, lenArg: Int, buildLen: Int, regBlockLen: Int, havebuf: Boolean) {
  var len = lenArg
  val combineLen = len / (2 * buildLen)
  var leftOver = len % (2 * buildLen)
  if (leftOver <= buildLen) {
    len -= leftOver
    leftOver = 0
  }
  for (i in 0..combineLen) {
    if (i == combineLen && leftOver == 0) break
    val blockPos = pos + i * 2 * buildLen
    val blockCount = (if (i == combineLen) leftOver else 2 * buildLen) / regBlockLen
    insertSort(arr, keyPos, blockCount + (if (i == combineLen) 1 else 0))
    var midkey = buildLen / regBlockLen
    for (index in 1 until blockCount) {
      var leftIndex = index - 1
      for (rightIndex in index until blockCount) {
        val a = arr[blockPos + leftIndex * regBlockLen]
        val b = arr[blockPos + rightIndex * regBlockLen]
        if (a > b || (a == b && arr[keyPos + leftIndex] > arr[keyPos + rightIndex])) {
          leftIndex = rightIndex
        }
      }
      if (leftIndex != index - 1) {
        multiSwap(arr, blockPos + (index - 1) * regBlockLen, blockPos + leftIndex * regBlockLen, regBlockLen)
        swap(arr, keyPos + (index - 1), keyPos + leftIndex)
        if (midkey == index - 1 || midkey == leftIndex) {
          midkey = midkey xor (index - 1) xor leftIndex
        }
      }
    }
    var aBlockCount = 0
    val lastLen = if (i == combineLen) (leftOver % regBlockLen) else 0
    if (lastLen != 0) {
      while (aBlockCount < blockCount &&
        arr[blockPos + blockCount * regBlockLen] < arr[blockPos + (blockCount - aBlockCount - 1) * regBlockLen]
      ) {
        aBlockCount++
      }
    }
    mergeBuffersLeft(arr, keyPos, keyPos + midkey, blockPos, blockCount - aBlockCount, regBlockLen, havebuf, aBlockCount, lastLen)
  }
  if (havebuf) {
    while (len > 0) {
      len--
      swap(arr, pos + len, pos + len - regBlockLen)
    }
  }
}

fun lazyStableSort(arr: Array<Int>, pos: Int, len: Int) {
  for (dist in 1 until len step 2) {
    if (arr[pos + dist - 1] > arr[pos + dist]) swap(arr, pos + dist - 1, pos + dist)
  }
  var part = 2
  while (part < len) {
    var left = 0
    val right = len - 2 * part
    while (left <= right) {
      mergeWithoutBuffer(arr, pos + left, part, part)
      left += 2 * part
    }
    val rest = len - left
    if (rest > part) mergeWithoutBuffer(arr, pos + left, part, rest - part)
    part *= 2
  }
}

fun commonSort(arr: Array<Int>, pos: Int, len: Int) {
  if (len <= 16) {
    insertSort(arr, pos, len)
    return
  }
  var blockLen = 1
  while (blockLen * blockLen < len) blockLen *= 2
  var numKeys = (len - 1) / blockLen + 1
  val keysFound = findKeys(arr, pos, len, numKeys + blockLen)
  var bufferEnabled = true
  if (keysFound < numKeys + blockLen) {
    if (keysFound < 4) {
      lazyStableSort(arr, pos, len)
      return
    }
    numKeys = blockLen
    while (numKeys > keysFound) numKeys /= 2
    bufferEnabled = false
    blockLen = 0
  }
  val dist = blockLen + numKeys
  var buildLen = if (bufferEnabled) blockLen else numKeys
  buildBlocks(arr, pos + dist, len - dist, buildLen)
  while (true) {
    buildLen *= 2
    if (len - dist <= buildLen) break
    var regBlockLen = blockLen
    var buildBufEnabled = bufferEnabled
    if (!bufferEnabled) {
      if (numKeys > 4 && (numKeys / 8) * numKeys >= buildLen) {
        regBlockLen = numKeys / 2
        buildBufEnabled = true
      } else {
        var calcKeys = 1
        var i = buildLen * keysFound / 2
        while (calcKeys < numKeys && i != 0) {
          calcKeys *= 2
          i /= 8
        }
        regBlockLen = (2 * buildLen) / calcKeys
      }
    }
    combineBlocks(arr, pos, pos + dist, len - dist, buildLen, regBlockLen, buildBufEnabled)
  }
  insertSort(arr, pos, dist)
  mergeWithoutBuffer(arr, pos, dist, len - dist)
}

fun sort(arr: Array<Int>) {
  commonSort(arr, 0, arr.size)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
