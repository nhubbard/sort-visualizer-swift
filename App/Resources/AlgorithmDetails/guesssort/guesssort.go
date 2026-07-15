package main

import (
  "fmt"
)

func isValid(arr []int, loops []int, n int) bool {
  total := 0
  for i := 0; i < n; i++ {
    for j := 0; j < n; j++ {
      if loops[i] == loops[j] {
        total += 1
      }
    }
  }
  for i := 0; i < n; i++ {
    for j := 0; j < n; j++ {
      if i < j && arr[loops[i]] > arr[loops[j]] {
        total += 1
      } else if i > j && arr[loops[i]] < arr[loops[j]] {
        total += 1
      }
    }
  }
  return total == n
}

func sort(arr []int) []int {
  n := len(arr)
  loops := make([]int, n)
  indexes := make([]int, n)

  for {
    if isValid(arr, loops, n) {
      copy(indexes, loops)
    }
    pos := 0
    for pos < n {
      if loops[pos] < n-1 {
        loops[pos] += 1
        break
      } else {
        loops[pos] = 0
        pos += 1
      }
    }
    if pos == n {
      break
    }
  }

  original := append([]int{}, arr...)
  for i := 0; i < n; i++ {
    arr[i] = original[indexes[i]]
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 14}
  fmt.Println(sort(array))
}
