package main

import (
  "fmt"
)

func merge(arr []int, low, mid, high int) {
  left := make([]int, mid-low)
  right := make([]int, high-mid)
  copy(left, arr[low:mid])
  copy(right, arr[mid:high])
  i, j, k := 0, 0, low
  for i < len(left) && j < len(right) {
    if left[i] <= right[j] {
      arr[k] = left[i]
      i++
    } else {
      arr[k] = right[j]
      j++
    }
    k++
  }
  for i < len(left) {
    arr[k] = left[i]
    i++
    k++
  }
  for j < len(right) {
    arr[k] = right[j]
    j++
    k++
  }
}

func min(a, b int) int {
  if a < b {
    return a
  }
  return b
}

func sort(arr []int) []int {
  n := len(arr)
  for width := 1; width < n; width *= 2 {
    for low := 0; low < n; low += 2 * width {
      mid := min(low+width, n)
      high := min(low+2*width, n)
      if mid < high {
        merge(arr, low, mid, high)
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
