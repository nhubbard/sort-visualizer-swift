package main

import (
  "fmt"
)

func siftDown(arr []int, i int, b int) {
  j := i
  for 2*j+1 < b {
    if 2*j+2 < b {
      if arr[2*j+2] > arr[2*j+1] {
        j = 2*j + 2
      } else {
        j = 2*j + 1
      }
    } else {
      j = 2*j + 1
    }
  }
  for arr[i] > arr[j] {
    j = (j - 1) / 2
  }
  for j > i {
    arr[i], arr[j] = arr[j], arr[i]
    j = (j - 1) / 2
  }
}

func sort(arr []int) []int {
  n := len(arr)
  for i := (n - 1) / 2; i >= 0; i-- {
    siftDown(arr, i, n)
  }
  for i := n - 1; i > 0; i-- {
    arr[0], arr[i] = arr[i], arr[0]
    siftDown(arr, 0, i)
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
