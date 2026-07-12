package main

import (
  "fmt"
)

func nextPowerOfTwo(n int) int {
  k := 1
  for k < n {
    k <<= 1
  }
  return k
}

func circleSortRoutine(arr []int, lo, hi, end int) int {
  if lo == hi {
    return 0
  }
  low := lo
  high := hi
  mid := (hi - lo) / 2
  swaps := 0
  for lo < hi {
    if hi < end && arr[lo] > arr[hi] {
      arr[lo], arr[hi] = arr[hi], arr[lo]
      swaps++
    }
    lo++
    hi--
  }
  swaps += circleSortRoutine(arr, low, low+mid, end)
  if low+mid+1 < end {
    swaps += circleSortRoutine(arr, low+mid+1, high, end)
  }
  return swaps
}

func sort(arr []int) []int {
  end := len(arr)
  if end == 0 {
    return arr
  }
  paddedLength := nextPowerOfTwo(end)
  swaps := -1
  for swaps != 0 {
    swaps = circleSortRoutine(arr, 0, paddedLength-1, end)
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
