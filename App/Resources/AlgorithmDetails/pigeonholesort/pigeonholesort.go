package main

import (
  "fmt"
)

func sort(arr []int) []int {
  n := len(arr)
  min := arr[0]
  max := arr[0]
  for _, v := range arr {
    if v < min {
      min = v
    }
    if v > max {
      max = v
    }
  }

  size := max - min + 1
  holes := make([]int, size)
  for _, v := range arr {
    holes[v-min]++
  }

  output := make([]int, n)
  j := 0
  for count := 0; count < size; count++ {
    for holes[count] > 0 {
      holes[count]--
      output[j] = count + min
      j++
    }
  }

  return output
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
