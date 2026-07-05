package main

import (
  "fmt"
)

func sort(arr []int) []int {
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
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}