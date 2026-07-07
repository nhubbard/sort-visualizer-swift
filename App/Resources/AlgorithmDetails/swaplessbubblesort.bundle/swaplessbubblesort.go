package main

import (
  "fmt"
)

func swaplessBubbleSort(arr []int) []int {
  n := len(arr)
  i := n
  for i > 0 {
    last := 0
    pos := 0
    comp := arr[0]
    for j := 1; j < i; j++ {
      if comp > arr[j] {
        arr[j-1] = arr[j]
        last = j
      } else {
        if pos+1 < j {
          arr[j-1] = comp
        }
        pos = j
        comp = arr[j]
      }
    }
    arr[i-1] = comp
    i = last
  }
  return arr
}

func sort(arr []int) []int {
  return swaplessBubbleSort(arr)
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
