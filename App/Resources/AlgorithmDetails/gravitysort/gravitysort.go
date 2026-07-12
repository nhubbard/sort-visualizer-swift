package main

import (
  "fmt"
)

func gravitySort(arr []int) {
  n := len(arr)
  if n == 0 {
    return
  }

  minValue := arr[0]
  maxValue := arr[0]
  for i := 1; i < n; i++ {
    if arr[i] < minValue {
      minValue = arr[i]
    }
    if arr[i] > maxValue {
      maxValue = arr[i]
    }
  }
  ySize := maxValue - minValue + 1

  x := make([]int, n)
  y := make([]int, ySize)

  for i := 0; i < n; i++ {
    x[i] = arr[i] - minValue
    y[x[i]]++
  }

  for i := ySize - 1; i > 0; i-- {
    y[i-1] += y[i]
  }

  for j := ySize - 1; j >= 0; j-- {
    for i := 0; i < n; i++ {
      inc := 0
      if i >= n-y[j] {
        inc++
      }
      if x[i] >= j {
        inc--
      }
      arr[i] += inc
    }
  }
}

func sort(arr []int) []int {
  gravitySort(arr)
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
