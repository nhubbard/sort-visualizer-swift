fun swap(arr: Array<Int>, a: Int, b: Int) {
  val t = arr[a]
  arr[a] = arr[b]
  arr[b] = t
}

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

fun mergeWithoutBuffer(arr: Array<Int>, pos: Int, len1: Int, len2: Int) {
  if (len1 == 0 || len2 == 0) return
  if (len1 + len2 == 2) {
    if (arr[pos] > arr[pos + 1]) swap(arr, pos, pos + 1)
    return
  }
  val mid1: Int
  val mid2: Int
  if (len1 > len2) {
    mid1 = len1 / 2
    mid2 = binSearch(arr, pos + len1, len2, pos + mid1, true)
  } else {
    mid2 = len2 / 2
    mid1 = binSearch(arr, pos, len1, pos + len1 + mid2, false)
  }
  rotate(arr, pos + mid1, len1 - mid1, mid2)
  mergeWithoutBuffer(arr, pos, mid1, mid2)
  mergeWithoutBuffer(arr, pos + mid1 + mid2, len1 - mid1, len2 - mid2)
}

fun mergeLeft(arr: Array<Int>, pos: Int, leftLen: Int, rightLenArg: Int, distArg: Int) {
  var left = 0
  var right = leftLen
  var rightLen = rightLenArg + leftLen
  var dist = distArg
  while (right < rightLen) {
    if (left == leftLen || arr[pos + left] > arr[pos + right]) {
      swap(arr, pos + dist, pos + right)
      dist++
      right++
    } else {
      swap(arr, pos + dist, pos + left)
      dist++
      left++
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
      swap(arr, pos + mergedPos, pos + left)
      mergedPos--
      left--
    } else {
      swap(arr, pos + mergedPos, pos + right)
      mergedPos--
      right--
    }
  }
  while (right != mergedPos && right >= leftLen) {
    swap(arr, pos + mergedPos, pos + right)
    mergedPos--
    right--
  }
}

fun smartMergeWithBuffer(arr: Array<Int>, pos: Int, leftOverLen: Int, blockLen: Int): Int {
  var dist = -blockLen
  var left = 0
  var right = leftOverLen
  var leftEnd = right
  var rightEnd = right + blockLen
  val length: Int
  while (left < leftEnd && right < rightEnd) {
    if (arr[pos + left] <= arr[pos + right]) {
      swap(arr, pos + dist, pos + left)
      dist++
      left++
    } else {
      swap(arr, pos + dist, pos + right)
      dist++
      right++
    }
  }
  if (left < leftEnd) {
    length = leftEnd - left
    while (left < leftEnd) {
      leftEnd--
      rightEnd--
      swap(arr, pos + leftEnd, pos + rightEnd)
    }
  } else {
    length = rightEnd - right
  }
  return length
}

fun mergeBuffersLeft(arr: Array<Int>, pos: Int, blockCount: Int, blockLen: Int, aBlockCount: Int, lastLen: Int) {
  if (blockCount == 0) {
    mergeLeft(arr, pos, aBlockCount * blockLen, lastLen, -blockLen)
    return
  }
  var leftOverLen = blockLen
  var processIndex = blockLen
  for (keyIndex in 1 until blockCount) {
    val restToProcess = processIndex - leftOverLen
    leftOverLen = smartMergeWithBuffer(arr, pos + restToProcess, leftOverLen, blockLen)
    processIndex += blockLen
  }
  val restToProcess = processIndex - leftOverLen
  if (lastLen != 0) {
    leftOverLen += blockLen * aBlockCount
    mergeLeft(arr, pos + restToProcess, leftOverLen, lastLen, -blockLen)
  } else {
    multiSwap(arr, pos + restToProcess, pos + restToProcess - blockLen, leftOverLen)
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

fun combineBlocks(arr: Array<Int>, pos: Int, lenArg: Int, buildLen: Int, regBlockLen: Int) {
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
    for (index in 1 until blockCount) {
      var leftIndex = index - 1
      for (rightIndex in index until blockCount) {
        val a = arr[blockPos + leftIndex * regBlockLen]
        val b = arr[blockPos + rightIndex * regBlockLen]
        val cmp = a.compareTo(b)
        if (cmp > 0 || (
            cmp == 0 && arr[blockPos + (leftIndex + 1) * regBlockLen - 1] >
              arr[blockPos + (rightIndex + 1) * regBlockLen - 1]
          )
        ) {
          leftIndex = rightIndex
        }
      }
      if (leftIndex != index - 1) {
        multiSwap(arr, blockPos + (index - 1) * regBlockLen, blockPos + leftIndex * regBlockLen, regBlockLen)
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
    mergeBuffersLeft(arr, blockPos, blockCount - aBlockCount, regBlockLen, aBlockCount, lastLen)
  }
  while (len > 0) {
    len--
    swap(arr, pos + len, pos + len - regBlockLen)
  }
}

fun commonSort(arr: Array<Int>, pos: Int, len: Int) {
  if (len <= 16) {
    insertSort(arr, pos, len)
    return
  }
  var blockLen = 1
  while (blockLen * blockLen < len) blockLen *= 2
  var buildLen = blockLen
  buildBlocks(arr, pos + blockLen, len - blockLen, buildLen)
  while (true) {
    buildLen *= 2
    if (len - blockLen <= buildLen) break
    combineBlocks(arr, pos + blockLen, len - blockLen, buildLen, blockLen)
  }
  insertSort(arr, pos, blockLen)
  mergeWithoutBuffer(arr, pos, blockLen, len - blockLen)
}

fun sort(arr: Array<Int>) {
  commonSort(arr, 0, arr.size)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
