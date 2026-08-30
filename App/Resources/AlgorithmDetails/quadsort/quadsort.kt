fun swap2(arr: Array<Int>, i: Int, j: Int) {
  val t = arr[i]
  arr[i] = arr[j]
  arr[j] = t
}

fun reverseInclusive(arr: Array<Int>, loIn: Int, hiIn: Int) {
  var lo = loIn
  var hi = hiIn
  while (lo < hi) {
    swap2(arr, lo, hi)
    lo++
    hi--
  }
}

// -- Fixed-size sorting networks ----------------------------------------------------------------

fun swapTwo(arr: Array<Int>, start: Int) {
  if (arr[start] > arr[start + 1]) {
    swap2(arr, start, start + 1)
  }
}

fun swapThree(arr: Array<Int>, start: Int) {
  if (arr[start] > arr[start + 1]) {
    if (arr[start] <= arr[start + 2]) {
      swap2(arr, start, start + 1)
    } else if (arr[start + 1] > arr[start + 2]) {
      swap2(arr, start, start + 2)
    } else {
      val temp = arr[start]
      arr[start] = arr[start + 1]
      arr[start + 1] = arr[start + 2]
      arr[start + 2] = temp
    }
  } else if (arr[start + 1] > arr[start + 2]) {
    if (arr[start] > arr[start + 2]) {
      val temp = arr[start + 2]
      arr[start + 2] = arr[start + 1]
      arr[start + 1] = arr[start]
      arr[start] = temp
    } else {
      swap2(arr, start + 2, start + 1)
    }
  }
}

fun swapFour(arr: Array<Int>, start: Int) {
  if (arr[start] > arr[start + 1]) {
    swap2(arr, start, start + 1)
  }
  if (arr[start + 2] > arr[start + 3]) {
    swap2(arr, start + 2, start + 3)
  }
  if (arr[start + 1] > arr[start + 2]) {
    if (arr[start] <= arr[start + 2]) {
      if (arr[start + 1] <= arr[start + 3]) {
        swap2(arr, start + 1, start + 2)
      } else {
        val temp = arr[start + 1]
        arr[start + 1] = arr[start + 2]
        arr[start + 2] = arr[start + 3]
        arr[start + 3] = temp
      }
    } else if (arr[start] > arr[start + 3]) {
      swap2(arr, start + 1, start + 3)
      swap2(arr, start, start + 2)
    } else if (arr[start + 1] <= arr[start + 3]) {
      val temp = arr[start + 1]
      arr[start + 1] = arr[start]
      arr[start] = arr[start + 2]
      arr[start + 2] = temp
    } else {
      val temp = arr[start + 1]
      arr[start + 1] = arr[start]
      arr[start] = arr[start + 2]
      arr[start + 2] = arr[start + 3]
      arr[start + 3] = temp
    }
  }
}

// `end` is a length-1 array used as an out-parameter, matching the original's `inout Int`.
fun swapFive(arr: Array<Int>, start: Int, end: IntArray) {
  end[0] = start + 4
  var pta = end[0]
  end[0] += 1
  var ptt = pta
  pta -= 1

  if (arr[pta] > arr[ptt]) {
    val key = arr[ptt]
    arr[ptt] = arr[pta]
    ptt -= 1
    pta -= 1

    if (pta > start && arr[pta - 1] > key) {
      arr[ptt] = arr[pta]
      ptt -= 1
      pta -= 1
      arr[ptt] = arr[pta]
      ptt -= 1
      pta -= 1
    }

    if (pta >= start && arr[pta] > key) {
      arr[ptt] = arr[pta]
      ptt -= 1
      pta -= 1
    }

    arr[ptt] = key
  }
}

fun tailSwapEight(arr: Array<Int>, start: Int, end: IntArray) {
  var pta = end[0]
  end[0] += 1
  var ptt = pta
  pta -= 1

  if (arr[pta] > arr[ptt]) {
    val key = arr[ptt]
    arr[ptt] = arr[pta]
    ptt -= 1
    pta -= 1

    if (arr[pta - 2] > key) {
      for (i in 0 until 3) {
        arr[ptt] = arr[pta]
        ptt -= 1
        pta -= 1
      }
    }

    if (pta > start && arr[pta - 1] > key) {
      arr[ptt] = arr[pta]
      ptt -= 1
      pta -= 1
      arr[ptt] = arr[pta]
      ptt -= 1
      pta -= 1
    }

    if (pta >= start && arr[pta] > key) {
      arr[ptt] = arr[pta]
      ptt -= 1
      pta -= 1
    }

    arr[ptt] = key
  }
}

