package main

import (
  "fmt"
)

func intPow(base, exponent int) int {
  result := 1
  for i := 0; i < exponent; i++ {
    result *= base
  }
  return result
}

func getDigit(value, power, radix int) int {
  return (value / intPow(radix, power)) % radix
}

func radixMSD(arr []int, low, high, radix, power int) {
  if low >= high || power < 0 {
    return
  }

  buckets := make([][]int, radix)
  for i := low; i < high; i++ {
    digit := getDigit(arr[i], power, radix)
    buckets[digit] = append(buckets[digit], arr[i])
  }

  index := low
  for _, bucket := range buckets {
    for _, value := range bucket {
      arr[index] = value
      index++
    }
  }

  start := low
  for _, bucket := range buckets {
    radixMSD(arr, start, start+len(bucket), radix, power-1)
    start += len(bucket)
  }
}

func sort(arr []int) []int {
  if len(arr) <= 1 {
    return arr
  }
  radix := 4
  maxValue := arr[0]
  for _, v := range arr {
    if v > maxValue {
      maxValue = v
    }
  }
  highestPower := 0
  probe := radix
  for probe <= maxValue {
    highestPower++
    probe *= radix
  }
  radixMSD(arr, 0, len(arr), radix, highestPower)
  return arr
}

func main() {
  array := []int{0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56}
  fmt.Println(sort(array))
}
