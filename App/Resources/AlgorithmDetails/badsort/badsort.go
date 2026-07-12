package main

import (
  "fmt"
)

func sort(array []int) []int {
  currentLen := len(array)
  for i := 0; i < currentLen; i++ {
    shortest := i

    j := i
    for j < currentLen {
      isShortest := true
      k := j + 1
      for k < currentLen {
        if array[j] > array[k] {
          isShortest = false
          break
        }
        k++
      }
      if isShortest {
        shortest = j
        break
      }
      j++
    }

    array[i], array[shortest] = array[shortest], array[i]
  }
  return array
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
