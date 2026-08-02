fun sort(arr: Array<Int>) {
  fun dirCompareVal(left: Int, right: Int, dir: Boolean): Int {
    val res = if (left > right) 1 else if (left < right) -1 else 0
    return if (dir) res else -res
  }

  fun gapReverse(start: Int, end: Int, gap: Int) {
    var i = start
    var j = end
    while (i < j) {
      val tmp = arr[i]
      arr[i] = arr[j - gap]
      arr[j - gap] = tmp
      i += gap
      j -= gap
    }
  }

  fun insertLast(a: Int, b: Int, gap: Int, dir: Boolean): Boolean {
    var did = false
    val key = arr[b]
    var j = b - gap
    while (j >= a && dirCompareVal(key, arr[j], dir) < 0) {
      arr[j + gap] = arr[j]
      did = true
      j -= gap
    }
    arr[j + gap] = key
    return did
  }

  data class MatrixShape(
    val width: Int,
    val insertLast: Boolean,
  )

  fun getMatrixDims(length: Int): MatrixShape {
    var dim = Math.sqrt(length.toDouble()).toInt()
    val insertLastFlag = dim * dim == length - 1
    while (length % dim != 0) {
      dim -= 1
    }
    val width = dim
    val height = length / dim
    val unbalanced = (width == 1) != (height == 1)
    return MatrixShape(width, unbalanced || insertLastFlag)
  }

  fun matrixSort(start: Int, end: Int, gap: Int, dir: Boolean): Boolean {
    val length = (end - start) / gap
    if (length < 2) {
      return false
    } else if (length <= 16) {
      var did = false
      var i = start
      while (i < end) {
        did = insertLast(start, i, gap, dir) || did
        i += gap
      }
      return did
    } else {
      val matShape = getMatrixDims(length)
      if (matShape.insertLast) {
        val did1 = matrixSort(start, end - gap, gap, dir)
        val did2 = insertLast(start, end - gap, gap, dir)
        return did1 || did2
      }

      var i = start + matShape.width * gap
      while (i < end) {
        gapReverse(i, i + matShape.width * gap, gap)
        i += 2 * matShape.width * gap
      }

      var did = false
      var newdid = true
      while (newdid) {
        newdid = false
        var curdir = dir
        i = start
        while (i < end) {
          newdid = matrixSort(i, i + matShape.width * gap, gap, curdir) || newdid
          did = did || newdid
          curdir = !curdir
          i += matShape.width * gap
        }

        newdid = false
        for (k in 0 until matShape.width) {
          newdid = matrixSort(start + k * gap, end + k * gap, gap * matShape.width, dir) || newdid
          did = did || newdid
        }
      }
      i = start + matShape.width * gap
      while (i < end) {
        gapReverse(i, i + matShape.width * gap, gap)
        i += 2 * matShape.width * gap
      }

      return did
    }
  }

  matrixSort(0, arr.size, 1, true)
}

fun main() {
  var array = arrayOf<Int>(
    15, 3, 22, 8, 19, 1, 24, 11, 6, 20,
    9, 17, 2, 14, 23, 5, 18, 0, 12, 21,
    7, 16, 4, 13, 10,
  )
  sort(array)
  println("[%s]".format(array.joinToString(", ")))
}
