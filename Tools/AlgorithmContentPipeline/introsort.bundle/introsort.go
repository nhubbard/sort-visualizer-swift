package main

import (
  "fmt"
  "math"
)

const sizeThreshold = 16

func swap(arr []int, a int, b int) {
  arr[a], arr[b] = arr[b], arr[a]
}

func medianOf3(arr []int, left int, mid int, right int) int {
  if !(arr[left] >= arr[right]) {
    swap(arr, left, right)
  }
  if !(arr[left] >= arr[mid]) {
    swap(arr, left, mid)
  }
  if !(arr[mid] >= arr[right]) {
    swap(arr, mid, right)
  }
  return mid
}

func partition(arr []int, lo int, hi int, pivotValue int) int {
  i, j := lo, hi
  for {
    for arr[i] < pivotValue {
      i++
    }
    j--
    for pivotValue < arr[j] {
      j--
    }
    if !(i < j) {
      return i
    }
    swap(arr, i, j)
    i++
  }
}

func siftDown(arr []int, lo int, root int, rangeSize int) {
  for {
    largest := root
    left := 2*root + 1
    right := 2*root + 2
    if left < rangeSize && arr[lo+largest] < arr[lo+left] {
      largest = left
    }
    if right < rangeSize && arr[lo+largest] < arr[lo+right] {
      largest = right
    }
    if largest == root {
      break
    }
    swap(arr, lo+root, lo+largest)
    root = largest
  }
}

func heapSortRange(arr []int, lo int, hi int) {
  size := hi - lo
  for i := size/2 - 1; i >= 0; i-- {
    siftDown(arr, lo, i, size)
  }
  for end := size - 1; end > 0; end-- {
    swap(arr, lo, lo+end)
    siftDown(arr, lo, 0, end)
  }
}

func insertionSort(arr []int, start int, end int) {
  for i := start + 1; i < end; i++ {
    j := i
    for j > start && arr[j] < arr[j-1] {
      swap(arr, j-1, j)
      j--
    }
  }
}

func floorLog2(a int) int {
  return int(math.Floor(math.Log(float64(a)) / math.Log(2)))
}

func introsortLoop(arr []int, lo int, hi int, depthLimit int) {
  for hi-lo > sizeThreshold {
    if depthLimit == 0 {
      heapSortRange(arr, lo, hi)
      return
    }
    depthLimit--
    mid := lo + (hi-lo)/2
    pivotIndex := medianOf3(arr, lo, mid, hi-1)
    pivotValue := arr[pivotIndex]
    p := partition(arr, lo, hi, pivotValue)
    introsortLoop(arr, p, hi, depthLimit)
    hi = p
  }
}

func sort(arr []int) []int {
  n := len(arr)
  introsortLoop(arr, 0, n, 2*floorLog2(n))
  insertionSort(arr, 0, n)
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
