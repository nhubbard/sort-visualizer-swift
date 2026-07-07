package main

import (
  "fmt"
)

func doubleSelectionSort(arr []int) {
  n := len(arr)
  if n <= 1 {
    return
  }

  left := 0
  right := n - 1
  smallest := 0
  biggest := 0

  for left <= right {
    for i := left; i <= right; i++ {
      if arr[i] > arr[biggest] {
        biggest = i
      }
      if arr[i] < arr[smallest] {
        smallest = i
      }
    }

    if biggest == left {
      biggest = smallest
    }

    arr[left], arr[smallest] = arr[smallest], arr[left]
    arr[right], arr[biggest] = arr[biggest], arr[right]

    left++
    right--
    smallest = left
    biggest = right
  }
}

func sort(arr []int) []int {
  doubleSelectionSort(arr)
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
