package main

import (
	"fmt"
)

func multiSwap(arr []int, i, j, length int) {
	for k := 0; k < length; k++ {
		arr[i+k], arr[j+k] = arr[j+k], arr[i+k]
	}
}

func rotate(arr []int, mid, leftLen, rightLen int) {
	for leftLen > 0 && rightLen > 0 {
		if leftLen > rightLen {
			multiSwap(arr, mid-rightLen, mid, rightLen)
			mid -= rightLen
			leftLen -= rightLen
		} else {
			multiSwap(arr, mid-leftLen, mid, leftLen)
			mid += leftLen
			rightLen -= leftLen
		}
	}
}

// shuffleBlock perfect-shuffles a chunk of size-1 elements by following the cycles of
// i -> i*2 mod size.
func shuffleBlock(arr []int, start, size int) {
	i := 1
	for i < size {
		val := arr[start+i-1]
		j := (i * 2) % size
		for j != i {
			nextVal := arr[start+j-1]
			arr[start+j-1] = val
			val = nextVal
			j = (j * 2) % size
		}
		arr[start+i-1] = val
		i *= 3
	}
}

// shuffle interleaves two adjacent sorted runs. A single riffle shuffle only closes into clean
// cycles at power-of-three sizes, so it shuffles in power-of-three chunks and rotates the next
// chunk's tail into place before each one.
func shuffle(arr []int, start, end int) {
	for end-start > 1 {
		half := (end - start) / 2
		chunk := 1
		for chunk*3-1 <= 2*half {
			chunk *= 3
		}
		tail := (chunk - 1) / 2
		rotate(arr, start+half, half-tail, tail)
		shuffleBlock(arr, start, chunk)
		start += chunk - 1
	}
}

func rotateShuffledEqual(arr []int, i, j, size int) {
	for k := 0; k < size; k += 2 {
		arr[i+k], arr[j+k] = arr[j+k], arr[i+k]
	}
}

func rotateShuffled(arr []int, mid, leftLen, rightLen int) {
	for leftLen > 0 && rightLen > 0 {
		if leftLen > rightLen {
			rotateShuffledEqual(arr, mid-rightLen, mid, rightLen)
			mid -= rightLen
			leftLen -= rightLen
		} else {
			rotateShuffledEqual(arr, mid-leftLen, mid, leftLen)
			mid += leftLen
			rightLen -= leftLen
		}
	}
}

func rotateShuffledOuter(arr []int, mid, leftLen, rightLen int) {
	if leftLen > rightLen {
		rotateShuffledEqual(arr, mid-rightLen, mid+1, rightLen)
		mid -= rightLen
		leftLen -= rightLen
		rotateShuffled(arr, mid, leftLen, rightLen)
	} else {
		rotateShuffledEqual(arr, mid-leftLen, mid+1, leftLen)
		mid += leftLen + 1
		rightLen -= leftLen
		rotateShuffled(arr, mid, leftLen, rightLen)
	}
}

// unshuffleBlock is the inverse of shuffleBlock: it walks the same cycles, writing each value one
// step backward.
func unshuffleBlock(arr []int, start, size int) {
	i := 1
	for i < size {
		prev := i
		val := arr[start+i-1]
		j := (i * 2) % size
		for j != i {
			arr[start+prev-1] = arr[start+j-1]
			prev = j
			j = (j * 2) % size
		}
		arr[start+prev-1] = val
		i *= 3
	}
}

func unshuffle(arr []int, start, end int) {
	for end-start > 1 {
		half := (end - start) / 2
		chunk := 1
		for chunk*3-1 <= 2*half {
			chunk *= 3
		}
		tail := (chunk - 1) / 2
		rotateShuffledOuter(arr, start+2*tail, 2*tail, 2*half-2*tail)
		unshuffleBlock(arr, start, chunk)
		start += chunk - 1
	}
}

func compare3(arr []int, i, j int) int {
	if arr[i] < arr[j] {
		return -1
	}
	if arr[i] == arr[j] {
		return 0
	}
	return 1
}

// mergeUp scans the shuffled (interleaved) range one adjacent pair at a time. A pair already in
// order just advances the scan; a stretch of same-side elements gets un-shuffled back into two
// short plain runs and rotated into its final position.
func mergeUp(arr []int, start, end int, fromLeft bool) {
	i := start
	j := i + 1
	for j < end {
		cmp := compare3(arr, i, j)
		if cmp == -1 || (!fromLeft && cmp == 0) {
			i++
			if i == j {
				j++
				fromLeft = !fromLeft
			}
		} else if end-j == 1 {
			rotate(arr, j, j-i, 1)
			break
		} else {
			run := 0
			if fromLeft {
				for j+2*run < end && compare3(arr, j+2*run, i) != 1 {
					run++
				}
			} else {
				for j+2*run < end && compare3(arr, j+2*run, i) == -1 {
					run++
				}
			}
			j--
			unshuffle(arr, j, j+2*run)
			rotate(arr, j, j-i, run)
			i += run + 1
			j += 2*run + 1
		}
	}
}

func merge(arr []int, start, mid, end int) {
	if mid-start <= end-mid {
		shuffle(arr, start, end)
		mergeUp(arr, start, end, true)
	} else {
		shuffle(arr, start+1, end)
		mergeUp(arr, start, end, false)
	}
}

func ceilPow2(x int) int {
	x--
	for shift := 16; shift > 0; shift >>= 1 {
		x |= x >> shift
	}
	return x + 1
}

func sort(arr []int) []int {
	n := len(arr)
	if n < 2 {
		return arr
	}

	subarrayCount := ceilPow2(n)
	for subarrayCount > 1 {
		i := 0
		for i < subarrayCount {
			lo := n * i / subarrayCount
			mid := n * (i + 1) / subarrayCount
			hi := n * (i + 2) / subarrayCount
			merge(arr, lo, mid, hi)
			i += 2
		}
		subarrayCount >>= 1
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
