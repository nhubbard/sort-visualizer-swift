package main

import (
  "fmt"
)

// [start, stop) is the half-open range being sorted. merge selects whether
// the two halves are recursively pre-sorted before the fixed diamond
// comparison pattern below merges them together.
func sort(arr []int, start, stop int, merge bool) {
  if stop-start == 2 {
    if arr[start] > arr[stop-1] {
      arr[start], arr[stop-1] = arr[stop-1], arr[start]
    }
  } else if stop-start >= 3 {
    div := float64(stop-start) / 4.0
    mid := (stop-start)/2 + start
    quarter := int(div) + start
    threeQuarters := int(div*3) + start

    if merge {
      sort(arr, start, mid, true)
      sort(arr, mid, stop, true)
    }
    sort(arr, quarter, threeQuarters, false)
    sort(arr, start, mid, false)
    sort(arr, mid, stop, false)
    sort(arr, quarter, threeQuarters, false)
  }
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  sort(array, 0, len(array), true)
  fmt.Println(array)
}
