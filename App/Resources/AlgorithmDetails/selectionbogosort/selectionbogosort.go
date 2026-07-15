package main

import (
  "fmt"
  "math/rand"
)

func minFrom(arr []int, i int) int {
  m := arr[i]
  for k := i + 1; k < len(arr); k++ {
    if arr[k] < m {
      m = arr[k]
    }
  }
  return m
}

func sort(arr []int) []int {
  n := len(arr)
  for i := 0; i < n; i++ {
    for arr[i] != minFrom(arr, i) {
      j := i + rand.Intn(n-i)
      arr[i], arr[j] = arr[j], arr[i]
    }
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 14, 23}
  fmt.Println(sort(array))
}
