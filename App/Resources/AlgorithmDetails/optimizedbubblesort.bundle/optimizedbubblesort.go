package main

import (
  "fmt"
)

func sort(arr []int) []int {
  i := len(arr) - 1
  for i > 0 {
    consecSorted := 1
    for j := 0; j < i; j++ {
      if arr[j] > arr[j+1] {
        arr[j], arr[j+1] = arr[j+1], arr[j]
        consecSorted = 1
      } else {
        consecSorted++
      }
    }
    i -= consecSorted
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
