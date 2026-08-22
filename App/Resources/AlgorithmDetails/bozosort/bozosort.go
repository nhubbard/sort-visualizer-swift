package main

import (
	"fmt"
	"math/rand"
	"sort"
)

func _sort(arr []int) []int {
	n := len(arr)
	for !sort.IntsAreSorted(arr) {
		i := rand.Intn(n)
		j := rand.Intn(n)
		arr[i], arr[j] = arr[j], arr[i]
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77}
	fmt.Println(_sort(array))
}
