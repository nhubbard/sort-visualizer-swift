package main

import (
  "fmt"
)

func bubbleSort(arr []int, n int) []int {
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
  items := []int{35, 95, 74, 71, 72, 30, 96, 53, 9, 0}
  fmt.Println(bubbleSort(items, len(items)))
}