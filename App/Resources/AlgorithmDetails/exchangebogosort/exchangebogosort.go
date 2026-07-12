package main

import (
  "fmt"
  "math/rand"
  "sort"
)

func _sort(arr []int) []int {
  n := len(arr)
  for !sort.IntsAreSorted(arr) {
    i := rand.Intn(n)
    j := rand.Intn(n)
    if (i < j && arr[i] > arr[j]) || (i > j && arr[i] < arr[j]) {
      arr[i], arr[j] = arr[j], arr[i]
    }
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23}
  fmt.Println(_sort(array))
}
