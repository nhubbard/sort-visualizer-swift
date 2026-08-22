package main

import (
	"fmt"
)

func findMinMax(array []int, a, b int) (int, int) {
	minValue := array[a]
	maxValue := array[a]
	for i := a + 1; i < b; i++ {
		if array[i] < minValue {
			minValue = array[i]
		} else if array[i] > maxValue {
			maxValue = array[i]
		}
	}
	return minValue, maxValue
}

func insertionSortRange(array []int, s, e int) {
	for i := s + 1; i < e; i++ {
		j := i
		for j > s && array[j-1] > array[j] {
			array[j-1], array[j] = array[j], array[j-1]
			j--
		}
	}
}

func siftDown(array []int, s, root, size int) {
	for {
		largest := root
		left := 2*root + 1
		right := 2*root + 2
		if left < size && array[s+largest] < array[s+left] {
			largest = left
		}
		if right < size && array[s+largest] < array[s+right] {
			largest = right
		}
		if largest == root {
			break
		}
		array[s+root], array[s+largest] = array[s+largest], array[s+root]
		root = largest
	}
}

func heapSortRange(array []int, s, e int) {
	size := e - s
	if size <= 1 {
		return
	}
	i := size/2 - 1
	for i >= 0 {
		siftDown(array, s, i, size)
		i--
	}
	end := size - 1
	for end > 0 {
		array[s], array[s+end] = array[s+end], array[s]
		siftDown(array, s, 0, end)
		end--
	}
}

func classify(value, minValue int, c float64) int {
	return int(float64(value-minValue) * c)
}

func staticSort(array []int, a, b int) {
	minValue, maxValue := findMinMax(array, a, b)
	auxLen := b - a
	count := make([]int, auxLen+1)
	offset := make([]int, auxLen+1)
	c := float64(auxLen) / float64(maxValue-minValue+1)

	for i := a; i < b; i++ {
		idx := classify(array[i], minValue, c)
		count[idx]++
	}

	offset[0] = a
	for i := 1; i < auxLen; i++ {
		offset[i] = count[i-1] + offset[i-1]
	}

	for v := 0; v < auxLen; v++ {
		for count[v] > 0 {
			origin := offset[v]
			from := origin
			num := array[from]
			array[from] = -1
			for {
				idx := classify(num, minValue, c)
				to := offset[idx]
				offset[idx]++
				count[idx]--
				temp := array[to]
				array[to] = num
				num = temp
				from = to
				if from == origin {
					break
				}
			}
		}
	}

	for i := 0; i < auxLen; i++ {
		s := a
		if i > 1 {
			s = offset[i-1]
		}
		e := offset[i]
		if e-s <= 1 {
			continue
		}
		if e-s > 16 {
			heapSortRange(array, s, e)
		} else {
			insertionSortRange(array, s, e)
		}
	}
}

func sort(arr []int) []int {
	if len(arr) > 1 {
		staticSort(arr, 0, len(arr))
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
