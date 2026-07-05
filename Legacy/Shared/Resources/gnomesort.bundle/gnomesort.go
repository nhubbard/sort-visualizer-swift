package main

import (
  "fmt"
)

func sort(arr []int) []int {
  n := len(arr)
  index := 0
  for index < n {
    if index == 0 {
      index++
    }
    if arr[index] >= arr[index - 1] {
      index++
    } else {
      arr[index], arr[index - 1] = arr[index - 1], arr[index]
      index--
    }
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}