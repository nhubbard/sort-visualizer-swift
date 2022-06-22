package main

import (
  "fmt"
)

func sort(arr []int) []int {
  n := len(arr)
  var sorted bool
  for !sorted {
    sorted = true
    for i := 1; i < n - 1; i += 2 {
      if arr[i] > arr[i + 1] {
        arr[i], arr[i + 1] = arr[i + 1], arr[i]
        sorted = false
      }
    }
    for i := 0; i < n - 1; i += 2 {
      if arr[i] > arr[i + 1] {
        arr[i], arr[i + 1] = arr[i + 1], arr[i]
        sorted = false
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