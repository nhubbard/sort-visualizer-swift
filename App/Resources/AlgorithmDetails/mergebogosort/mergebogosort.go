package main

import (
  "fmt"
  "math/rand"
)

func isSorted(arr []int, start int, end int) bool {
  for i := start; i < end-1; i++ {
    if arr[i] > arr[i+1] {
      return false
    }
  }
  return true
}

func sort(arr []int, start int, end int) []int {
  if start >= end-1 {
    return arr
  }
  mid := (start + end) / 2
  sort(arr, start, mid)
  sort(arr, mid, end)

  saved := make([]int, end-start)
  copy(saved, arr[start:end])

  for !isSorted(arr, start, end) {
    perm := rand.Perm(end - start)
    highPositions := make(map[int]bool)
    for i := 0; i < end-mid; i++ {
      highPositions[perm[i]] = true
    }

    low, high := 0, mid-start
    for offset := 0; offset < end-start; offset++ {
      if highPositions[offset] {
        arr[start+offset] = saved[high]
        high++
      } else {
        arr[start+offset] = saved[low]
        low++
      }
    }
  }

  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 14, 23}
  fmt.Println(sort(array, 0, len(array)))
}
