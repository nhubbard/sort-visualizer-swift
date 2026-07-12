import Foundation

func oddEvenMergeCompare(_ array: inout [Int], _ i: Int, _ j: Int) {
  if array[i] > array[j] {
    array.swapAt(i, j)
  }
}

// lo is the starting position, m2 is the halfway point, n is the length of
// the piece being merged, and r is the distance of the elements compared.
func oddEvenMerge(
  _ array: inout [Int],
  _ lo: Int,
  _ m2: Int,
  _ n: Int,
  _ r: Int
) {
  let m = r * 2
  if m < n {
    if (n / r) % 2 != 0 {
      oddEvenMerge(&array, lo, (m2 + 1) / 2, n + r, m)     // even subsequence
      oddEvenMerge(&array, lo + r, m2 / 2, n - r, m)       // odd subsequence
    } else {
      oddEvenMerge(&array, lo, (m2 + 1) / 2, n, m)         // even subsequence
      oddEvenMerge(&array, lo + r, m2 / 2, n, m)           // odd subsequence
    }

    if m2 % 2 != 0 {
      var i = lo
      while i + r < lo + n {
        oddEvenMergeCompare(&array, i, i + r)
        i += m
      }
    } else {
      var i = lo + r
      while i + r < lo + n {
        oddEvenMergeCompare(&array, i, i + r)
        i += m
      }
    }
  } else {
    if n > r {
      oddEvenMergeCompare(&array, lo, lo + r)
    }
  }
}

func oddEvenMergeSort(_ array: inout [Int], _ lo: Int, _ n: Int) {
  if n > 1 {
    let m = n / 2
    oddEvenMergeSort(&array, lo, m)
    oddEvenMergeSort(&array, lo + m, n - m)
    oddEvenMerge(&array, lo, m, n, 1)
  }
}

func sort(_ array: inout [Int]) {
  oddEvenMergeSort(&array, 0, array.count)
}

var array: [Int] = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
