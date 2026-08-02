package main

import (
	"fmt"
)

func reverseRange(arr []int, lo int, hi int) {
	for lo < hi {
		arr[lo], arr[hi] = arr[hi], arr[lo]
		lo++
		hi--
	}
}

func twinSwap(arr []int, nmemb int) int {
	index := 0
	end := nmemb - 2
	for index <= end {
		if arr[index] <= arr[index+1] {
			index += 2
			continue
		}
		start := index
		index += 2
		for {
			if index > end {
				if start == 0 && (nmemb%2 == 0 || arr[index-1] > arr[index]) {
					end = nmemb - 1
					reverseRange(arr, start, end)
					return 1
				}
				break
			}
			if arr[index] > arr[index+1] {
				if arr[index-1] > arr[index] {
					index += 2
					continue
				}
				arr[index], arr[index+1] = arr[index+1], arr[index]
			}
			break
		}
		end = index - 1
		reverseRange(arr, start, end)
		end = nmemb - 2
		index += 2
	}
	return 0
}

func tailMerge(arr []int, buf []int, nmemb int, block int) {
	s := 0
	for block < nmemb {
		offset := 0
		for offset+block < nmemb {
			a := offset
			e := a + block - 1
			if arr[e] <= arr[e+1] {
				offset += block * 2
				continue
			}
			var cMax, dMax int
			if offset+block*2 <= nmemb {
				cMax = s + block
				dMax = a + block*2
			} else {
				cMax = s + nmemb - (offset + block)
				dMax = nmemb
			}
			d := dMax - 1
			for arr[e] <= arr[d] {
				dMax--
				d--
				cMax--
			}
			c := s
			d = a + block
			for c < cMax {
				buf[c] = arr[d]
				c++
				d++
			}
			c--
			d = a + block - 1
			e = dMax - 1
			if arr[a] <= arr[a+block] {
				arr[e] = arr[d]
				e--
				d--
				for c >= s {
					for arr[d] > buf[c] {
						arr[e] = arr[d]
						e--
						d--
					}
					arr[e] = buf[c]
					e--
					c--
				}
			} else {
				arr[e] = arr[d]
				e--
				d--
				for d >= a {
					for arr[d] <= buf[c] {
						arr[e] = buf[c]
						e--
						c--
					}
					arr[e] = arr[d]
					e--
					d--
				}
				for c >= s {
					arr[e] = buf[c]
					e--
					c--
				}
			}
			offset += block * 2
		}
		block *= 2
	}
}

func twinsort(arr []int, nmemb int) {
	if twinSwap(arr, nmemb) == 0 {
		buf := make([]int, nmemb/2)
		tailMerge(arr, buf, nmemb, 2)
	}
}

func sort(arr []int) []int {
	n := len(arr)
	twinsort(arr, n)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
