package main

import (
  "fmt"
)

func circleSortRoutine(arr []int, length, end int) int {
  swapCount := 0
  for gap := length / 2; gap > 0; gap /= 2 {
    for start := 0; start+gap < end; start += 2 * gap {
      low := start
      high := start + 2*gap - 1
      for low < high {
        if high < end && arr[low] > arr[high] {
          arr[low], arr[high] = arr[high], arr[low]
          swapCount++
        }
        low++
        high--
      }
    }
  }
  return swapCount
}

func sort(arr []int) []int {
  end := len(arr)
  if end <= 1 {
    return arr
  }
  n := 1
  for n < end {
    n <<= 1
  }

  numberOfSwaps := 1
  for numberOfSwaps != 0 {
    numberOfSwaps = circleSortRoutine(arr, n, end)
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
