package main

import (
  "fmt"
)

func sort(arr []int) []int {
  n := len(arr)
  ext := make([]int, n)
  copy(ext, arr)
  minValue := ext[0]
  maxValue := ext[0]
  for k := 0; k < n; k++ {
    if ext[k] < minValue {
      minValue = ext[k]
    }
    if ext[k] > maxValue {
      maxValue = ext[k]
    }
  }
  maxValue += 1

  cur := minValue
  i := 0
  for i < n {
    for j := 0; j < n; j++ {
      if ext[j] <= cur {
        arr[i] = ext[j]
        ext[j] = maxValue
        i += 1
      }
    }
    cur += 1
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
