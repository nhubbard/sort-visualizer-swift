package main

import (
  "fmt"
  "math/rand"
)

func isSorted(arr []int) bool {
  for i := 1; i < len(arr); i++ {
    if arr[i-1] > arr[i] {
      return false
    }
  }
  return true
}

func sort(arr []int) []int {
  n := len(arr)
  for !isSorted(arr) {
    index := rand.Intn(n - 1)
    if arr[index] > arr[index+1] {
      arr[index], arr[index+1] = arr[index+1], arr[index]
    }
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23}
  fmt.Println(sort(array))
}
