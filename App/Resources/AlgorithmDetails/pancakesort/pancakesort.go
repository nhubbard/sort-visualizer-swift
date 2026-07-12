package main

import (
  "fmt"
)

func flip(arr []int, n int) {
  left := 0
  for left < n {
    arr[left], arr[n] = arr[n], arr[left]
    n--
    left++
  }
}

func maxIndex(arr []int, n int) int {
  index := 0
  for i := 0; i < n; i++ {
    if arr[i] > arr[index] {
      index = i
    }
  }
  return index
}

func sort(arr []int) []int {
  n := len(arr)
  max := 0
  for n > 1 {
    max = maxIndex(arr, n)
    if max != n {
      flip(arr, max)
      flip(arr, n - 1)
    }
    n--;
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}