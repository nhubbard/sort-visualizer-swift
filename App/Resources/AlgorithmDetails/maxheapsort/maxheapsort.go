package main

import (
  "fmt"
)

func heapify(arr []int, n int, i int) {
  largest := i
  left := 2 * i + 1
  right := 2 * i + 2
  if left < n && arr[left] > arr[largest] {
    largest = left
  }
  if right < n && arr[right] > arr[largest] {
    largest = right
  }
  if largest != i {
    arr[i], arr[largest] = arr[largest], arr[i]
    heapify(arr, n, largest)
  }
}

func sort(arr []int) []int {
  n := len(arr)
  for i := n / 2 - 1; i >= 0; i-- {
    heapify(arr, n, i)
  }
  for i := n - 1; i >= 0; i-- {
    arr[0], arr[i] = arr[i], arr[0]
    heapify(arr, i, 0)
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}