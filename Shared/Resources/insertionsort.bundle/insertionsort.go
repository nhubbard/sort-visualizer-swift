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
  items := []int{35, 95, 74, 71, 72, 30, 96, 53, 9, 0}
  fmt.Println(sort(items))
}