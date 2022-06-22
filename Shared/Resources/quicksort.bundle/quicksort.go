package main

import (
  "fmt"
)

func partition(arr []int, low, high int) ([]int, int) {
  pivot := arr[high]
  i := low
  for j := low; j < high; j++ {
    if arr[j] < pivot {
      arr[i], arr[j] = arr[j], arr[i]
      i++
    }
  }
  arr[i], arr[high] = arr[high], arr[i]
  return arr, i
}

func quickSort(arr []int, low, high int) []int {
  if low < high {
    var p int
    arr, p = partition(arr, low, high)
    arr = quickSort(arr, low, p-1)
    arr = quickSort(arr, p+1, high)
  }
  return arr
}

func sort(arr []int) []int {
  return quickSort(arr, 0, len(arr) - 1)
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}