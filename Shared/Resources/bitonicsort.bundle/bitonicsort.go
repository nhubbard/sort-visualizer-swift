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
  // Specific to bitonic sort: size must be power of 2.
  items := []int{35, 74, 71, 72, 30, 53, 9, 0}
  fmt.Println(sort(items))
}
