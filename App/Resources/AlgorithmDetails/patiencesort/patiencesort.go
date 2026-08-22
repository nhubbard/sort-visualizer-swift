package main

import (
	"container/heap"
	"fmt"
)

type heapEntry struct {
	top       int
	pileIndex int
}

type pileHeap []heapEntry

func (h pileHeap) Len() int           { return len(h) }
func (h pileHeap) Less(i, j int) bool { return h[i].top < h[j].top }
func (h pileHeap) Swap(i, j int)      { h[i], h[j] = h[j], h[i] }
func (h *pileHeap) Push(x any)        { *h = append(*h, x.(heapEntry)) }
func (h *pileHeap) Pop() any {
	old := *h
	n := len(old)
	item := old[n-1]
	*h = old[:n-1]
	return item
}

func sort(arr []int) []int {
	n := len(arr)
	var piles [][]int
	var tops []int

	for _, x := range arr {
		// binary search: leftmost pile whose top is >= x
		lo, hi := 0, len(piles)
		for lo < hi {
			mid := (lo + hi) / 2
			if tops[mid] >= x {
				hi = mid
			} else {
				lo = mid + 1
			}
		}
		if lo == len(piles) {
			piles = append(piles, []int{x})
			tops = append(tops, x)
		} else {
			piles[lo] = append(piles[lo], x)
			tops[lo] = x
		}
	}

	h := &pileHeap{}
	heap.Init(h)
	for i := range piles {
		heap.Push(h, heapEntry{top: tops[i], pileIndex: i})
	}

	result := make([]int, 0, n)
	for h.Len() > 0 {
		entry := heap.Pop(h).(heapEntry)
		pile := piles[entry.pileIndex]
		value := pile[len(pile)-1]
		piles[entry.pileIndex] = pile[:len(pile)-1]
		result = append(result, value)
		if len(piles[entry.pileIndex]) > 0 {
			newTop := piles[entry.pileIndex][len(piles[entry.pileIndex])-1]
			heap.Push(h, heapEntry{top: newTop, pileIndex: entry.pileIndex})
		}
	}

	copy(arr, result)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
