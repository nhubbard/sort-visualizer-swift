package main

import (
  "fmt"
  "math/rand"
  "sort"
)

func _sort(arr []int) []int {
  for {
    if sort.IntsAreSorted(arr) {
      return arr
    }
    rand.Shuffle(len(arr), func(i, j int) {
      arr[i], arr[j] = arr[j], arr[i]
    })
  }
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23}
  fmt.Println(_sort(array))
}
