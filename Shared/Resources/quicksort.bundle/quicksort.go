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

func main() {
  items := []int{35, 95, 74, 71, 72, 30, 96, 53, 9, 0}
  fmt.Println(quickSort(items, 0, len(items) - 1))
}
