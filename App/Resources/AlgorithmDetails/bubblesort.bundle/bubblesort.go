package main

import (
  "fmt"
)

func sort(arr []int) []int {
  n := len(arr)
  for c := 0; c < n - 1; c++ {
    for d := 0; d < n - c - 1; d++ {
      if arr[d] > arr[d + 1] {
        arr[d], arr[d + 1] = arr[d + 1], arr[d]
      }
    }
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}