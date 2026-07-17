package main

import (
	"fmt"
	"math"
)

func sort(arr []int) []int {
	n := len(arr)
	if n <= 1 {
		return arr
	}
	pow2 := int(math.Log(float64(n-1)) / math.Log(2))
	for k := pow2; k >= 0; k-- {
		pow3 := int((math.Log(float64(n)) - float64(k)*math.Log(2)) / math.Log(3))
		for j := pow3; j >= 0; j-- {
			gap := int(math.Pow(2, float64(k)) * math.Pow(3, float64(j)))
			for i := 0; i+gap < n; i++ {
				if arr[i] > arr[i+gap] {
					arr[i], arr[i+gap] = arr[i+gap], arr[i]
				}
			}
		}
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