fun swapSix(arr: Array<Int>, start: Int, end: IntArray) {
  swapFive(arr, start, end)
  tailSwapEight(arr, start, end)
}

fun swapSeven(arr: Array<Int>, start: Int, end: IntArray) {
  swapSix(arr, start, end)
  tailSwapEight(arr, start, end)
}

fun swapEight(arr: Array<Int>, start: Int, end: IntArray) {
  swapSeven(arr, start, end)
  tailSwapEight(arr, start, end)
}

// ~4 items: one of the fixed sorting networks above. 5+: an unguarded insertion sort --
// swapFive/Six/Seven/Eight handle the first 5-8 elements by hand, then a binary-search insertion
// (the `while (top > 1)` loop) places everything past index 8.
fun tailSwap(arr: Array<Int>, start: Int, nmemb: Int) {
  val end = intArrayOf(0)
  when (nmemb) {
    0, 1 -> {
      return
    }

    2 -> {
      swapTwo(arr, start)
      return
    }

    3 -> {
      swapThree(arr, start)
      return
    }

    4 -> {
      swapFour(arr, start)
      return
    }

    5 -> {
      swapFour(arr, start)
      swapFive(arr, start, end)
      return
    }

    6 -> {
      swapFour(arr, start)
      swapSix(arr, start, end)
      return
    }

    7 -> {
      swapFour(arr, start)
      swapSeven(arr, start, end)
      return
    }

    8 -> {
      swapFour(arr, start)
      swapEight(arr, start, end)
      return
    }
  }

  swapFour(arr, start)
  swapEight(arr, start, end)
  end[0] = start + 8
  var offset = 8

  while (offset < nmemb) {
    var top = offset
    offset += 1
    var pta = end[0]
    end[0] += 1
    val ptt = pta
    pta -= 1

    if (arr[pta] <= arr[ptt]) {
      continue
    }

    val temp = arr[ptt]
    while (top > 1) {
      val mid = top / 2
      if (arr[pta - mid] > temp) {
        pta -= mid
      }
      top -= mid
    }

    var i = ptt
    while (i > pta) {
      arr[i] = arr[i - 1]
      i -= 1
    }
    arr[pta] = temp
  }
}

// -- Parity merges --------------------------------------------------------------------------

fun parityMerge4(arr: Array<Int>, start: Int, dest: Array<Int>, auxOffset: Int) {
  var auxP = auxOffset
  var ptl = start
  var ptr = start + 4

  for (i in 0 until 3) {
    if (arr[ptl] <= arr[ptr]) {
      dest[auxP] = arr[ptl]
      ptl += 1
    } else {
      dest[auxP] = arr[ptr]
      ptr += 1
    }
    auxP += 1
  }
  if (arr[ptl] <= arr[ptr]) {
    dest[auxP] = arr[ptl]
  } else {
    dest[auxP] = arr[ptr]
  }

  ptl = start + 3
  ptr = start + 7
  auxP += 4

  for (i in 0 until 3) {
    if (arr[ptl] > arr[ptr]) {
      dest[auxP] = arr[ptl]
      ptl -= 1
    } else {
      dest[auxP] = arr[ptr]
      ptr -= 1
    }
    auxP -= 1
  }
  if (arr[ptl] > arr[ptr]) {
    dest[auxP] = arr[ptl]
  } else {
    dest[auxP] = arr[ptr]
  }
}

fun parityMerge8(arr: Array<Int>, from: Array<Int>, start: Int) {
  var mainP = start
  var ptl = 0
  var ptr = 8

  for (i in 0 until 7) {
    if (from[ptl] <= from[ptr]) {
      arr[mainP] = from[ptl]
      ptl += 1
    } else {
      arr[mainP] = from[ptr]
      ptr += 1
    }
    mainP += 1
  }
  if (from[ptl] <= from[ptr]) {
    arr[mainP] = from[ptl]
  } else {
    arr[mainP] = from[ptr]
  }

  ptl = 7
  ptr = 15
  mainP += 8

  for (i in 0 until 7) {
    if (from[ptl] > from[ptr]) {
      arr[mainP] = from[ptl]
      ptl -= 1
    } else {
      arr[mainP] = from[ptr]
      ptr -= 1
    }
    mainP -= 1
  }
  if (from[ptl] > from[ptr]) {
    arr[mainP] = from[ptl]
  } else {
    arr[mainP] = from[ptr]
  }
}

