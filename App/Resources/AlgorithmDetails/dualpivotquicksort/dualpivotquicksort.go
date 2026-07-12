package main

import (
  "fmt"
)

func partition(arr []int, low, high int) ([]int, int, int) {
  if arr[low] > arr[high] {
    arr[low], arr[high] = arr[high], arr[low]
  }
  j := low + 1
  g := high - 1
  k := low + 1
  p := arr[low]
  q := arr[high]
  for k <= g {
    if arr[k] < p {
      arr[k], arr[j] = arr[j], arr[k]
      j++
    } else if arr[k] >= q {
      for arr[g] > q && k < g {
        g--
      }
      arr[k], arr[g] = arr[g], arr[k]
      g--
      if arr[k] < p {
        arr[k], arr[j] = arr[j], arr[k]
        j++
      }
    }
    k++
  }
  j--
  g++
  arr[low], arr[j] = arr[j], arr[low]
  arr[high], arr[g] = arr[g], arr[high]
  return arr, j, g
}

func dualPivotQuickSort(arr []int, low, high int) []int {
  if low < high {
    var j, g int
    arr, j, g = partition(arr, low, high)
    arr = dualPivotQuickSort(arr, low, j-1)
    arr = dualPivotQuickSort(arr, j+1, g-1)
    arr = dualPivotQuickSort(arr, g+1, high)
  }
  return arr
}

func sort(arr []int) []int {
  return dualPivotQuickSort(arr, 0, len(arr) - 1)
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
