package main

import (
  "fmt"
)

func greatestPowerOfTwoLessThan(n int) int {
  k := 1
  for k < n {
    k <<= 1
  }
  return k >> 1
}

func compare(arr []int, i, j int, dir bool) {
  isGreater := arr[i] > arr[j]
  if dir == isGreater {
    arr[i], arr[j] = arr[j], arr[i]
  }
}

func bitonicMerge(arr []int, lo, n int, dir bool) {
  if n > 1 {
    m := greatestPowerOfTwoLessThan(n)
    for i := lo; i < lo+n-m; i++ {
      compare(arr, i, i+m, dir)
    }
    bitonicMerge(arr, lo, m, dir)
    bitonicMerge(arr, lo+m, n-m, dir)
  }
}

func bitonicSort(arr []int, lo, n int, dir bool) {
  if n > 1 {
    m := n / 2
    bitonicSort(arr, lo, m, !dir)
    bitonicSort(arr, lo+m, n-m, dir)
    bitonicMerge(arr, lo, n, dir)
  }
}

func sort(arr []int) []int {
  bitonicSort(arr, 0, len(arr), true)
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
