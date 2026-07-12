package main

import (
  "fmt"
)

func sort(arr []int) []int {
  for i := 0; i < len(arr)-1; i++ {
    min := i
    for j := i + 1; j < len(arr); j++ {
      if arr[j] < arr[min] {
        min = j
      }
    }
    tmp := arr[min]
    pos := min
    for pos > i {
      arr[pos] = arr[pos-1]
      pos--
    }
    arr[pos] = tmp
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
