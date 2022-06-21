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
  items := []int{35, 95, 74, 71, 72, 30, 96, 53, 9, 0}
  fmt.Println(sort(items))
}
