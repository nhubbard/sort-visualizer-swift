package main

import (
  "fmt"
)

func flip(arr []int, end int) {
  start := 0
  for start < end {
    arr[start], arr[end] = arr[end], arr[start]
    start++
    end--
  }
}

func sort(arr []int) []int {
  n := len(arr)
  for i := n - 1; i > 0; i-- {
    max := 0
    for j := max + 1; j <= i; j++ {
      if arr[j] > arr[max] {
        max = j
      }
    }
    if max != i {
      flip(arr, max)
      flip(arr, i)
      flip(arr, i-1)
      flip(arr, max-1)
    }
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}