package main

import (
  "fmt"
)

func sort(arr []int) []int {
  start := 0
  end := len(arr) - 1
  for start < end {
    consecSorted := 1
    for i := start; i < end; i++ {
      if arr[i] > arr[i+1] {
        arr[i], arr[i+1] = arr[i+1], arr[i]
        consecSorted = 1
      } else {
        consecSorted++
      }
    }
    end -= consecSorted

    consecSorted = 1
    for j := end; j > start; j-- {
      if arr[j-1] > arr[j] {
        arr[j-1], arr[j] = arr[j], arr[j-1]
        consecSorted = 1
      } else {
        consecSorted++
      }
    }
    start += consecSorted
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
