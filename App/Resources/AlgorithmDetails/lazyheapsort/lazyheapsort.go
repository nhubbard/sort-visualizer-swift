package main

import (
  "fmt"
  "math"
)

func maxToFront(arr []int, a int, b int) {
  best := a
  i := a + 1
  for i < b {
    if arr[i] > arr[best] {
      best = i
    }
    i++
  }
  arr[best], arr[a] = arr[a], arr[best]
}

func sort(arr []int) []int {
  n := len(arr)
  s := int(math.Sqrt(float64(n-1))) + 1

  i := 0
  for i < n {
    maxToFront(arr, i, min(i+s, n))
    i += s
  }

  j := n
  for j > 0 {
    best := 0
    k := best + s
    for k < j {
      if arr[k] >= arr[best] {
        best = k
      }
      k += s
    }
    j--
    arr[best], arr[j] = arr[j], arr[best]
    maxToFront(arr, best, min(best+s, j))
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