fun parityMerge16(arr: Array<Int>, start: Int, aux: Array<Int>) {
  if (arr[start + 3] <= arr[start + 4] && arr[start + 7] <= arr[start + 8] &&
    arr[start + 11] <= arr[start + 12]
  ) {
    return
  }

  parityMerge4(arr, start, aux, 0)
  parityMerge4(arr, start + 8, aux, 8)
  parityMerge8(arr, aux, start)
}

// -- Bottom-up tail merge -----------------------------------------------------------------------

fun partialBackwardMerge(arr: Array<Int>, aux: Array<Int>, start: Int, nmemb: Int, block: Int) {
  var m = start + block
  var e = start + nmemb - 1
  val r = m
  m -= 1

  if (arr[m] <= arr[r]) {
    return
  }
  while (arr[m] <= arr[e]) {
    e -= 1
  }

  for (i in r until (r + (e - m))) {
    aux[i - r] = arr[i]
  }

  var s = e - r
  arr[e] = arr[m]
  e -= 1
  m -= 1

  if (arr[start] <= aux[0]) {
    do {
      while (arr[m] > aux[s]) {
        arr[e] = arr[m]
        e -= 1
        m -= 1
      }
      arr[e] = aux[s]
      e -= 1
      s -= 1
    } while (s >= 0)
  } else {
    do {
      while (arr[m] <= aux[s]) {
        arr[e] = aux[s]
        e -= 1
        s -= 1
      }
      arr[e] = arr[m]
      e -= 1
      m -= 1
    } while (m >= start)
    do {
      arr[e] = aux[s]
      e -= 1
      s -= 1
    } while (s >= 0)
  }
}

fun tailMerge(arr: Array<Int>, aux: Array<Int>, start: Int, nmemb: Int, blockIn: Int) {
  var block = blockIn
  val pte = start + nmemb

  while (block < nmemb) {
    var pta = start
    while (pta + block < pte) {
      if (pta + block * 2 < pte) {
        partialBackwardMerge(arr, aux, pta, block * 2, block)
        pta += block * 2
        continue
      }
      partialBackwardMerge(arr, aux, pta, pte - pta, block)
      break
    }
    block *= 2
  }
}

// -- Quad merge -----------------------------------------------------------------------------

fun forwardMergeRead(arr: Array<Int>, aux: Array<Int>, toAux: Boolean, i: Int): Int = if (toAux) arr[i] else aux[i]

fun forwardMergeWrite(arr: Array<Int>, aux: Array<Int>, toAux: Boolean, i: Int, value: Int) {
  if (toAux) {
    aux[i] = value
  } else {
    arr[i] = value
  }
}

fun forwardMerge(
  arr: Array<Int>, aux: Array<Int>, start: Int, auxStart: Int, block: Int, toAux: Boolean,
) {
  var mergeP = if (toAux) auxStart else start
  var l = if (toAux) start else auxStart
  var r = if (toAux) (start + block) else (auxStart + block)
  val m = r
  val e = r + block

  if (forwardMergeRead(arr, aux, toAux, r - 1) <= forwardMergeRead(arr, aux, toAux, e - 1)) {
    while (l < m) {
      if (forwardMergeRead(arr, aux, toAux, l) <= forwardMergeRead(arr, aux, toAux, r)) {
        forwardMergeWrite(arr, aux, toAux, mergeP, forwardMergeRead(arr, aux, toAux, l))
        mergeP += 1
        l += 1
      } else {
        forwardMergeWrite(arr, aux, toAux, mergeP, forwardMergeRead(arr, aux, toAux, r))
        mergeP += 1
        r += 1
      }
    }
    while (r < e) {
      forwardMergeWrite(arr, aux, toAux, mergeP, forwardMergeRead(arr, aux, toAux, r))
      mergeP += 1
      r += 1
    }
  } else {
    while (r < e) {
      if (forwardMergeRead(arr, aux, toAux, l) > forwardMergeRead(arr, aux, toAux, r)) {
        forwardMergeWrite(arr, aux, toAux, mergeP, forwardMergeRead(arr, aux, toAux, r))
        mergeP += 1
        r += 1
      } else {
        forwardMergeWrite(arr, aux, toAux, mergeP, forwardMergeRead(arr, aux, toAux, l))
        mergeP += 1
        l += 1
      }
    }
    while (l < m) {
      forwardMergeWrite(arr, aux, toAux, mergeP, forwardMergeRead(arr, aux, toAux, l))
      mergeP += 1
      l += 1
    }
  }
}

