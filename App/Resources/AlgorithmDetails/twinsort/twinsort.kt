fun reverseRange(arr: Array<Int>, lo0: Int, hi0: Int) {
  var lo = lo0
  var hi = hi0
  while (lo < hi) {
    val t = arr[lo]
    arr[lo] = arr[hi]
    arr[hi] = t
    lo++
    hi--
  }
}

fun twinSwap(arr: Array<Int>, nmemb: Int): Int {
  var index = 0
  var end = nmemb - 2
  while (index <= end) {
    if (arr[index] <= arr[index + 1]) {
      index += 2
      continue
    }
    val start = index
    index += 2
    while (true) {
      if (index > end) {
        if (start == 0 && (nmemb % 2 == 0 || arr[index - 1] > arr[index])) {
          end = nmemb - 1
          reverseRange(arr, start, end)
          return 1
        }
        break
      }
      if (arr[index] > arr[index + 1]) {
        if (arr[index - 1] > arr[index]) {
          index += 2
          continue
        }
        val t = arr[index]
        arr[index] = arr[index + 1]
        arr[index + 1] = t
      }
      break
    }
    end = index - 1
    reverseRange(arr, start, end)
    end = nmemb - 2
    index += 2
  }
  return 0
}

fun tailMerge(arr: Array<Int>, buf: IntArray, nmemb: Int, block0: Int) {
  val s = 0
  var block = block0
  while (block < nmemb) {
    var offset = 0
    while (offset + block < nmemb) {
      val a = offset
      var e = a + block - 1
      if (arr[e] <= arr[e + 1]) {
        offset += block * 2
        continue
      }
      var cMax: Int
      var dMax: Int
      if (offset + block * 2 <= nmemb) {
        cMax = s + block
        dMax = a + block * 2
      } else {
        cMax = s + nmemb - (offset + block)
        dMax = nmemb
      }
      var d = dMax - 1
      while (arr[e] <= arr[d]) {
        dMax--
        d--
        cMax--
      }
      var c = s
      d = a + block
      while (c < cMax) {
        buf[c] = arr[d]
        c++
        d++
      }
      c--
      d = a + block - 1
      e = dMax - 1
      if (arr[a] <= arr[a + block]) {
        arr[e] = arr[d]; e--; d--
        while (c >= s) {
          while (arr[d] > buf[c]) {
            arr[e] = arr[d]; e--; d--
          }
          arr[e] = buf[c]; e--; c--
        }
      } else {
        arr[e] = arr[d]; e--; d--
        while (d >= a) {
          while (arr[d] <= buf[c]) {
            arr[e] = buf[c]; e--; c--
          }
          arr[e] = arr[d]; e--; d--
        }
        while (c >= s) {
          arr[e] = buf[c]; e--; c--
        }
      }
      offset += block * 2
    }
    block *= 2
  }
}

fun twinsort(arr: Array<Int>, nmemb: Int) {
  if (twinSwap(arr, nmemb) == 0) {
    val buf = IntArray(nmemb / 2)
    tailMerge(arr, buf, nmemb, 2)
  }
}

fun sort(arr: Array<Int>) {
  val n = arr.size
  twinsort(arr, n)
}

fun main() {
  var array = arrayOf<Int>(
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
