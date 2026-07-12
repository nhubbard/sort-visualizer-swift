package main

import (
  "fmt"
  "math"
)

func triangularRoot(val int) int {
  return (int(math.Sqrt(float64(8*val+1))) - 1) / 2
}

func siftDown(array []int, root int, size int) {
  for {
    row := triangularRoot(root)
    left := root + row + 1
    if left >= size {
      break
    }
    right := left + 1
    largest := root
    if array[largest] < array[left] {
      largest = left
    }
    if right < size && array[largest] < array[right] {
      largest = right
    }
    if largest == root {
      break
    }
    array[root], array[largest] = array[largest], array[root]
    root = largest
  }
}

func heapify(array []int, length int) {
  for i := length - 1; i >= 0; i-- {
    siftDown(array, i, length)
  }
}

func sort(array []int) {
  n := len(array)
  if n <= 1 {
    return
  }
  heapify(array, n)
  for i := 1; i < n-1; i++ {
    array[0], array[n-i] = array[n-i], array[0]
    siftDown(array, 0, n-i)
  }
  if array[0] > array[1] {
    array[0], array[1] = array[1], array[0]
  }
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  sort(array)
  fmt.Println(array)
}