fun quadMergeBlock(arr: Array<Int>, start: Int, aux: Array<Int>, block: Int) {
  val blockX2 = block * 2
  var cMax = start + block

  if (arr[cMax - 1] <= arr[cMax]) {
    cMax += blockX2

    if (arr[cMax - 1] <= arr[cMax]) {
      cMax -= block

      if (arr[cMax - 1] <= arr[cMax]) {
        return
      }

      var pts = 0
      var c = start
      do {
        aux[pts] = arr[c]
        c += 1
        pts += 1
      } while (c < cMax)

      cMax = c + blockX2
      do {
        aux[pts] = arr[c]
        c += 1
        pts += 1
      } while (c < cMax)

      forwardMerge(arr, aux, start, 0, blockX2, false)
      return
    }

    var pts = 0
    var c = start
    cMax = start + blockX2
    do {
      aux[pts] = arr[c]
      c += 1
      pts += 1
    } while (c < cMax)
  } else {
    forwardMerge(arr, aux, start, 0, block, true)
  }

  forwardMerge(arr, aux, start + blockX2, blockX2, block, true)
  forwardMerge(arr, aux, start, 0, blockX2, false)
}

fun quadMerge(arr: Array<Int>, aux: Array<Int>, start: Int, nmemb: Int, blockIn: Int) {
  val pte = start + nmemb
  var block = blockIn * 4

  while (block * 2 <= nmemb) {
    var pta = start
    do {
      quadMergeBlock(arr, pta, aux, block / 4)
      pta += block
    } while (pta + block <= pte)
    tailMerge(arr, aux, pta, pte - pta, block / 4)
    block *= 4
  }
  tailMerge(arr, aux, start, nmemb, block / 4)
}

// -- Pre-sort pass --------------------------------------------------------------------------

