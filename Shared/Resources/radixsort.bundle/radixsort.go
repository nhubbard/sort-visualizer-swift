package main

import (
  "fmt"
)

func max(arr []int) int {
  n := len(arr)
  max := arr[0]
  for i := 1; i < n; i++ {
    if arr[i] > max {
      max = arr[i]
    }
  }
  return max
}

func sort(arr []int) []int {
  n := len(arr)
  var bucket [10][10]int
  var bucketCount [10]int
  nop := 0
  divisor := 1
  lar := max(arr)
  for lar > 0 {
    nop++
    lar /= 10
  }
  for pass := 0; pass < nop; pass++ {
    i := 0
    for i = 0; i < 10; i++ {
      bucketCount[i] = 0
    }
    for i = 0; i < n; i++ {
      r := (arr[i] / divisor) % 10
      bucket[r][bucketCount[r]] = arr[i]
      bucketCount[r] += 1
    }
    i = 0
    for k := 0; k < 10; k++ {
      for j := 0; j < bucketCount[k]; j++ {
        arr[i] = bucket[k][j]
        i++
      }
    }
    divisor *= 10;
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}