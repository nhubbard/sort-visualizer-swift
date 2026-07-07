package main

import (
  "fmt"
)

func sort(arr []int) []int {
  n := len(arr)
  for i := 1; i < n; i++ {
    key := arr[i]
    j := i - 1
    for j >= 0 && arr[j] > key {
      arr[j + 1] = arr[j]
      j = j - 1
    }
    arr[j + 1] = key
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}