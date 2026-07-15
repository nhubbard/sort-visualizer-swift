package main

import (
  "fmt"
)

func maxHeapify(arr []int, i int, heapSize int) {
  left := 3*i + 1
  mid := 3*i + 2
  right := 3*i + 3
  largest := i
  if left <= heapSize && arr[left] > arr[largest] {
    largest = left
  }
  if right <= heapSize && arr[right] > arr[largest] {
    largest = right
  }
  if mid <= heapSize && arr[mid] > arr[largest] {
    largest = mid
  }
  if largest != i {
    arr[i], arr[largest] = arr[largest], arr[i]
    maxHeapify(arr, largest, heapSize)
  }
}

func sort(arr []int) []int {
  n := len(arr)
  heapSize := n - 1
  for i := n - 1; i >= 0; i-- {
    maxHeapify(arr, i, heapSize)
  }
  for i := n - 1; i >= 0; i-- {
    arr[0], arr[i] = arr[i], arr[0]
    heapSize -= 1
    maxHeapify(arr, 0, heapSize)
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
