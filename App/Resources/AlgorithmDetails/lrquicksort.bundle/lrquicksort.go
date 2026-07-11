package main

import (
  "fmt"
)

func quickSort(arr []int, p, r int) []int {
  if p >= r {
    return arr
  }

  pivot := arr[p+(r-p+1)/2]
  i := p
  j := r

  for i <= j {
    for arr[i] < pivot {
      i++
    }
    for arr[j] > pivot {
      j--
    }
    if i <= j {
      arr[i], arr[j] = arr[j], arr[i]
      i++
      j--
    }
  }

  if p < j {
    arr = quickSort(arr, p, j)
  }
  if i < r {
    arr = quickSort(arr, i, r)
  }
  return arr
}

func sort(arr []int) []int {
  return quickSort(arr, 0, len(arr)-1)
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
