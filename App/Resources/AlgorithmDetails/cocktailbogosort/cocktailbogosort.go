package main

import (
  "fmt"
  "math/rand"
)

func isMinimum(arr []int, start int, end int) bool {
  for k := start + 1; k < end; k++ {
    if arr[start] > arr[k] {
      return false
    }
  }
  return true
}

func isMaximum(arr []int, start int, end int) bool {
  for k := start; k < end-1; k++ {
    if arr[k] > arr[end-1] {
      return false
    }
  }
  return true
}

func shuffleRange(arr []int, start int, end int) {
  for i := start; i < end-1; i++ {
    j := i + rand.Intn(end-i)
    arr[i], arr[j] = arr[j], arr[i]
  }
}

func sort(arr []int) []int {
  lo := 0
  hi := len(arr)
  for lo < hi-1 {
    if isMinimum(arr, lo, hi) {
      lo++
    } else if isMaximum(arr, lo, hi) {
      hi--
    } else {
      shuffleRange(arr, lo, hi)
    }
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23}
  fmt.Println(sort(array))
}
