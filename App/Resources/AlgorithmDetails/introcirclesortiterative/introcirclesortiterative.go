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

func binaryInsertionSort(arr []int, end int) {
  for i := 1; i < end; i++ {
    value := arr[i]
    lo := 0
    hi := i
    for lo < hi {
      mid := lo + (hi-lo)/2
      if value < arr[mid] {
        hi = mid
      } else {
        lo = mid + 1
      }
    }
    j := i
    for j > lo {
      arr[j] = arr[j-1]
      j--
    }
    arr[lo] = value
  }
}

func sort(arr []int) []int {
  end := len(arr)
  if end <= 1 {
    return arr
  }
  n := 1
  threshold := 0
  for n < end {
    n <<= 1
    threshold++
  }
  threshold /= 2

  iterations := 0
  for {
    iterations++
    if iterations >= threshold {
      binaryInsertionSort(arr, end)
      return arr
    }
    if circleSortRoutine(arr, n, end) == 0 {
      return arr
    }
  }
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
