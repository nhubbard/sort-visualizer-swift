package main

import (
  "fmt"
)

func partition(arr []int, lo, hi int) ([]int, int) {
  pivot := arr[hi]
  i := lo
  for j := lo; j < hi; j++ {
    if arr[j] < pivot {
      arr[i], arr[j] = arr[j], arr[i]
      i++
    }
  }
  arr[i], arr[hi] = arr[hi], arr[i]
  return arr, i
}

func quickSort(arr []int, lo, hi int) []int {
  if lo < hi {
    var p int
    arr, p = partition(arr, lo, hi)
    arr = quickSort(arr, lo, p-1)
    arr = quickSort(arr, p+1, hi)
  }
  return arr
}

func sort(arr []int) []int {
  return quickSort(arr, 0, len(arr)-1)
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
