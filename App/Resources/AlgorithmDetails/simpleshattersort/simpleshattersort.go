package main

import (
	"fmt"
)

func insertionSort(arr []int, start int, end int) {
	for i := start + 1; i < end; i++ {
		key := arr[i]
		j := i - 1
		for j >= start && arr[j] > key {
			arr[j+1] = arr[j]
			j--
		}
		arr[j+1] = key
	}
}

func shatterPartition(arr []int, start int, length int, num int) []int {
	minV := arr[start]
	maxV := arr[start]
	for i := 1; i < length; i++ {
		if arr[start+i] < minV {
			minV = arr[start+i]
		}
		if arr[start+i] > maxV {
			maxV = arr[start+i]
		}
	}
	valueRange := maxV - minV + 1
	shatters := (length + num - 1) / num

	buckets := make([][]int, shatters)
	for i := 0; i < length; i++ {
		v := arr[start+i]
		idx := (v - minV) * shatters / valueRange
		if idx > shatters-1 {
			idx = shatters - 1
		}
		buckets[idx] = append(buckets[idx], v)
	}

	offsets := make([]int, shatters+1)
	for i := 0; i < shatters; i++ {
		offsets[i+1] = offsets[i] + len(buckets[i])
	}

	pos := start
	for i := 0; i < shatters; i++ {
		for _, v := range buckets[i] {
			arr[pos] = v
			pos++
		}
	}
	return offsets
}

func floorLog2(n int) int {
	log := 0
	m := n
	for m > 1 {
		m >>= 1
		log++
	}
	return log
}

func simpleShatterSort(arr []int, length int, num int, rate int) {
	i := num
	for i > 1 {
		shatterPartition(arr, 0, length, i)
		i = i / rate
	}
	offsets := shatterPartition(arr, 0, length, 1)
	for k := 0; k < len(offsets)-1; k++ {
		if offsets[k+1]-offsets[k] > 1 {
			insertionSort(arr, offsets[k], offsets[k+1])
		}
	}
}

func sort(arr []int) []int {
	n := len(arr)
	rate := floorLog2(n) / 2
	if rate < 2 {
		rate = 2
	}
	simpleShatterSort(arr, n, 4, rate)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
