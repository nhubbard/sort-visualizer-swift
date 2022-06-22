package main

import (
  "fmt"
)

func sort(arr []int) []int {
  n := len(arr)
  for k := 2; k <= n; k *= 2 {
    for j := k / 2; j > 0; j /= 2 {
      for i := 0; i < n; i++ {
        l := i ^ j
        if l > i {
          if (((i & k) == 0) && (arr[i] > arr[l]) ||
          (((i & k) != 0) && (arr[i] < arr[l]))) {
            arr[i], arr[l] = arr[l], arr[i]
          }
        }
      }
    }
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}