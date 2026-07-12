package main

import (
  "fmt"
)

func oddEvenMergeCompare(arr []int, i, j int) {
  if arr[i] > arr[j] {
    arr[i], arr[j] = arr[j], arr[i]
  }
}

// lo is the starting position, m2 is the halfway point, n is the length of
// the piece being merged, and r is the distance of the elements compared.
func oddEvenMerge(arr []int, lo, m2, n, r int) {
  m := r * 2
  if m < n {
    if (n/r)%2 != 0 {
      oddEvenMerge(arr, lo, (m2+1)/2, n+r, m)     // even subsequence
      oddEvenMerge(arr, lo+r, m2/2, n-r, m)       // odd subsequence
    } else {
      oddEvenMerge(arr, lo, (m2+1)/2, n, m)       // even subsequence
      oddEvenMerge(arr, lo+r, m2/2, n, m)         // odd subsequence
    }

    if m2%2 != 0 {
      for i := lo; i+r < lo+n; i += m {
        oddEvenMergeCompare(arr, i, i+r)
      }
    } else {
      for i := lo + r; i+r < lo+n; i += m {
        oddEvenMergeCompare(arr, i, i+r)
      }
    }
  } else {
    if n > r {
      oddEvenMergeCompare(arr, lo, lo+r)
    }
  }
}

func oddEvenMergeSort(arr []int, lo, n int) {
  if n > 1 {
    m := n / 2
    oddEvenMergeSort(arr, lo, m)
    oddEvenMergeSort(arr, lo+m, n-m)
    oddEvenMerge(arr, lo, m, n, 1)
  }
}

func sort(arr []int) []int {
  oddEvenMergeSort(arr, 0, len(arr))
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
