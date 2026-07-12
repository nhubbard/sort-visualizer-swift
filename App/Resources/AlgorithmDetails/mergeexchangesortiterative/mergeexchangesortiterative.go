package main

import (
  "fmt"
  "math"
)

func mergeExchangeSort(arr []int) {
  n := len(arr)
  if n <= 1 {
    return
  }
  t := int(math.Log(float64(n-1))/math.Log(2)) + 1
  p0 := 1 << (t - 1)
  for p := p0; p > 0; p >>= 1 {
    q := p0
    r := 0
    d := p
    for {
      for i := 0; i < n-d; i++ {
        if (i&p) == r && arr[i] > arr[i+d] {
          arr[i], arr[i+d] = arr[i+d], arr[i]
        }
      }
      if q == p {
        break
      }
      d = q - p
      q >>= 1
      r = p
    }
  }
}

func sort(arr []int) []int {
  mergeExchangeSort(arr)
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
