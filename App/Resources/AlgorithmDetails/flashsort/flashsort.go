package main

import (
	"fmt"
)

func classify(value, minValue int, c float64) int {
	return int(float64(value-minValue)*c) + 1
}

func flashSort(array []int) {
	n := len(array)
	if n == 0 {
		return
	}

	m := int(0.2*float64(n)) + 2

	minValue := array[0]
	maxValue := array[0]
	maxIndex := 0

	i := 1
	for i < n-1 {
		var small, big, bigIndex int
		if array[i] < array[i+1] {
			small, big, bigIndex = array[i], array[i+1], i+1
		} else {
			big, bigIndex, small = array[i], i, array[i+1]
		}
		if big > maxValue {
			maxValue = big
			maxIndex = bigIndex
		}
		if small < minValue {
			minValue = small
		}
		i += 2
	}

	last := array[n-1]
	if last < minValue {
		minValue = last
	} else if last > maxValue {
		maxValue = last
		maxIndex = n - 1
	}

	if maxValue == minValue {
		return
	}

	L := make([]int, m+1)
	c := float64(m-1) / float64(maxValue-minValue)

	for h := 0; h < n; h++ {
		k := classify(array[h], minValue, c)
		L[k] += 1
	}

	for k := 2; k <= m; k++ {
		L[k] += L[k-1]
	}

	array[maxIndex], array[0] = array[0], array[maxIndex]

	j := 0
	k := m
	numMoves := 0
	for numMoves < n {
		for j >= L[k] {
			j++
			k = classify(array[j], minValue, c)
		}

		evicted := array[j]
		for j < L[k] {
			k = classify(evicted, minValue, c)
			location := L[k] - 1
			temp := array[location]
			array[location] = evicted
			evicted = temp
			L[k] -= 1
			numMoves++
		}
	}

	for idx := 1; idx < n; idx++ {
		current := array[idx]
		pos := idx - 1
		for pos >= 0 && array[pos] > current {
			array[pos+1] = array[pos]
			pos--
		}
		array[pos+1] = current
	}
}

func sort(arr []int) []int {
	flashSort(arr)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
