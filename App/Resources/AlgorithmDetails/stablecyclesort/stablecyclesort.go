package main

import (
  "fmt"
)

func destination(arr []int, flagged []bool, a, b1, b int) int {
  heldValue := arr[a]
  d := a
  e := 0
  for i := a + 1; i < b; i++ {
    if arr[i] < heldValue {
      d++
    } else if i < b1 && !flagged[i] && arr[i] == heldValue {
      e++
    }
  }
  for flagged[d] || e > 0 {
    if !flagged[d] {
      e--
    }
    d++
  }
  return d
}

func stableCycleSort(arr []int) []int {
  n := len(arr)
  if n <= 1 {
    return arr
  }
  flagged := make([]bool, n)
  for i := 0; i < n-1; i++ {
    if flagged[i] {
      continue
    }
    j := i
    for {
      k := destination(arr, flagged, i, j, n)
      arr[i], arr[k] = arr[k], arr[i]
      flagged[k] = true
      j = k
      if j == i {
        break
      }
    }
  }
  return arr
}

func sort(arr []int) []int {
  return stableCycleSort(arr)
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
