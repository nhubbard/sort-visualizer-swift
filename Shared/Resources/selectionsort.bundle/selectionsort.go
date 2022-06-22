package main

import (
  "fmt"
)

func sort(arr []int) []int {
  n := len(arr)
  for i := 0; i < n - 1; i++ {
    minIdx := i
    for j := i + 1; j < n; j++ {
      if arr[j] < arr[minIdx] {
        minIdx = j
      }
    }
    arr[minIdx], arr[i] = arr[i], arr[minIdx]
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}