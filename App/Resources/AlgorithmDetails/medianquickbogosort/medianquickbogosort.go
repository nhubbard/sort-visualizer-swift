package main

import (
  "fmt"
  "math/rand"
)

func isSplit(arr []int, start int, mid int, end int) bool {
  lowMax := arr[start]
  for i := start + 1; i < mid; i++ {
    if arr[i] > lowMax {
      lowMax = arr[i]
    }
  }
  for i := mid; i < end; i++ {
    if lowMax > arr[i] {
      return false
    }
  }
  return true
}

func sortRange(arr []int, start int, end int) {
  if start >= end-1 {
    return
  }
  mid := (start + end) / 2

  for !isSplit(arr, start, mid, end) {
    rand.Shuffle(end-start, func(i, j int) {
      arr[start+i], arr[start+j] = arr[start+j], arr[start+i]
    })
  }

  sortRange(arr, start, mid)
  sortRange(arr, mid, end)
}

func sort(arr []int) []int {
  sortRange(arr, 0, len(arr))
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 14, 23}
  fmt.Println(sort(array))
}
