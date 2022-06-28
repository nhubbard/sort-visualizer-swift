package main

import (
  "fmt"
)

func sort(arr []int) []int {
  n := len(arr)
  var sm int
  shrink := 1.3
  gap := n
  sorted := false
  for !sorted {
    gap = int(float64(gap) / shrink)
    if gap <= 1 {
      sorted = true
      gap = 1
    }
    for i := 0; i < n - gap; i++ {
      sm = gap + i
      if arr[i] > arr[sm] {
        arr[i], arr[sm] = arr[sm], arr[i]
        sorted = false;
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
