package main

import (
	"fmt"
)

func hyperfloor(n int) int {
	power := 1
	for power*2 <= n {
		power *= 2
	}
	return power
}

func uncheckedInsertionSort(array []int, first int, last int) {
	cur := first + 1
	for cur != last {
		if array[cur] < array[cur-1] {
			tmp := array[cur]
			sift := cur
			sift1 := cur - 1
			for {
				array[sift] = array[sift1]
				sift--
				if sift == first {
					break
				}
				sift1--
				if tmp >= array[sift1] {
					break
				}
			}
			array[sift] = tmp
		}
		cur++
	}
}

func insertionSort(array []int, first int, last int) {
	if first == last {
		return
	}
	uncheckedInsertionSort(array, first, last)
}

func poplarSift(array []int, firstIn int, sizeIn int) {
	size := sizeIn
	if size < 2 {
		return
	}
	root := firstIn + (size - 1)
	childRoot1 := root - 1
	childRoot2 := firstIn + (size/2 - 1)
	for {
		maxRoot := root
		if array[maxRoot] < array[childRoot1] {
			maxRoot = childRoot1
		}
		if array[maxRoot] < array[childRoot2] {
			maxRoot = childRoot2
		}
		if maxRoot == root {
			return
		}
		array[root], array[maxRoot] = array[maxRoot], array[root]
		size /= 2
		if size < 2 {
			return
		}
		root = maxRoot
		childRoot1 = root - 1
		childRoot2 = maxRoot - (size - size/2)
	}
}

func popHeapWithSize(array []int, first int, last int, sizeIn int) {
	size := sizeIn
	poplarSize := hyperfloor(size+1) - 1
	lastRoot := last - 1
	bigger := lastRoot
	biggerSize := poplarSize

	it := first
	for {
		root := it + poplarSize - 1
		if root == lastRoot {
			break
		}
		if array[bigger] < array[root] {
			bigger = root
			biggerSize = poplarSize
		}
		it = root + 1
		size -= poplarSize
		poplarSize = hyperfloor(size+1) - 1
	}

	if bigger != lastRoot {
		array[bigger], array[lastRoot] = array[lastRoot], array[bigger]
		poplarSift(array, bigger-(biggerSize-1), biggerSize)
	}
}

func makeHeap(array []int, first int, last int) {
	size := last - first
	if size < 2 {
		return
	}
	smallPoplarSize := 15
	if size <= smallPoplarSize {
		uncheckedInsertionSort(array, first, last)
		return
	}

	poplarLevel := 1
	it := first
	next := it + smallPoplarSize
	for {
		uncheckedInsertionSort(array, it, next)
		poplarSize := smallPoplarSize
		i := (poplarLevel & -poplarLevel) >> 1
		for i != 0 {
			it -= poplarSize
			poplarSize = 2*poplarSize + 1
			if it+poplarSize > last {
				break
			}
			poplarSift(array, it, poplarSize)
			next++
			i >>= 1
		}
		if (last - next) <= smallPoplarSize {
			insertionSort(array, next, last)
			return
		}
		it = next
		next += smallPoplarSize
		poplarLevel++
	}
}

func sortHeap(array []int, first int, lastIn int) {
	last := lastIn
	size := last - first
	if size < 2 {
		return
	}
	for {
		popHeapWithSize(array, first, last, size)
		last--
		size--
		if size <= 1 {
			break
		}
	}
}

func sort(array []int) {
	n := len(array)
	if n <= 1 {
		return
	}
	makeHeap(array, 0, n)
	sortHeap(array, 0, n)
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	sort(array)
	fmt.Println(array)
}