// Pre-sorting pass: a 4-item sorting network applied across the whole range, with a side
// detector for strictly-decreasing runs -- reversed in place rather than merged. If the *entire*
// range turns out strictly decreasing, one reversal finishes the sort outright (returns 1);
// otherwise this finishes with parity-merge passes over what's left (returns 0).
fun quadSwap(arr: Array<Int>, start: Int, nmemb: Int): Int {
  val swapBuf = Array(16) { 0 }
  var pta = start
  var count = nmemb / 4
  var pts = 0

  swapper@ while (count > 0) {
    count -= 1

    innerA@ while (true) {
      if (arr[pta] > arr[pta + 1]) {
        if (arr[pta + 2] > arr[pta + 3]) {
          if (arr[pta + 1] > arr[pta + 2]) {
            pts = pta
            pta += 4
            break@innerA
          }
          swap2(arr, pta + 2, pta + 3)
        }
        swap2(arr, pta, pta + 1)
      } else if (arr[pta + 2] > arr[pta + 3]) {
        swap2(arr, pta + 2, pta + 3)
      }

      if (arr[pta + 1] > arr[pta + 2]) {
        if (arr[pta] <= arr[pta + 2]) {
          if (arr[pta + 1] <= arr[pta + 3]) {
            swap2(arr, pta + 1, pta + 2)
          } else {
            val temp = arr[pta + 1]
            arr[pta + 1] = arr[pta + 2]
            arr[pta + 2] = arr[pta + 3]
            arr[pta + 3] = temp
          }
        } else if (arr[pta] > arr[pta + 3]) {
          swap2(arr, pta + 1, pta + 3)
          swap2(arr, pta, pta + 2)
        } else if (arr[pta + 1] <= arr[pta + 3]) {
          val temp = arr[pta + 1]
          arr[pta + 1] = arr[pta]
          arr[pta] = arr[pta + 2]
          arr[pta + 2] = temp
        } else {
          val temp = arr[pta + 1]
          arr[pta + 1] = arr[pta]
          arr[pta] = arr[pta + 2]
          arr[pta + 2] = arr[pta + 3]
          arr[pta + 3] = temp
        }
      }
      pta += 4
      continue@swapper
    }

    innerB@ while (true) {
      if (count > 0) {
        count -= 1

        if (arr[pta] > arr[pta + 1]) {
          if (arr[pta + 2] > arr[pta + 3]) {
            if (arr[pta + 1] > arr[pta + 2]) {
              if (arr[pta - 1] > arr[pta]) {
                pta += 4
                continue@innerB
              }
            }
            swap2(arr, pta + 2, pta + 3)
          }
          swap2(arr, pta, pta + 1)
        } else if (arr[pta + 2] > arr[pta + 3]) {
          swap2(arr, pta + 2, pta + 3)
        }

        if (arr[pta + 1] > arr[pta + 2]) {
          if (arr[pta] <= arr[pta + 2]) {
            if (arr[pta + 1] <= arr[pta + 3]) {
              swap2(arr, pta + 1, pta + 2)
            } else {
              val temp = arr[pta + 1]
              arr[pta + 1] = arr[pta + 2]
              arr[pta + 2] = arr[pta + 3]
              arr[pta + 3] = temp
            }
          } else if (arr[pta] > arr[pta + 3]) {
            swap2(arr, pta, pta + 2)
            swap2(arr, pta + 1, pta + 3)
          } else if (arr[pta + 1] <= arr[pta + 3]) {
            val temp = arr[pta]
            arr[pta] = arr[pta + 2]
            arr[pta + 2] = arr[pta + 1]
            arr[pta + 1] = temp
          } else {
            val temp = arr[pta]
            arr[pta] = arr[pta + 2]
            arr[pta + 2] = arr[pta + 3]
            arr[pta + 3] = arr[pta + 1]
            arr[pta + 1] = temp
          }
        }

        reverseInclusive(arr, pts, pta - 1)
        pta += 4
        continue@swapper
      }

      if (pts == start) {
        var remainder = nmemb % 4
        if (remainder == 3) {
          remainder = if (arr[pta + 1] > arr[pta + 2]) 2 else -1
        }
        if (remainder == 2) {
          remainder = if (arr[pta] > arr[pta + 1]) 1 else -1
        }
        if (remainder == 1) {
          remainder = if (arr[pta - 1] > arr[pta]) 0 else -1
        }
        if (remainder == 0) {
          reverseInclusive(arr, pts, pts + nmemb - 1)
          return 1
        }
      }

      reverseInclusive(arr, pts, pta - 1)
      break@swapper
    }
  }

  tailSwap(arr, pta, nmemb % 4)

  pta = start
  count = nmemb / 16
  while (count > 0) {
    count -= 1
    parityMerge16(arr, pta, swapBuf)
    pta += 16
  }

  if (nmemb % 16 > 4) {
    tailMerge(arr, swapBuf, pta, nmemb % 16, 4)
  }

  return 0
}

// -- Entry point -----------------------------------------------------------------------------

// Top-level dispatch by size: under 16 is a plain tailSwap; under 256 pre-sorts via quadSwap then
// finishes with tailMerge; 256 and up finishes with the full quadMerge pass instead.
fun sort(arr: Array<Int>, n: Int) {
  if (n < 16) {
    tailSwap(arr, 0, n)
  } else if (n < 256) {
    if (quadSwap(arr, 0, n) == 0) {
      val buffer = Array(128) { 0 }
      tailMerge(arr, buffer, 0, n, 16)
    }
  } else {
    if (quadSwap(arr, 0, n) == 0) {
      val buffer = Array(n / 2) { 0 }
      quadMerge(arr, buffer, 0, n, 16)
    }
  }
}

fun main() {
  var array = arrayOf<Int>(
    55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79, 21, 88, 5, 51,
    66, 29, 44, 12, 90, 1, 58, 33, 71, 19, 60, 45, 27, 82, 6, 95, 38, 63, 9, 50,
  )
  sort(array, array.size)
  println("[%s]".format(array.joinToString(", ")))
}
