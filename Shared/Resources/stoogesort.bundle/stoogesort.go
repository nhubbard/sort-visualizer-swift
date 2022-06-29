package main

import (
  "fmt"
)

func sort(arr []int, i, j int) []int {
  if arr[j] < arr[i] {
    arr[i], arr[j] = arr[j], arr[i]
  }
  if j - i > 1 {
    t := (j - i + 1) / 3
    sort(arr, i, j - t)
    sort(arr, i + t, j)
    sort(arr, i, j - t)
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array, 0, len(array) - 1))
}
