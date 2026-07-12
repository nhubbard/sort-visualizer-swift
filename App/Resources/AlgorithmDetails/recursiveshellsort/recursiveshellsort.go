package main

import (
  "fmt"
)

func gappedInsertionSort(arr []int, a, b, gap int) {
  for i := a + gap; i < b; i += gap {
    key := arr[i]
    j := i - gap
    for j >= a && key < arr[j] {
      arr[j+gap] = arr[j]
      j -= gap
    }
    arr[j+gap] = key
  }
}

func recursiveShellSort(arr []int, start, end, g int) {
  if start+g <= end {
    recursiveShellSort(arr, start, end, 3*g)
    recursiveShellSort(arr, start+g, end, 3*g)
    recursiveShellSort(arr, start+(2*g), end, 3*g)
    gappedInsertionSort(arr, start, end, g)
  }
}

func sort(arr []int) []int {
  recursiveShellSort(arr, 0, len(arr), 1)
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
