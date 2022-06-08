package main

import (
  "fmt"
)

func gnomeSort(arr []int) []int {
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
  items := []int{35, 95, 74, 71, 72, 30, 96, 53, 9, 0}
  fmt.Println(gnomeSort(items))
}