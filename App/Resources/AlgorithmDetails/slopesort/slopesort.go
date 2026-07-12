package main

import (
  "fmt"
)

func sort(arr []int) []int {
  n := len(arr)
  for start := 1; start < n; start++ {
    i := start
    k := start - 1
    for k >= 0 {
      if arr[i] < arr[k] {
        arr[i], arr[k] = arr[k], arr[i]
      }
      k--
      i--
    }
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}