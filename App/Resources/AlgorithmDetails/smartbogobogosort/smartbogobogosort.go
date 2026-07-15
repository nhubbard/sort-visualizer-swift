package main

import (
  "fmt"
  "math/rand"
)

func sort(arr []int, length int) []int {
  if length == 1 {
    return arr
  }
  sort(arr, length-1)
  for arr[length-2] > arr[length-1] {
    rand.Shuffle(length, func(i, j int) { arr[i], arr[j] = arr[j], arr[i] })
    sort(arr, length-1)
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 14, 23}
  fmt.Println(sort(array, len(array)))
}
