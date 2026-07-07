package main

import (
  "fmt"
)

func push(arr []int, low, high int) {
  for i := low; i < high; i++ {
    if arr[i] > arr[i+1] {
      arr[i], arr[i+1] = arr[i+1], arr[i]
    }
  }
}

func merge(arr []int, low, high, mid int) {
  i := low
  for i <= mid {
    if arr[i] > arr[mid+1] {
      arr[i], arr[mid+1] = arr[mid+1], arr[i]
      push(arr, mid+1, high)
    }
    i++
  }
}

func mergeSort(arr []int, low, high int) {
  if high-low == 0 {
    return
  } else if high-low == 1 {
    if arr[low] > arr[high] {
      arr[low], arr[high] = arr[high], arr[low]
    }
  } else {
    mid := (low + high) / 2
    mergeSort(arr, low, mid)
    mergeSort(arr, mid+1, high)
    merge(arr, low, high, mid)
  }
}

func sort(arr []int) []int {
  if len(arr) >= 2 {
    mergeSort(arr, 0, len(arr)-1)
  }
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
