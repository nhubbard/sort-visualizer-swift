package main

import (
  "fmt"
)

func sort(arr []int) []int {
  n := len(arr)
  for i := n / 2; i > 0; i /= 2 {
    for j := i; j < n; j++ {
      for k := j - i; k >= 0; k -= i {
        if arr[k + i] >= arr[k] {
          break
        } else {
          arr[k], arr[k + i] = arr[k + i], arr[k]
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