package main

import (
	"fmt"
)

func sort(arr []int) []int {
	n := len(arr)

	for p := 1; p < n; p += p {
		for k := p; k > 0; k /= 2 {
			for j := k % p; j+k < n; j += k + k {
				for i := 0; i < k; i++ {
					if (i+j)/(p+p) == (i+j+k)/(p+p) {
						if i+j+k < n {
							if arr[i+j] > arr[i+j+k] {
								arr[i+j], arr[i+j+k] = arr[i+j+k], arr[i+j]
							}
						}
					}
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
