package main

import (
  "fmt"
)

const threshold = 32

func insertionSort(arr []int, start int, end int) {
  for i := start + 1; i < end; i++ {
    j := i
    for j > start && arr[j] < arr[j-1] {
      arr[j-1], arr[j] = arr[j], arr[j-1]
      j--
    }
  }
}

func merge(arr []int, start int, mid int, end int) {
  low := start
  high := mid
  merged := make([]int, 0, end-start)
  for low < mid && high < end {
    if arr[high] < arr[low] {
      merged = append(merged, arr[high])
      high++
    } else {
      merged = append(merged, arr[low])
      low++
    }
  }
  for low < mid {
    merged = append(merged, arr[low])
    low++
  }
  for high < end {
    merged = append(merged, arr[high])
    high++
  }
  for i, v := range merged {
    arr[start+i] = v
  }
}

func mergeSort(arr []int, start int, end int) {
  if end-start <= threshold {
    insertionSort(arr, start, end)
    return
  }
  mid := start + (end-start)/2
  mergeSort(arr, start, mid)
  mergeSort(arr, mid, end)
  merge(arr, start, mid, end)
}

func sort(arr []int) []int {
  n := len(arr)
  if n < 2 {
    return arr
  }
  mergeSort(arr, 0, n)
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
