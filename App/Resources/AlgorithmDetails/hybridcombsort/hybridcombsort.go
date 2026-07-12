package main

import (
  "fmt"
)

func insertionSort(arr []int) {
  n := len(arr)
  for i := 1; i < n; i++ {
    key := arr[i]
    j := i - 1
    for j >= 0 && arr[j] > key {
      arr[j+1] = arr[j]
      j = j - 1
    }
    arr[j+1] = key
  }
}

func sort(arr []int) []int {
  n := len(arr)
  shrink := 1.3
  gap := n
  sorted := false
  threshold := n / 32
  if threshold > 8 {
    threshold = 8
  }
  for !sorted {
    gap = int(float64(gap) / shrink)
    if gap <= 1 {
      sorted = true
      gap = 1
    }
    for i := 0; i < n-gap; i++ {
      if gap <= threshold {
        insertionSort(arr)
        return arr
      }
      sm := gap + i
      if arr[i] > arr[sm] {
        arr[i], arr[sm] = arr[sm], arr[i]
        sorted = false
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
