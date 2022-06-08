package main

import (
  "fmt"
)

func shakerSort(arr []int) []int {
  swapped := true
  n := len(arr)
  start := 0
  end := n - 1
  for swapped {
    swapped = false
    for i := start; i < end; i++ {
      if arr[i] > arr[i + 1] {
        arr[i], arr[i + 1] = arr[i + 1], arr[i]
        swapped = true
      }
    }
    if !swapped {
      break
    }
    swapped = false
    end--
    for i := end - 1; i >= start; i-- {
      if arr[i] > arr[i + 1] {
        arr[i], arr[i + 1] = arr[i + 1], arr[i]
        swapped = true
      }
    }
    start++
  }
  return arr
}

func main() {
  items := []int{35, 95, 74, 71, 72, 30, 96, 53, 9, 0}
  fmt.Println(shakerSort(items))
}