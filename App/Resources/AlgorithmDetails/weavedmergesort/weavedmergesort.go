package main

import (
  "fmt"
)

func merge(arr []int, tmp []int, length int, residue int, modulus int) {
  if residue+modulus >= length {
    return
  }
  low := residue
  high := residue + modulus
  dmodulus := modulus << 1

  merge(arr, tmp, length, low, dmodulus)
  merge(arr, tmp, length, high, dmodulus)

  nxt := residue
  for low < length && high < length {
    if arr[low] > arr[high] || (arr[low] == arr[high] && low > high) {
      tmp[nxt] = arr[high]
      high += dmodulus
    } else {
      tmp[nxt] = arr[low]
      low += dmodulus
    }
    nxt += modulus
  }
  if low >= length {
    for high < length {
      tmp[nxt] = arr[high]
      nxt += modulus
      high += dmodulus
    }
  } else {
    for low < length {
      tmp[nxt] = arr[low]
      nxt += modulus
      low += dmodulus
    }
  }
  for i := residue; i < length; i += modulus {
    arr[i] = tmp[i]
  }
}

func sort(arr []int) []int {
  tmp := make([]int, len(arr))
  merge(arr, tmp, len(arr), 0, 1)
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
